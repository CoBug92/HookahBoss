import type { PoolClient } from "pg";
import { loadConfig } from "../config.js";
import { tagNames, tagProfiles } from "../../seeds/catalog-v1.js";
import { allCatalogBrands as brands, allCatalogSources as sources, validateCatalogSeed } from "../seeds/catalog.js";
import { createPool } from "./pool.js";

async function upsertSource(client: PoolClient, source: (typeof sources)[number]): Promise<string> {
  const result = await client.query<{ id: string }>(`INSERT INTO content_sources(url,title,publisher,checked_at)
    VALUES ($1,$2,$3,$4) ON CONFLICT(url) DO UPDATE SET title=EXCLUDED.title,publisher=EXCLUDED.publisher,checked_at=EXCLUDED.checked_at RETURNING id`,
    [source.url, source.title, source.publisher, source.verifiedAt]);
  return result.rows[0]!.id;
}

export async function archiveMissingBlackburnProducts(client: Pick<PoolClient,"query">, present: Array<{lineSlug:string;productSlug:string}>): Promise<number> {
  const lineSlugs=present.map(item=>item.lineSlug), productSlugs=present.map(item=>item.productSlug);
  const result=await client.query(`UPDATE tobacco_products p SET status='archived',updated_at=now()
    FROM tobacco_lines l,brands b,content_sources s
    WHERE p.line_id=l.id AND l.brand_id=b.id AND p.source_id=s.id
      AND b.slug='blackburn' AND (s.url=$1 OR s.url=$2)
      AND p.status<>'archived'
      AND NOT EXISTS (SELECT 1 FROM unnest($3::text[],$4::text[]) current(line_slug,product_slug)
        WHERE current.line_slug=l.slug AND current.product_slug=p.slug)`,
    ["https://www.blckburn.com/taste","https://hookahportal.ru/tobaccos/blackburn",lineSlugs,productSlugs]);
  return result.rowCount ?? 0;
}

export async function archiveMissingDarksideProducts(client:Pick<PoolClient,"query">,present:Array<{lineSlug:string;productSlug:string}>):Promise<number>{
  const sourceUrls=["https://darkside-world.com/products/brand/darkside","https://darkside-world.com/products/catalog","https://t.me/s/trydarkside/6233","https://t.me/s/trydarkside/5757"];
  const result=await client.query(`UPDATE tobacco_products p SET status='archived',updated_at=now()
    FROM tobacco_lines l,brands b,content_sources s
    WHERE p.line_id=l.id AND l.brand_id=b.id AND p.source_id=s.id
      AND b.slug='darkside' AND s.url=ANY($1::text[]) AND p.status<>'archived'
      AND NOT EXISTS (SELECT 1 FROM unnest($2::text[],$3::text[]) current(line_slug,product_slug)
        WHERE current.line_slug=l.slug AND current.product_slug=p.slug)`,
    [sourceUrls,present.map(item=>item.lineSlug),present.map(item=>item.productSlug)]);
  return result.rowCount??0;
}

export async function importCatalogSeed(databaseUrl: string): Promise<void> {
  const errors = validateCatalogSeed();
  if (errors.length) throw new Error(`Invalid catalog seed:\n${errors.join("\n")}`);
  const pool = createPool(databaseUrl);
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    const sourceIds = new Map<string, string>();
    for (const source of sources) sourceIds.set(source.key, await upsertSource(client, source));
    const tagIds = new Map<string, string>();
    for (const [slug, profile] of Object.entries(tagProfiles)) {
      const names = tagNames[slug]!;
      const result = await client.query<{ id: string }>(`INSERT INTO flavor_tags(slug,name_ru,name_en,profile) VALUES ($1,$2,$3,$4)
        ON CONFLICT(slug) DO UPDATE SET name_ru=EXCLUDED.name_ru,name_en=EXCLUDED.name_en,profile=EXCLUDED.profile RETURNING id`, [slug, names[0], names[1], profile]);
      tagIds.set(slug, result.rows[0]!.id);
    }
    for (const brand of brands) {
      const brandResult = await client.query<{ id: string }>(`INSERT INTO brands(slug,name,status,source_id,verified_at) VALUES ($1,$2,'published',$3,$4)
        ON CONFLICT(slug) DO UPDATE SET name=EXCLUDED.name,status='published',source_id=EXCLUDED.source_id,verified_at=EXCLUDED.verified_at,updated_at=now() RETURNING id`,
        [brand.slug, brand.name, sourceIds.get(brand.sourceKey), sources.find(item => item.key === brand.sourceKey)!.verifiedAt]);
      for (const line of brand.lines) {
        const lineSource = sources.find(item => item.key === line.sourceKey)!;
        const lineResult = await client.query<{ id: string }>(`INSERT INTO tobacco_lines(brand_id,slug,name,strength,status,source_id,verified_at) VALUES ($1,$2,$3,$4,'published',$5,$6)
          ON CONFLICT(brand_id,slug) DO UPDATE SET name=EXCLUDED.name,strength=EXCLUDED.strength,status='published',source_id=EXCLUDED.source_id,verified_at=EXCLUDED.verified_at RETURNING id`,
          [brandResult.rows[0]!.id, line.slug, line.name, line.strength, sourceIds.get(line.sourceKey), lineSource.verifiedAt]);
        for (const product of line.products) {
          const productSource = sources.find(item => item.key === product.sourceKey)!;
          const productResult = await client.query<{ id: string }>(`INSERT INTO tobacco_products(line_id,slug,name,name_ru,name_en,description_ru,description_en,translation_origin,source_confidence,sweetness,acidity,freshness,status,source_id,verified_at)
            VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,'published',$13,$14)
            ON CONFLICT(line_id,slug) DO UPDATE SET name=EXCLUDED.name,name_ru=EXCLUDED.name_ru,name_en=EXCLUDED.name_en,description_ru=EXCLUDED.description_ru,description_en=EXCLUDED.description_en,translation_origin=EXCLUDED.translation_origin,source_confidence=EXCLUDED.source_confidence,sweetness=EXCLUDED.sweetness,acidity=EXCLUDED.acidity,freshness=EXCLUDED.freshness,status='published',source_id=EXCLUDED.source_id,verified_at=EXCLUDED.verified_at RETURNING id`,
            [lineResult.rows[0]!.id, product.slug, product.nameRu, product.nameRu, product.nameEn, product.descriptionRu ?? null, product.descriptionEn ?? null, product.translationOrigin, productSource.confidence, product.sweetness, product.acidity, product.freshness, sourceIds.get(product.sourceKey), productSource.verifiedAt]);
          const productId = productResult.rows[0]!.id;
          await client.query("DELETE FROM tobacco_product_tags WHERE product_id=$1", [productId]);
          for (const tag of product.tags) await client.query("INSERT INTO tobacco_product_tags(product_id,tag_id,weight) VALUES ($1,$2,1)", [productId, tagIds.get(tag)]);
        }
      }
    }
    const blackburn=brands.find(brand=>brand.slug==="blackburn");
    if(blackburn) await archiveMissingBlackburnProducts(client,blackburn.lines.flatMap(line=>line.products.map(product=>({lineSlug:line.slug,productSlug:product.slug}))));
    const darkside=brands.find(brand=>brand.slug==="darkside");
    if(darkside) await archiveMissingDarksideProducts(client,darkside.lines.flatMap(line=>line.products.map(product=>({lineSlug:line.slug,productSlug:product.slug}))));
    await client.query("COMMIT");
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

if (process.argv[1] && import.meta.url === new URL(`file://${process.argv[1]}`).href) await importCatalogSeed(loadConfig().databaseUrl);
