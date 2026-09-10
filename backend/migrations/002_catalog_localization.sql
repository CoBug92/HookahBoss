ALTER TABLE tobacco_products
  ADD COLUMN name_ru text,
  ADD COLUMN name_en text,
  ADD COLUMN description_ru text,
  ADD COLUMN description_en text,
  ADD COLUMN translation_origin text CHECK (translation_origin IN ('official', 'normalized_translation')),
  ADD COLUMN source_confidence text CHECK (source_confidence IN ('high', 'medium', 'low'));

ALTER TABLE tobacco_products ADD CONSTRAINT tobacco_product_localization_nonblank CHECK (
  (name_ru IS NULL OR btrim(name_ru) <> '') AND
  (name_en IS NULL OR btrim(name_en) <> '') AND
  (description_ru IS NULL OR btrim(description_ru) <> '') AND
  (description_en IS NULL OR btrim(description_en) <> '')
);
