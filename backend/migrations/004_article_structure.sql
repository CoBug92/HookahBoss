CREATE TYPE article_category AS ENUM ('fundamentals','preparation','bowls_heat','care','safety');
ALTER TABLE articles ADD COLUMN category article_category, ADD COLUMN summary_ru text, ADD COLUMN summary_en text,
  ADD COLUMN body_ru_structured jsonb, ADD COLUMN body_en_structured jsonb, ADD COLUMN reading_minutes smallint CHECK (reading_minutes BETWEEN 1 AND 60);
CREATE TABLE article_sources(article_id uuid NOT NULL REFERENCES articles(id) ON DELETE CASCADE,source_id uuid NOT NULL REFERENCES content_sources(id) ON DELETE RESTRICT,PRIMARY KEY(article_id,source_id));
CREATE TABLE article_related(article_id uuid NOT NULL REFERENCES articles(id) ON DELETE CASCADE,related_article_id uuid NOT NULL REFERENCES articles(id) ON DELETE CASCADE,position smallint NOT NULL CHECK(position>0),PRIMARY KEY(article_id,related_article_id),UNIQUE(article_id,position),CHECK(article_id<>related_article_id));
