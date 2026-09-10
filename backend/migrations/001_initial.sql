CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE content_status AS ENUM ('draft', 'published', 'archived');
CREATE TYPE strength_level AS ENUM ('light', 'medium', 'strong');
CREATE TYPE intensity_level AS ENUM ('subtle', 'pronounced');
CREATE TYPE inventory_level AS ENUM ('plenty', 'low', 'empty');

CREATE TABLE IF NOT EXISTS schema_migrations (
  version text PRIMARY KEY,
  applied_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE content_sources (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  url text NOT NULL UNIQUE,
  title text,
  publisher text,
  checked_at date NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE app_users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  apple_subject text NOT NULL UNIQUE,
  email text,
  display_name text,
  locale text NOT NULL DEFAULT 'ru' CHECK (locale IN ('ru', 'en')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE brands (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug text NOT NULL UNIQUE,
  name text NOT NULL,
  status content_status NOT NULL DEFAULT 'draft',
  source_id uuid REFERENCES content_sources(id),
  verified_at date,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK ((status = 'draft') OR (source_id IS NOT NULL AND verified_at IS NOT NULL))
);

CREATE TABLE tobacco_lines (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  brand_id uuid NOT NULL REFERENCES brands(id) ON DELETE CASCADE,
  slug text NOT NULL,
  name text NOT NULL,
  strength strength_level NOT NULL,
  status content_status NOT NULL DEFAULT 'draft',
  source_id uuid REFERENCES content_sources(id),
  verified_at date,
  UNIQUE (brand_id, slug),
  CHECK ((status = 'draft') OR (source_id IS NOT NULL AND verified_at IS NOT NULL))
);

CREATE TABLE flavor_tags (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug text NOT NULL UNIQUE,
  name_ru text NOT NULL,
  name_en text NOT NULL,
  profile text NOT NULL CHECK (profile IN ('berry','fruit','citrus','dessert','beverage','herbal','spicy'))
);

CREATE TABLE tobacco_products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  line_id uuid NOT NULL REFERENCES tobacco_lines(id) ON DELETE CASCADE,
  slug text NOT NULL,
  name text NOT NULL,
  sweetness intensity_level NOT NULL,
  acidity intensity_level NOT NULL,
  freshness intensity_level NOT NULL,
  status content_status NOT NULL DEFAULT 'draft',
  source_id uuid REFERENCES content_sources(id),
  verified_at date,
  UNIQUE (line_id, slug),
  CHECK ((status = 'draft') OR (source_id IS NOT NULL AND verified_at IS NOT NULL))
);

CREATE TABLE tobacco_product_tags (
  product_id uuid NOT NULL REFERENCES tobacco_products(id) ON DELETE CASCADE,
  tag_id uuid NOT NULL REFERENCES flavor_tags(id) ON DELETE RESTRICT,
  weight smallint NOT NULL DEFAULT 1 CHECK (weight BETWEEN 1 AND 5),
  PRIMARY KEY (product_id, tag_id)
);

CREATE TABLE official_mixes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug text NOT NULL UNIQUE,
  title_ru text NOT NULL,
  title_en text NOT NULL,
  status content_status NOT NULL DEFAULT 'draft',
  source_id uuid REFERENCES content_sources(id),
  verified_at date,
  published_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK ((status = 'draft') OR (source_id IS NOT NULL AND verified_at IS NOT NULL))
);

CREATE TABLE official_mix_components (
  mix_id uuid NOT NULL REFERENCES official_mixes(id) ON DELETE CASCADE,
  product_id uuid NOT NULL REFERENCES tobacco_products(id) ON DELETE RESTRICT,
  percentage smallint NOT NULL CHECK (percentage BETWEEN 1 AND 100),
  position smallint NOT NULL CHECK (position > 0),
  PRIMARY KEY (mix_id, product_id),
  UNIQUE (mix_id, position)
);

CREATE FUNCTION validate_official_mix_percentages() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE target_mix uuid;
DECLARE total integer;
BEGIN
  target_mix := COALESCE(NEW.mix_id, OLD.mix_id);
  IF NOT EXISTS (SELECT 1 FROM official_mixes WHERE id = target_mix) THEN RETURN NULL; END IF;
  SELECT COALESCE(sum(percentage), 0) INTO total FROM official_mix_components WHERE mix_id = target_mix;
  IF total <> 100 THEN RAISE EXCEPTION 'official mix percentages must total 100 (got %)', total; END IF;
  RETURN NULL;
END $$;

CREATE CONSTRAINT TRIGGER official_mix_percentage_total
AFTER INSERT OR UPDATE OR DELETE ON official_mix_components
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION validate_official_mix_percentages();

CREATE TABLE mix_ratings (
  user_id uuid NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  mix_id uuid NOT NULL REFERENCES official_mixes(id) ON DELETE CASCADE,
  score smallint NOT NULL CHECK (score BETWEEN 1 AND 5),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, mix_id)
);

