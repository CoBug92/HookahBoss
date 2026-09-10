import { officialMixesV1, mixSourcesV1, type OfficialMixSeed } from "../../seeds/mixes-v1.js";
import { officialMixesV2, mixSourcesV2 } from "../../seeds/mixes-v2.js";
import { officialMixesV3, mixSourcesV3 } from "../../seeds/mixes-v3.js";
import { allCatalogBrands } from "./catalog.js";

export const allOfficialMixes=[...officialMixesV1,...officialMixesV2,...officialMixesV3];
export const allMixSources=[...mixSourcesV1,...mixSourcesV2,...mixSourcesV3];

export function validateMixSeed(mixes:OfficialMixSeed[]=allOfficialMixes):string[]{
 const errors:string[]=[]; const sourceKeys=new Set(allMixSources.map(s=>s.key)); const slugs=new Set<string>();
 const products=new Set(allCatalogBrands.flatMap(b=>b.lines.flatMap(l=>l.products.map(p=>`${b.slug}/${l.slug}/${p.slug}`))));
 for(const source of allMixSources){ if(!source.url.trim()||!source.title.trim()||!source.publisher.trim()||!source.accessedAt||!source.verifiedAt) errors.push(`source ${source.key}: incomplete provenance`);if(!URL.canParse(source.url))errors.push(`source ${source.key}: invalid URL`);if(!new Set(["high","medium","low"]).has(source.confidence))errors.push(`source ${source.key}: invalid confidence`);if(!source.sourceType||!new Set(["editorial_recipe","user_recipe"]).has(source.sourceType))errors.push(`source ${source.key}: invalid recipe source type`);if(source.sourceType==="user_recipe"&&!source.author?.trim())errors.push(`source ${source.key}: missing author`);if(source.percentageEvidence!=="explicit_numeric_percentages")errors.push(`source ${source.key}: percentages are not source-explicit`); }
 for(const mix of mixes){
  if(slugs.has(mix.slug)) errors.push(`${mix.slug}: duplicate slug`); slugs.add(mix.slug);
  if(![mix.slug,mix.titleRu,mix.titleEn,mix.summaryRu,mix.summaryEn].every(v=>v.trim().length>0)) errors.push(`${mix.slug}: blank locale field`);
  if(!sourceKeys.has(mix.sourceKey)) errors.push(`${mix.slug}: unknown source`);
  const refs=new Set<string>();
  for(const component of mix.components){ if(refs.has(component.product)) errors.push(`${mix.slug}: duplicate component`); refs.add(component.product); if(!products.has(component.product)) errors.push(`${mix.slug}: unknown product ${component.product}`); if(!Number.isInteger(component.percentage)||component.percentage<1||component.percentage>100) errors.push(`${mix.slug}: invalid percentage`); }
  if(mix.components.reduce((sum,c)=>sum+c.percentage,0)!==100) errors.push(`${mix.slug}: percentages do not total 100`);
 }
 return errors;
}

if(process.argv[1]&&import.meta.url===new URL(`file://${process.argv[1]}`).href){const errors=validateMixSeed();if(errors.length){console.error(errors.join("\n"));process.exitCode=1}else console.log(JSON.stringify({valid:true,mixes:allOfficialMixes.length,sources:allMixSources.length,rejectedCandidates:20}));}
