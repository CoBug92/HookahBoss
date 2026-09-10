import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

const migrationUrl = new URL("../migrations/001_initial.sql", import.meta.url);

test("schema encodes personal-data and rating invariants", async () => {
  const sql = await readFile(migrationUrl, "utf8");

  assert.match(sql, /apple_subject text NOT NULL UNIQUE/);
  assert.match(sql, /PRIMARY KEY \(user_id, mix_id\)/);
  assert.match(sql, /score BETWEEN 1 AND 5/);
  assert.match(sql, /inventory_level AS ENUM \('plenty', 'low', 'empty'\)/);
  assert.match(sql, /official mix percentages must total 100/);
  assert.match(sql, /source_product_id <> substitute_product_id/);
});

test("published editorial records require provenance", async () => {
  const sql = await readFile(migrationUrl, "utf8");
  const provenanceChecks = sql.match(/\(status = 'draft'\) OR \(source_id IS NOT NULL AND verified_at IS NOT NULL\)/g) ?? [];
  assert.equal(provenanceChecks.length, 5);
});

test("inventory and personal components allow exactly one product origin", async () => {
  const sql = await readFile(migrationUrl, "utf8");
  assert.match(sql, /\(product_id IS NOT NULL\)::int \+ \(private_product_id IS NOT NULL\)::int = 1/);
  assert.match(sql, /\(product_id IS NOT NULL\)::int \+ \(private_product_id IS NOT NULL\)::int \+ \(freeform_name IS NOT NULL\)::int = 1/);
});

test("private flavor profiles and article bookmarks are account owned", async () => {
  const sql = await readFile(new URL("../migrations/006_private_products_and_article_bookmarks.sql", import.meta.url), "utf8");
  assert.match(sql, /flavor_profiles text\[\]/);
  assert.match(sql, /PRIMARY KEY\(user_id,article_id\)/);
  assert.match(sql, /REFERENCES app_users\(id\) ON DELETE CASCADE/);
});

test("Apple provider refresh credential is stored as a versioned encrypted envelope",async()=>{
  const sql=await readFile(new URL("../migrations/008_apple_provider_credentials.sql",import.meta.url),"utf8");
  assert.match(sql,/apple_refresh_token_encrypted text/);
  assert.match(sql,/apple_refresh_token_key_version text/);
  assert.doesNotMatch(sql,/refresh_token\s+text/i);
});

test("catalog product timestamps required by archival imports are added by migration 010",async()=>{
  const initial=await readFile(migrationUrl,"utf8");
  const migration=await readFile(new URL("../migrations/010_tobacco_product_timestamps.sql",import.meta.url),"utf8");
  const importer=await readFile(new URL("../src/db/importCatalogSeed.ts",import.meta.url),"utf8");
  const productTable=initial.match(/CREATE TABLE tobacco_products \([\s\S]*?\n\);/)?.[0]??"";
  assert.ok(productTable);
  assert.doesNotMatch(productTable,/updated_at timestamptz/i);
  assert.match(migration,/ALTER TABLE tobacco_products/);
  assert.match(migration,/ADD COLUMN created_at timestamptz NOT NULL DEFAULT now\(\)/);
  assert.match(migration,/ADD COLUMN updated_at timestamptz NOT NULL DEFAULT now\(\)/);
  assert.match(importer,/SET status='archived',updated_at=now\(\)/);
});
