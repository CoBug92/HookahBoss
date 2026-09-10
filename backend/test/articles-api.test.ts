import assert from "node:assert/strict";
import test from "node:test";
import { buildApp } from "../src/app.js";

test("article list binds localization, category and pagination and returns public metadata", async () => {
  let sql = ""; let values: readonly unknown[] | undefined;
  const database = { query: async (text: unknown, bound?: readonly unknown[]) => {
    sql = String(text); values = bound;
    return { rows: [{ id: "a", slug: "heat", title: "Heat", summary: "Summary", category: "bowls_heat", readingMinutes: 5, totalCount: 7 }], rowCount: 1 } as never;
  }};
  const app = buildApp(database);
  const response = await app.inject({ method: "GET", url: "/v1/articles?locale=en&category=bowls_heat&page=2&pageSize=3" });
  await app.close();
  assert.equal(response.statusCode, 200);
  assert.deepEqual(values, ["en", "bowls_heat", 3, 3]);
  assert.match(sql, /summary_en/); assert.match(sql, /category = \$2/);
  assert.deepEqual(response.json(), { data: [{ id: "a", slug: "heat", title: "Heat", summary: "Summary", category: "bowls_heat", readingMinutes: 5 }], pagination: { page: 2, pageSize: 3, total: 7 } });
});

test("article list defaults to Russian and validates filters", async () => {
  const calls:Array<{sql:string;values?:readonly unknown[]}>=[];
  const database = { query: async (text: unknown, bound?: readonly unknown[]) => { calls.push({sql:String(text),values:bound}); return String(text).includes("count(*)")?{rows:[{total:0}],rowCount:1} as never:{ rows: [], rowCount: 0 } as never; } };
  const app = buildApp(database);
  const ok = await app.inject({ method: "GET", url: "/v1/articles" });
  const badPage = await app.inject({ method: "GET", url: "/v1/articles?page=0" });
  const badCategory = await app.inject({ method: "GET", url: "/v1/articles?category=unknown" });
  await app.close();
  assert.deepEqual(calls[0]?.values, ["ru", 20, 0]);
  assert.deepEqual(ok.json().pagination, { page: 1, pageSize: 20, total: 0 });
  assert.deepEqual(badPage.json(), { error: "invalid_pagination" });
  assert.deepEqual(badCategory.json(), { error: "invalid_category" });
});

test("article list preserves total on an empty out-of-range page",async()=>{
  let call=0;const database={query:async()=>++call===1?{rows:[],rowCount:0} as never:{rows:[{total:10}],rowCount:1} as never};const app=buildApp(database);
  const response=await app.inject({method:"GET",url:"/v1/articles?page=99&pageSize=2"});await app.close();
  assert.deepEqual(response.json(),{data:[],pagination:{page:99,pageSize:2,total:10}});assert.equal(call,2);
});

test("article detail localizes structured content and related articles", async () => {
  let values: readonly unknown[] | undefined;
  const row = { id: "a", slug: "safety", title: "Safety", summary: "Summary", sections: [{ heading: "CO", body: "Body" }], category: "safety", readingMinutes: 6,
    related: [{ id: "b", slug: "care", title: "Care", summary: "Clean", category: "care", readingMinutes: 4 }] };
  const database = { query: async (_text: unknown, bound?: readonly unknown[]) => { values = bound; return { rows: [row], rowCount: 1 } as never; } };
  const app = buildApp(database);
  const response = await app.inject({ method: "GET", url: "/v1/articles/safety?locale=en" });
  await app.close();
  assert.equal(response.statusCode, 200); assert.deepEqual(values, ["safety", "en"]); assert.deepEqual(response.json(), { data: row });
  assert.equal("author" in response.json().data, false); assert.equal("publishedAt" in response.json().data, false);
});

test("article detail has a stable not-found response", async () => {
  const app = buildApp({ query: async () => ({ rows: [], rowCount: 0 }) as never });
  const response = await app.inject({ method: "GET", url: "/v1/articles/missing" });
  await app.close();
  assert.equal(response.statusCode, 404); assert.deepEqual(response.json(), { error: "article_not_found" });
});
