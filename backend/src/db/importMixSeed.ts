import { loadConfig } from "../config.js";
import { createPool } from "./pool.js";
import { allMixSources as mixSourcesV1,allOfficialMixes as officialMixesV1,validateMixSeed } from "../seeds/mixes.js";

export async function importMixSeed(databaseUrl:string):Promise<void>{
 const errors=validateMixSeed();if(errors.length)throw new Error(errors.join("\n"));const pool=createPool(databaseUrl);const client=await pool.connect();
 try{await client.query("BEGIN");const sourceIds=new Map<string,string>();
  for(const s of mixSourcesV1){const r=await client.query<{id:string}>(`INSERT INTO content_sources(url,title,publisher,checked_at,source_type,author) VALUES($1,$2,$3,$4,$5,$6) ON CONFLICT(url) DO UPDATE SET title=EXCLUDED.title,publisher=EXCLUDED.publisher,checked_at=EXCLUDED.checked_at,source_type=EXCLUDED.source_type,author=EXCLUDED.author RETURNING id`,[s.url,s.title,s.publisher,s.verifiedAt,s.sourceType,s.author??null]);sourceIds.set(s.key,r.rows[0]!.id);}
  for(const mix of officialMixesV1){const source=mixSourcesV1.find(s=>s.key===mix.sourceKey)!;const r=await client.query<{id:string}>(`INSERT INTO official_mixes(slug,title_ru,title_en,summary_ru,summary_en,translation_origin,source_confidence,status,source_id,verified_at,published_at) VALUES($1,$2,$3,$4,$5,$6,$7,'published',$8,$9,now()) ON CONFLICT(slug) DO UPDATE SET title_ru=EXCLUDED.title_ru,title_en=EXCLUDED.title_en,summary_ru=EXCLUDED.summary_ru,summary_en=EXCLUDED.summary_en,translation_origin=EXCLUDED.translation_origin,source_confidence=EXCLUDED.source_confidence,status='published',source_id=EXCLUDED.source_id,verified_at=EXCLUDED.verified_at,updated_at=now() RETURNING id`,[mix.slug,mix.titleRu,mix.titleEn,mix.summaryRu,mix.summaryEn,mix.translationOrigin,source.confidence,sourceIds.get(mix.sourceKey),source.verifiedAt]);const mixId=r.rows[0]!.id;await client.query("DELETE FROM official_mix_components WHERE mix_id=$1",[mixId]);
   for(const [index,c] of mix.components.entries()){const parts=c.product.split("/");const product=await client.query<{id:string}>(`SELECT p.id FROM tobacco_products p JOIN tobacco_lines l ON l.id=p.line_id JOIN brands b ON b.id=l.brand_id WHERE b.slug=$1 AND l.slug=$2 AND p.slug=$3`,parts);if(!product.rows[0])throw new Error(`Missing imported product ${c.product}`);await client.query("INSERT INTO official_mix_components(mix_id,product_id,percentage,position) VALUES($1,$2,$3,$4)",[mixId,product.rows[0].id,c.percentage,index+1]);}
  }
  await client.query("COMMIT");
 }catch(error){await client.query("ROLLBACK");throw error}finally{client.release();await pool.end()}
}
if(process.argv[1]&&import.meta.url===new URL(`file://${process.argv[1]}`).href)await importMixSeed(loadConfig().databaseUrl);
