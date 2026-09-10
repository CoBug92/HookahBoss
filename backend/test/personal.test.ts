import assert from "node:assert/strict";
import test from "node:test";
import { buildApp } from "../src/app.js";
import { InvalidAppleTokenError, type AppleTokenVerifier } from "../src/auth.js";

const validVerifier: AppleTokenVerifier = {
  async verify(token) {
    assert.equal(token, "valid-token");
    return { subject: "apple-user-1", email: "person@example.com" };
  }
};

test("personal endpoints reject a missing bearer token", async () => {
  const database = { query: async () => { throw new Error("database must not be called"); } };
  const app = buildApp(database as never);
  const response = await app.inject({ method: "GET", url: "/v1/me/inventory" });
  await app.close();
  assert.equal(response.statusCode, 401);
  assert.deepEqual(response.json(), { error: "unauthorized" });
});

test("personal endpoints reject a token rejected by the verifier", async () => {
  const verifier: AppleTokenVerifier = { async verify() { throw new InvalidAppleTokenError(); } };
  const database = { query: async () => { throw new Error("database must not be called"); } };
  const app = buildApp(database as never, false, verifier);
  const response = await app.inject({ method: "GET", url: "/v1/me/inventory", headers: { authorization: "Bearer bad" } });
  await app.close();
  assert.equal(response.statusCode, 401);
});

test("rating is upserted for the authenticated user", async () => {
  const mixId = "00000000-0000-4000-8000-000000000001";
  const calls: Array<{ sql: string; values?: readonly unknown[] }> = [];
  const database = {
    query: async (sql: string, values?: readonly unknown[]) => {
      calls.push({ sql, values });
      if (sql.includes("INSERT INTO app_users")) return { rows: [{ id: "user-1", apple_subject: "apple-user-1" }] } as never;
      return { rows: [{ mixId, score: 4, updatedAt: "now" }] } as never;
    }
  };
  const app = buildApp(database as never, false, validVerifier);
  const response = await app.inject({
    method: "PUT", url: `/v1/me/ratings/${mixId}`, headers: { authorization: "Bearer valid-token" }, payload: { score: 4 }
  });
  await app.close();

  assert.equal(response.statusCode, 200);
  assert.deepEqual(calls[1]?.values, ["user-1", mixId, 4]);
  assert.match(calls[1]?.sql ?? "", /ON CONFLICT \(user_id, mix_id\) DO UPDATE/);
});

test("rating validation rejects values outside 1 through 5", async () => {
  let calls = 0;
  const database = {
    query: async () => {
      calls += 1;
      return { rows: [{ id: "user-1", apple_subject: "apple-user-1" }] } as never;
    }
  };
  const app = buildApp(database as never, false, validVerifier);
  const response = await app.inject({
    method: "PUT", url: "/v1/me/ratings/00000000-0000-4000-8000-000000000001", headers: { authorization: "Bearer valid-token" }, payload: { score: 6 }
  });
  await app.close();
  assert.equal(response.statusCode, 400);
  assert.equal(calls, 1, "only authentication user resolution may query the database");
});

test("private inventory upsert enforces ownership in the database query", async () => {
  const calls: Array<{ sql: string; values?: readonly unknown[] }> = [];
  const database = {
    query: async (sql: string, values?: readonly unknown[]) => {
      calls.push({ sql, values });
      if (sql.includes("INSERT INTO app_users")) return { rows: [{ id: "user-1", apple_subject: "apple-user-1" }] } as never;
      return { rows: [] } as never;
    }
  };
  const app = buildApp(database as never, false, validVerifier);
  const response = await app.inject({
    method: "PUT", url: "/v1/me/inventory", headers: { authorization: "Bearer valid-token" },
    payload: { privateProductId: "00000000-0000-0000-0000-000000000099", level: "low" }
  });
  await app.close();

  assert.equal(response.statusCode, 404);
  assert.match(calls[1]?.sql ?? "", /WHERE id = \$2 AND user_id = \$1/);
  assert.deepEqual(calls[1]?.values, ["user-1", "00000000-0000-0000-0000-000000000099", "low"]);
});

