import { brands, sources, tagNames, tagProfiles, type SeedBrand } from "../../seeds/catalog-v1.js";
import { brandsV2, sourcesV2 } from "../../seeds/catalog-v2.js";
import { brandsV3, sourcesV3 } from "../../seeds/catalog-v3.js";
import { mixSupportBrands } from "../../seeds/catalog-mix-support-v1.js";
import { mixSupportBrandsV2, mixSupportSourcesV2 } from "../../seeds/catalog-mix-support-v2.js";
import { mixSupportBrandsV3, mixSupportSourcesV3 } from "../../seeds/catalog-mix-support-v3.js";
import { blackburnSnapshot } from "../../seeds/blackburn-generated.js";
import { darksideSnapshot } from "../../seeds/darkside-generated.js";

const blackburnSource = {
  key: "blackburn-official", url: blackburnSnapshot.source.pageUrl,
  title: "BlackBurn official taste catalog", publisher: blackburnSnapshot.source.publisher,
  accessedAt: blackburnSnapshot.source.accessedAt, verifiedAt: blackburnSnapshot.source.verifiedAt,
  confidence: "high" as const,
  notes: `Official catalog page; product API ${blackburnSnapshot.source.apiUrl} was discovered from its store configuration. Commerce and media fields are excluded.`
};
const familySlug = (family: string) => family.toLowerCase();
export const blackburnBrand: SeedBrand = {
  slug: "blackburn", name: "BlackBurn", sourceKey: blackburnSource.key,
  lines: (["Original", "Shock", "Something", "KMTM"] as const).map(family => ({
    slug: familySlug(family), name: family, strength: "medium", sourceKey: blackburnSource.key,
    products: blackburnSnapshot.products.filter(product => product.family === family).map(product => ({
      slug: product.slug, nameRu: product.title, nameEn: product.title,
      descriptionRu: product.descriptionRu, translationOrigin: "official" as const,
      sourceKey: blackburnSource.key, tags: product.tags,
      sweetness: product.sweetness, acidity: product.acidity, freshness: product.freshness
    }))
  }))
};

const darksideSource = {
  key:"darkside-official",url:darksideSnapshot.source.pageUrl,title:"DARKSIDE official full flavor catalog",publisher:darksideSnapshot.source.publisher,
  accessedAt:darksideSnapshot.source.accessedAt,verifiedAt:darksideSnapshot.source.verifiedAt,confidence:"high" as const,
  notes:`Official product page and catalog; ${darksideSnapshot.source.apiUrl} and brand id were discovered from the public Nuxt runtime. Commerce, availability and media fields are excluded.`
};
const previousDarkside=mixSupportBrandsV2.find(brand=>brand.slug==="darkside");
const officialDarksideSlugs=new Set(darksideSnapshot.products.map(product=>product.slug));
const retainedReferencedProducts=previousDarkside?.lines.flatMap(line=>line.products).filter(product=>!officialDarksideSlugs.has(product.slug))??[];
export const darksideBrand:SeedBrand={slug:"darkside",name:"DARKSIDE",sourceKey:darksideSource.key,lines:[{slug:"core",name:"Core",strength:"medium",sourceKey:darksideSource.key,products:[
  ...darksideSnapshot.products.map(product=>({slug:product.slug,nameRu:product.title,nameEn:product.title,descriptionRu:product.descriptionRu,translationOrigin:"official" as const,sourceKey:darksideSource.key,tags:product.tags,sweetness:product.sweetness,acidity:product.acidity,freshness:product.freshness})),
  ...retainedReferencedProducts
]}]};

export const allCatalogBrands = [...brands.filter(brand=>brand.slug!=="darkside"), ...brandsV2.filter(brand => brand.slug !== "blackburn"), ...brandsV3, ...mixSupportBrands, ...mixSupportBrandsV2.filter(brand=>brand.slug!=="darkside"), ...mixSupportBrandsV3, blackburnBrand,darksideBrand];
export const allCatalogSources = [...sources.filter(source=>source.key!=="darkside-catalog"), ...sourcesV2.filter(source => !["blackburn-official", "blackburn-industry"].includes(source.key)), ...sourcesV3, ...mixSupportSourcesV2, ...mixSupportSourcesV3, blackburnSource,darksideSource];

const nonblank = (value: unknown): value is string => typeof value === "string" && value.trim().length > 0;

export function validateCatalogSeed(seedBrands: SeedBrand[] = allCatalogBrands): string[] {
  const errors: string[] = [];
  const sourceKeys = new Set(allCatalogSources.map(source => source.key));
  const productKeys = new Set<string>();
  const strengths = new Set(["light", "medium", "strong"]);
  const intensities = new Set(["subtle", "pronounced"]);

  for (const source of allCatalogSources) {
    for (const [field, value] of Object.entries(source)) if (!nonblank(value)) errors.push(`source ${source.key}: ${field} is blank`);
    if (!URL.canParse(source.url)) errors.push(`source ${source.key}: invalid URL`);
    if (!new Set(["high", "medium", "low"]).has(source.confidence)) errors.push(`source ${source.key}: invalid confidence`);
  }

  for (const brand of seedBrands) {
    if (![brand.slug, brand.name].every(nonblank)) errors.push("brand has a blank field");
    if (!sourceKeys.has(brand.sourceKey)) errors.push(`brand ${brand.slug}: unknown source`);
    for (const line of brand.lines) {
      if (![line.slug, line.name].every(nonblank)) errors.push(`${brand.slug}: line has a blank field`);
      if (!strengths.has(line.strength)) errors.push(`${brand.slug}/${line.slug}: invalid strength`);
      if (!sourceKeys.has(line.sourceKey)) errors.push(`${brand.slug}/${line.slug}: unknown source`);
      for (const product of line.products) {
        const key = `${brand.slug}/${line.slug}/${product.slug}`;
        if (productKeys.has(key)) errors.push(`${key}: duplicate product`);
        productKeys.add(key);
        if (![product.slug, product.nameRu, product.nameEn].every(nonblank)) errors.push(`${key}: blank required locale/name`);
        if (product.descriptionRu !== undefined && !nonblank(product.descriptionRu)) errors.push(`${key}: blank RU description`);
        if (product.descriptionEn !== undefined && !nonblank(product.descriptionEn)) errors.push(`${key}: blank EN description`);
        if (!sourceKeys.has(product.sourceKey)) errors.push(`${key}: unknown provenance`);
        if (!new Set(["official", "normalized_translation"]).has(product.translationOrigin)) errors.push(`${key}: invalid translation origin`);
        for (const intensity of [product.sweetness, product.acidity, product.freshness]) if (!intensities.has(intensity)) errors.push(`${key}: invalid intensity`);
        if (product.tags.length === 0) errors.push(`${key}: no tags`);
        for (const tag of product.tags) if (!tagProfiles[tag] || !tagNames[tag]?.every(nonblank)) errors.push(`${key}: invalid/unlocalized tag ${tag}`);
      }
    }
  }
  return errors;
}

export function catalogStats(seedBrands: SeedBrand[] = allCatalogBrands) {
  return { brands: new Set(seedBrands.map(brand => brand.slug)).size, products: seedBrands.flatMap(brand => brand.lines.flatMap(line => line.products)).length };
}

if (process.argv[1] && import.meta.url === new URL(`file://${process.argv[1]}`).href) {
  const errors = validateCatalogSeed();
  if (errors.length) {
    console.error(errors.join("\n"));
    process.exitCode = 1;
  } else {
    console.log(JSON.stringify({ valid: true, ...catalogStats(), sources: allCatalogSources.length }));
  }
}
