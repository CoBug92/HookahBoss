import assert from "node:assert/strict";
import test from "node:test";
import { brands } from "../seeds/catalog-v1.js";
import { brandsV2 } from "../seeds/catalog-v2.js";
import { brandsV3 } from "../seeds/catalog-v3.js";
import { catalogStats, validateCatalogSeed } from "../src/seeds/catalog.js";

test("catalog seed is complete and valid", () => {
  assert.deepEqual(validateCatalogSeed(), []);
  assert.deepEqual(catalogStats(), { brands: 13, products: 383 });
  assert.equal(catalogStats(brandsV2).products, 60);
  assert.equal(catalogStats(brandsV3).products, 60);
});

test("DARKSIDE is one merged full line and preserves every mix product reference",async()=>{
  const {darksideBrand,allCatalogBrands}=await import("../src/seeds/catalog.js");
  const {validateMixSeed}=await import("../src/seeds/mixes.js");
  assert.equal(allCatalogBrands.filter(brand=>brand.slug==="darkside").length,1);
  assert.equal(darksideBrand.lines.flatMap(line=>line.products).length,76);
  assert(darksideBrand.lines[0]?.products.some(product=>product.slug==="lime-up"));
  assert(darksideBrand.lines[0]?.products.some(product=>product.slug==="kalee-grapefruit-2"));
  assert.deepEqual(validateMixSeed(),[]);
});

test("BlackBurn is replaced by the complete official snapshot", async () => {
  const { blackburnBrand, allCatalogSources } = await import("../src/seeds/catalog.js");
  assert.equal(blackburnBrand.lines.flatMap(line => line.products).length, 80);
  assert.equal(allCatalogSources.some(source => source.key === "blackburn-industry"), false);
  const iceberg=blackburnBrand.lines.flatMap(line=>line.products).find(product=>product.nameRu==="Iceberg");
  assert.deepEqual(iceberg?.tags,["cooling"]);
});

test("catalog validation detects duplicates across seed versions", () => {
  assert(validateCatalogSeed([...brands, ...brandsV2, ...brandsV3, structuredClone(brands[0]!)])
    .some(error => error.includes("duplicate product")));
});

test("catalog validation detects uniqueness and provenance violations", () => {
  const copy = structuredClone(brands);
  copy[0]!.lines[0]!.products.push(structuredClone(copy[0]!.lines[0]!.products[0]!));
  copy[1]!.lines[0]!.products[0]!.sourceKey = "missing";
  const errors = validateCatalogSeed(copy);
  assert(errors.some(error => error.includes("duplicate product")));
  assert(errors.some(error => error.includes("unknown provenance")));
});

test("MUSTHAVE is one complete official line and preserves mix references",async()=>{const{musthaveBrand,allCatalogBrands}=await import("../src/seeds/catalog.js");const{validateMixSeed}=await import("../src/seeds/mixes.js");assert.equal(allCatalogBrands.filter(brand=>brand.slug==="musthave").length,1);assert.equal(musthaveBrand.lines[0]?.products.length,99);assert.deepEqual(validateMixSeed(),[])});