test("inventory requires one product origin and a known level", async () => {
  const database = {
    query: async () => ({ rows: [{ id: "user-1", apple_subject: "apple-user-1" }] }) as never
  };
  const app = buildApp(database as never, false, validVerifier);
  const headers = { authorization: "Bearer valid-token" };
  const both = await app.inject({ method: "PUT", url: "/v1/me/inventory", headers, payload: { productId: "a", privateProductId: "b", level: "low" } });
  const badLevel = await app.inject({ method: "PUT", url: "/v1/me/inventory", headers, payload: { productId: "a", level: "full" } });
  await app.close();
  assert.equal(both.statusCode, 400);
  assert.equal(badLevel.statusCode, 400);
});

test("library snapshot is owner scoped and combines personal collections", async () => {
  const calls:string[]=[];
  const database={query:async(sql:string)=>{calls.push(sql);if(sql.includes("INSERT INTO app_users"))return{rows:[{id:"user-1",apple_subject:"apple-user-1"}]} as never;return{rows:[]} as never}};
  const app=buildApp(database as never,false,validVerifier);
  const response=await app.inject({method:"GET",url:"/v1/me/library",headers:{authorization:"Bearer valid-token"}});await app.close();
  assert.equal(response.statusCode,200);assert.deepEqual(response.json().data,{favorites:[],ratings:[],inventory:[],personalMixes:[],articleBookmarks:[]});
  assert.ok(calls.slice(1).every(sql=>sql.includes("user_id=$1") || sql.includes("i.user_id=$1") || sql.includes("m.user_id=$1")));
});

test("inventory matching applies deny rules and private exact flavor semantics",async()=>{
  const database={query:async(sql:string)=>{if(sql.includes("INSERT INTO app_users"))return{rows:[{id:"user-1",apple_subject:"apple-user-1"}]} as never;assert.match(sql,/substitution_deny_rules/);assert.match(sql,/private_available/);return{rows:[{mixId:"00000000-0000-4000-8000-000000000001",kind:"ready"}]} as never}};
  const app=buildApp(database as never,false,validVerifier);const response=await app.inject({method:"GET",url:"/v1/me/inventory/matches",headers:{authorization:"Bearer valid-token"}});await app.close();assert.equal(response.statusCode,200);assert.equal(response.json().data[0].kind,"ready");
});

test("inventory matching localizes labels and excludes unpublished catalog records",async()=>{
  const database={query:async(sql:string,values?:readonly unknown[])=>{if(sql.includes("INSERT INTO app_users"))return{rows:[{id:"user-1",apple_subject:"apple-user-1"}]} as never;assert.match(sql,/m\.status='published'/);assert.match(sql,/p\.status='published'/);assert.match(sql,/CASE WHEN \$2='en'/);assert.deepEqual(values,["user-1","en"]);return{rows:[]} as never}};
  const app=buildApp(database as never,false,validVerifier);const response=await app.inject({method:"GET",url:"/v1/me/inventory/matches?locale=en",headers:{authorization:"Bearer valid-token"}});await app.close();assert.equal(response.statusCode,200);
});

test("inventory mutations reject malformed UUIDs before mutation queries",async()=>{
  let calls=0;const database={query:async(sql:string)=>{calls++;if(sql.includes("INSERT INTO app_users"))return{rows:[{id:"user-1",apple_subject:"apple-user-1"}]} as never;return{rows:[]} as never}};const app=buildApp(database as never,false,validVerifier);const headers={authorization:"Bearer valid-token"};
  const put=await app.inject({method:"PUT",url:"/v1/me/inventory",headers,payload:{productId:"bad",level:"low"}});const del=await app.inject({method:"DELETE",url:"/v1/me/inventory/bad",headers});await app.close();assert.equal(put.statusCode,400);assert.equal(del.statusCode,400);assert.equal(calls,2);
});

test("rating rejects malformed UUID before a mutation query",async()=>{
  let calls=0;const database={query:async()=>{calls++;return{rows:[{id:"user-1",apple_subject:"apple-user-1"}]} as never}};const app=buildApp(database as never,false,validVerifier);const response=await app.inject({method:"PUT",url:"/v1/me/ratings/not-a-uuid",headers:{authorization:"Bearer valid-token"},payload:{score:4}});await app.close();assert.equal(response.statusCode,400);assert.equal(calls,1);
});

