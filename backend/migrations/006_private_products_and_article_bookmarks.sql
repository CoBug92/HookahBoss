ALTER TABLE private_tobacco_products
  ADD COLUMN flavor_profiles text[] NOT NULL DEFAULT '{}',
  ADD CONSTRAINT private_product_profiles_valid CHECK (flavor_profiles <@ ARRAY['berry','fruit','citrus','dessert','beverage','herbal','spicy']::text[]);

CREATE TABLE article_bookmarks (
  user_id uuid NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  article_id uuid NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY(user_id,article_id)
);
