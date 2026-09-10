import assert from "node:assert/strict";
import test from "node:test";
import { buildApp } from "../src/app.js";
import { AppleSubjectAllowlist, type AppleTokenVerifier } from "../src/auth.js";

const verifier: AppleTokenVerifier = { async verify() { return { subject: "admin-subject" }; } };
const authHeader = { authorization: "Bearer token" };

function databaseWith(handler?: (sql: string, values?: readonly unknown[]) => unknown) {
  return {
    query: async (sql: string, values?: readonly unknown[]) => {
      if (sql.includes("INSERT INTO app_users")) return { rows: [{ id: "admin-user", apple_subject: "admin-subject" }] } as never;
      return (handler?.(sql, values) ?? { rows: [] }) as never;
    }
  };
}

test("admin routes distinguish unauthorized and forbidden", async () => {
  const database = databaseWith();
  const app = buildApp(database as never, false, verifier, new AppleSubjectAllowlist([]));
  const unauthorized = await app.inject({ method: "GET", url: "/v1/admin/brands" });
  const forbidden = await app.inject({ method: "GET", url: "/v1/admin/brands", headers: authHeader });
  await app.close();
  assert.equal(unauthorized.statusCode, 401);
  assert.equal(forbidden.statusCode, 403);
});

test("admin capability is authenticated and reveals only the grant",async()=>{
  const database=databaseWith();
  const app=buildApp(database as never,false,verifier,new AppleSubjectAllowlist(["admin-subject"]));
  const unauthenticated=await app.inject({method:"GET",url:"/v1/me/admin-capabilities"});assert.equal(unauthenticated.statusCode,401);
  const granted=await app.inject({method:"GET",url:"/v1/me/admin-capabilities",headers:authHeader});assert.equal(granted.statusCode,200);assert.deepEqual(granted.json(),{data:{admin:true}});
  await app.close();
});

test("explicit Apple subject allowlist grants admin CRUD access", async () => {
  const calls: string[] = [];
  const database = databaseWith((sql) => {
    calls.push(sql);
    if (sql.includes("INSERT INTO content_sources")) return { rows: [{ id: "source-1", url: "https://example.com" }] };
    return { rows: [] };
  });
  const app = buildApp(database as never, false, verifier, new AppleSubjectAllowlist(["admin-subject"]));
  const response = await app.inject({
    method: "POST", url: "/v1/admin/sources", headers: authHeader,
    payload: { url: "https://example.com", checkedAt: "2026-09-09" }
  });
  await app.close();
  assert.equal(response.statusCode, 201);
  assert.equal(response.json().data.id, "source-1");
  assert.match(calls[0] ?? "", /INSERT INTO content_sources/);
});

test("publishing content without provenance is rejected before mutation", async () => {
  let mutationCalls = 0;
  const database = databaseWith(() => { mutationCalls += 1; return { rows: [] }; });
  const app = buildApp(database as never, false, verifier, new AppleSubjectAllowlist(["admin-subject"]));
  const response = await app.inject({
    method: "POST", url: "/v1/admin/brands", headers: authHeader,
    payload: { slug: "brand", name: "Brand", status: "published" }
  });
  await app.close();
  assert.equal(response.statusCode, 400);
  assert.equal(response.json().error, "published_content_requires_provenance");
  assert.equal(mutationCalls, 0);
});

test("official mix rejects an invalid percentage total", async () => {
  const database = databaseWith();
  const app = buildApp(database as never, false, verifier, new AppleSubjectAllowlist(["admin-subject"]));
  const response = await app.inject({
    method: "POST", url: "/v1/admin/official-mixes", headers: authHeader,
    payload: {
      slug: "mix", titleRu: "Микс", titleEn: "Mix",
      components: [{ productId: "p1", percentage: 40 }, { productId: "p2", percentage: 40 }]
    }
  });
  await app.close();
  assert.equal(response.statusCode, 400);
  assert.equal(response.json().error, "mix_percentages_must_total_100");
});

test("localized article fields cannot be blank", async () => {
  const database = databaseWith();
  const app = buildApp(database as never, false, verifier, new AppleSubjectAllowlist(["admin-subject"]));
  const response = await app.inject({
    method: "POST", url: "/v1/admin/articles", headers: authHeader,
    payload: { slug: "care", titleRu: "Уход", titleEn: "", bodyRu: "Текст", bodyEn: "Text" }
  });
  await app.close();
  assert.equal(response.statusCode, 400);
});