test("private product create validates input and is owner scoped",async()=>{
  const calls:Array<{sql:string;values?:readonly unknown[]}>=[];const database={query:async(sql:string,values?:readonly unknown[])=>{calls.push({sql,values});if(sql.includes("INSERT INTO app_users"))return{rows:[{id:"user-1",apple_subject:"apple-user-1"}]} as never;return{rows:[{id:"00000000-0000-4000-8000-000000000009",brandName:"Home",lineName:null,flavorName:"Peach",flavorProfiles:["fruit"],createdAt:"now"}]} as never}};const app=buildApp(database as never,false,validVerifier);const response=await app.inject({method:"POST",url:"/v1/me/private-products",headers:{authorization:"Bearer valid-token"},payload:{brandName:"Home",flavorName:"Peach",flavorProfiles:["fruit"]}});assert.equal(response.statusCode,201);assert.deepEqual(calls[1]?.values,[null,"user-1","Home",null,"Peach",["fruit"]]);const invalid=await app.inject({method:"POST",url:"/v1/me/private-products",headers:{authorization:"Bearer valid-token"},payload:{brandName:"",flavorName:"Peach",flavorProfiles:[]}});await app.close();assert.equal(invalid.statusCode,400);
});

test("private product accepts the fresh profile",async()=>{
  const database={query:async(sql:string)=>sql.includes("INSERT INTO app_users")?{rows:[{id:"user-1",apple_subject:"apple-user-1"}]}:{rows:[{id:"00000000-0000-4000-8000-000000000009",brandName:"Home",lineName:null,flavorName:"Ice",flavorProfiles:["fresh"],createdAt:"now"}]}};
  const app=buildApp(database as never,false,validVerifier);const response=await app.inject({method:"POST",url:"/v1/me/private-products",headers:{authorization:"Bearer valid-token"},payload:{brandName:"Home",flavorName:"Ice",flavorProfiles:["fresh"]}});await app.close();assert.equal(response.statusCode,201);assert.deepEqual(response.json().data.flavorProfiles,["fresh"]);
});

test("private product list and delete never cross account ownership",async()=>{
  const calls:Array<{sql:string;values?:readonly unknown[]}>=[];const id="00000000-0000-4000-8000-000000000009";const database={query:async(sql:string,values?:readonly unknown[])=>{calls.push({sql,values});if(sql.includes("INSERT INTO app_users"))return{rows:[{id:"user-1",apple_subject:"apple-user-1"}]} as never;return{rows:[]} as never}};const app=buildApp(database as never,false,validVerifier);await app.inject({method:"GET",url:"/v1/me/private-products",headers:{authorization:"Bearer valid-token"}});const deleted=await app.inject({method:"DELETE",url:`/v1/me/private-products/${id}`,headers:{authorization:"Bearer valid-token"}});await app.close();assert.equal(deleted.statusCode,204);assert.ok(calls.some(call=>call.sql.includes("WHERE user_id=$1")));assert.ok(calls.some(call=>call.sql.includes("id=$1 AND user_id=$2")));
});

test("article bookmarks are authenticated owner scoped and idempotent",async()=>{const calls:Array<{sql:string;values?:readonly unknown[]}>=[];const database={query:async(sql:string,values?:readonly unknown[])=>{calls.push({sql,values});if(sql.includes("INSERT INTO app_users"))return{rows:[{id:"user-1",apple_subject:"apple-user-1"}]} as never;return{rows:[{article_id:"article-1"}]} as never}};const app=buildApp(database as never,false,validVerifier);const put=await app.inject({method:"PUT",url:"/v1/me/article-bookmarks/safety",headers:{authorization:"Bearer valid-token"}});const del=await app.inject({method:"DELETE",url:"/v1/me/article-bookmarks/safety",headers:{authorization:"Bearer valid-token"}});await app.close();assert.equal(put.statusCode,204);assert.equal(del.statusCode,204);const insert=calls.find(call=>call.sql.includes("INSERT INTO article_bookmarks"))!,remove=calls.find(call=>call.sql.includes("DELETE FROM article_bookmarks"))!;assert.match(insert.sql,/ON CONFLICT DO NOTHING/);assert.deepEqual(insert.values,["user-1","safety"]);assert.deepEqual(remove.values,["user-1","safety"])});
