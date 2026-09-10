ALTER TABLE official_mixes
  ADD COLUMN summary_ru text,
  ADD COLUMN summary_en text,
  ADD COLUMN translation_origin text CHECK (translation_origin IN ('official', 'normalized_translation')),
  ADD COLUMN source_confidence text CHECK (source_confidence IN ('high', 'medium', 'low'));

ALTER TABLE official_mixes ADD CONSTRAINT official_mix_metadata_nonblank CHECK (
  (summary_ru IS NULL OR btrim(summary_ru) <> '') AND
  (summary_en IS NULL OR btrim(summary_en) <> '')
);

ALTER TABLE content_sources
  ADD COLUMN source_type text CHECK (source_type IN ('official_catalog', 'editorial_recipe', 'user_recipe', 'industry_catalog')),
  ADD COLUMN author text;
