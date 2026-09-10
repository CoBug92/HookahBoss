import assert from "node:assert/strict";
import test from "node:test";
import { buildApp } from "../src/app.js";

test("health endpoint checks the database", async () => {
  const calls: Array<{ text: unknown; values: unknown }> = [];
  const database = {
    query: async (text: unknown, values?: unknown) => {
      calls.push({ text, values });
      return { rows: [], rowCount: 0 } as never;
    }
  };
  const app = buildApp(database);
  const response = await app.inject({ method: "GET", url: "/health" });
  await app.close();

  assert.equal(response.statusCode, 200);
  assert.deepEqual(response.json(), { status: "ok" });
  assert.equal(calls[0]?.text, "SELECT 1");
});

test("mix detail returns a stable not-found response", async () => {
  const database = { query: async () => ({ rows: [], rowCount: 0 }) as never };
  const app = buildApp(database);
  const response = await app.inject({ method: "GET", url: "/v1/mixes/00000000-0000-0000-0000-000000000000?locale=en" });
  await app.close();

  assert.equal(response.statusCode, 404);
  assert.deepEqual(response.json(), { error: "mix_not_found" });
});

test("mix detail query requests the same rich profile as list",async()=>{
  let sql="";const database={query:async(text:unknown)=>{sql=String(text);return{rows:[{id:"mix",slug:"mix",title:"Mix",summary:"Summary",rating:null,ratings_count:0,components:[],tags:[],profiles:["dessert"],sweetness:"pronounced",acidity:"subtle",freshness:"subtle",strength:"strong"}],rowCount:1} as never}};
  const app=buildApp(database);const response=await app.inject({method:"GET",url:"/v1/mixes/00000000-0000-0000-0000-000000000000?locale=en"});await app.close();
  assert.equal(response.statusCode,200);assert.deepEqual(response.json().data.profiles,["dessert"]);assert.match(sql,/parts\.profiles/);assert.match(sql,/parts\.strength/);
});

test("public product catalog forces published status and binds locale and brand", async () => {
  let boundValues: readonly unknown[] | undefined;
  let sql = "";
  const database = {
    query: async (text: unknown, values?: readonly unknown[]) => {
      sql = String(text);
      boundValues = values;
      return { rows: [], rowCount: 0 } as never;
    }
  };
  const app = buildApp(database);
  const brandId = "00000000-0000-0000-0000-000000000001";
  const response = await app.inject({ method: "GET", url: `/v1/products?locale=en&status=archived&brandId=${brandId}` });
  await app.close();

  assert.equal(response.statusCode, 200);
  assert.deepEqual(boundValues, ["en", "published", brandId]);
  assert.match(sql, /CASE WHEN \$1::text = 'en' THEN p\.name_en ELSE p\.name_ru END/);
  assert.match(sql, /CASE WHEN \$1::text = 'en' THEN t\.name_en ELSE t\.name_ru END/);
  assert.match(sql, /p\.status = \$2 AND l\.status = 'published' AND b\.status = 'published'/);
  assert.doesNotMatch(sql, /\bLIMIT\b/);
});

test("public mix list localizes rich content, excludes unpublished records, preserves component order and is not silently truncated",async()=>{
  let sql="",values:readonly unknown[]|undefined;const database={query:async(text:unknown,bound?:readonly unknown[])=>{sql=String(text);values=bound;return{rows:[]} as never}};
  const app=buildApp(database);const response=await app.inject({method:"GET",url:"/v1/mixes?locale=en"});await app.close();
  assert.equal(response.statusCode,200);assert.deepEqual(values,["en"]);
  assert.match(sql,/CASE WHEN \$1 = 'en' THEN m\.title_en ELSE m\.title_ru END/);
  assert.match(sql,/CASE WHEN \$1='en' THEN cp\.name_en ELSE cp\.name_ru END/);
  assert.match(sql,/ORDER BY cc\.position/);
  assert.match(sql,/m\.status = 'published'/);assert.match(sql,/vp\.status<>'published'/);
  assert.doesNotMatch(sql,/\bLIMIT\b/);
});

test("public brands exclude non-published brands and lines without truncation",async()=>{
  let sql="";const database={query:async(text:unknown)=>{sql=String(text);return{rows:[]} as never}};const app=buildApp(database);
  const response=await app.inject({method:"GET",url:"/v1/brands?locale=en"});await app.close();assert.equal(response.statusCode,200);
  assert.match(sql,/l\.status = 'published'/);assert.match(sql,/b\.status = 'published'/);assert.doesNotMatch(sql,/\bLIMIT\b/);
});

test("public UUID filters fail with 400 before reaching PostgreSQL",async()=>{
  let calls=0;const database={query:async()=>{calls++;return{rows:[]} as never}};const app=buildApp(database);
  const mix=await app.inject({method:"GET",url:"/v1/mixes/not-a-uuid"});const products=await app.inject({method:"GET",url:"/v1/products?brandId=bad"});await app.close();
  assert.equal(mix.statusCode,400);assert.equal(products.statusCode,400);assert.equal(calls,0);
});

test("public catalog rejects unsupported locale before PostgreSQL",async()=>{
  let calls=0;const database={query:async()=>{calls++;return{rows:[]} as never}};const app=buildApp(database);
  for(const url of ["/v1/brands?locale=de","/v1/products?locale=de","/v1/mixes?locale=de","/v1/articles?locale=de"]){const response=await app.inject({method:"GET",url});assert.equal(response.statusCode,400);assert.equal(response.json().error,"invalid_locale")}
  await app.close();assert.equal(calls,0);
});

test("products cursor pagination is bounded, opaque and backward compatible",async()=>{
  const rows=[{id:"00000000-0000-4000-8000-000000000001"},{id:"00000000-0000-4000-8000-000000000002"}];let sql="";
  const app=buildApp({query:async(text:unknown)=>{sql=String(text);return{rows} as never}});const first=await app.inject({method:"GET",url:"/v1/products?pageSize=1"});
  assert.equal(first.statusCode,200);assert.equal(first.json().data.length,1);assert.equal(first.json().pagination.hasMore,true);assert.match(sql,/ORDER BY b\.name, l\.name, p\.name, p\.id LIMIT 2/);
  const cursor=encodeURIComponent(first.json().pagination.nextCursor);const next=await app.inject({method:"GET",url:`/v1/products?pageSize=1&cursor=${cursor}`});assert.equal(next.statusCode,200);assert.match(sql,/\(b\.name,l\.name,p\.name,p\.id\) >/);
  assert.equal((await app.inject({method:"GET",url:"/v1/products?pageSize=101"})).statusCode,400);assert.equal((await app.inject({method:"GET",url:"/v1/products?pageSize=1&cursor=bad"})).statusCode,400);await app.close();
});

test("mixes cursor pagination uses stable published/title/id ordering",async()=>{let sql="";const rows=[{id:"00000000-0000-4000-8000-000000000001"},{id:"00000000-0000-4000-8000-000000000002"}];const app=buildApp({query:async(text:unknown)=>{sql=String(text);return{rows} as never}});const response=await app.inject({method:"GET",url:"/v1/mixes?pageSize=1"});await app.close();assert.equal(response.json().pagination.hasMore,true);assert.match(sql,/ORDER BY m\.published_at DESC NULLS LAST, m\.title_ru, m\.id LIMIT 2/)});