CREATE TABLE mix_favorites (
  user_id uuid NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  mix_id uuid NOT NULL REFERENCES official_mixes(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, mix_id)
);

CREATE TABLE private_tobacco_products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  brand_name text NOT NULL,
  line_name text,
  flavor_name text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, brand_name, line_name, flavor_name)
);

CREATE TABLE inventory_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  product_id uuid REFERENCES tobacco_products(id) ON DELETE CASCADE,
  private_product_id uuid REFERENCES private_tobacco_products(id) ON DELETE CASCADE,
  level inventory_level NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK ((product_id IS NOT NULL)::int + (private_product_id IS NOT NULL)::int = 1)
);
CREATE UNIQUE INDEX inventory_official_unique ON inventory_items(user_id, product_id) WHERE product_id IS NOT NULL;
CREATE UNIQUE INDEX inventory_private_unique ON inventory_items(user_id, private_product_id) WHERE private_product_id IS NOT NULL;

CREATE TABLE personal_mixes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  title text,
  score smallint CHECK (score BETWEEN 1 AND 5),
  comment text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE personal_mix_components (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  mix_id uuid NOT NULL REFERENCES personal_mixes(id) ON DELETE CASCADE,
  product_id uuid REFERENCES tobacco_products(id) ON DELETE RESTRICT,
  private_product_id uuid REFERENCES private_tobacco_products(id) ON DELETE RESTRICT,
  freeform_name text,
  percentage smallint CHECK (percentage BETWEEN 1 AND 100),
  position smallint NOT NULL CHECK (position > 0),
  UNIQUE (mix_id, position),
  CHECK ((product_id IS NOT NULL)::int + (private_product_id IS NOT NULL)::int + (freeform_name IS NOT NULL)::int = 1)
);

CREATE TABLE articles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug text NOT NULL UNIQUE,
  title_ru text NOT NULL,
  title_en text NOT NULL,
  body_ru text NOT NULL,
  body_en text NOT NULL,
  status content_status NOT NULL DEFAULT 'draft',
  source_id uuid REFERENCES content_sources(id),
  verified_at date,
  published_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK ((status = 'draft') OR (source_id IS NOT NULL AND verified_at IS NOT NULL))
);

CREATE TABLE substitution_deny_rules (
  source_product_id uuid NOT NULL REFERENCES tobacco_products(id) ON DELETE CASCADE,
  substitute_product_id uuid NOT NULL REFERENCES tobacco_products(id) ON DELETE CASCADE,
  reason text,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (source_product_id, substitute_product_id),
  CHECK (source_product_id <> substitute_product_id)
);

CREATE INDEX products_line_idx ON tobacco_products(line_id);
CREATE INDEX product_tags_tag_idx ON tobacco_product_tags(tag_id);
CREATE INDEX official_mixes_status_idx ON official_mixes(status, published_at DESC);
CREATE INDEX ratings_mix_idx ON mix_ratings(mix_id);
CREATE INDEX articles_status_idx ON articles(status, published_at DESC);
