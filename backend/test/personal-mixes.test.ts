import assert from "node:assert/strict";
import test from "node:test";
import { buildApp } from "../src/app.js";
import type { AppleTokenVerifier } from "../src/auth.js";

const headers = { authorization: "Bearer valid-token" };
const verifier: AppleTokenVerifier = { async verify() { return { subject: "apple-user-1" }; } };

function authenticatedQuery(sql: string) {
  if (sql.includes("INSERT INTO app_users")) return { rows: [{ id: "user-1", apple_subject: "apple-user-1" }] };
  return { rows: [] };
}

test("personal mix routes require authorization", async () => {
  const app = buildApp({ query: async () => { throw new Error("unexpected query"); } } as never);
  const response = await app.inject({ method: "GET", url: "/v1/me/personal-mixes" });
  await app.close();
  assert.equal(response.statusCode, 401);
});

test("personal mix validates component count, sources and percentages", async () => {
  const database = { query: async (sql: string) => authenticatedQuery(sql) as never };
  const app = buildApp(database as never, false, verifier);

  const none = await app.inject({ method: "POST", url: "/v1/me/personal-mixes", headers, payload: { components: [] } });
  const twoSources = await app.inject({
    method: "POST", url: "/v1/me/personal-mixes", headers,
    payload: { components: [{ productId: "a", freeformName: "Lemon" }] }
  });
  const partial = await app.inject({
    method: "POST", url: "/v1/me/personal-mixes", headers,
    payload: { components: [{ freeformName: "Lemon", percentage: 50 }, { freeformName: "Mint" }] }
  });
  const wrongTotal = await app.inject({
    method: "POST", url: "/v1/me/personal-mixes", headers,
    payload: { components: [{ freeformName: "Lemon", percentage: 60 }, { freeformName: "Mint", percentage: 30 }] }
  });
  await app.close();

  assert.deepEqual([none.statusCode, twoSources.statusCode, partial.statusCode, wrongTotal.statusCode], [400, 400, 400, 400]);
  assert.equal(partial.json().error, "partial_percentages_not_allowed");
  assert.equal(wrongTotal.json().error, "percentages_must_total_100");
});

test("create writes the mix and stable component positions in one transaction", async () => {
  const transactionCalls: Array<{ sql: string; values?: readonly unknown[] }> = [];
  const client = {
    query: async (sql: string, values?: readonly unknown[]) => {
      transactionCalls.push({ sql, values });
      if (sql.includes("INSERT INTO personal_mixes")) return { rows: [{ id: "personal-1" }] };
      if (sql.includes("INSERT INTO personal_mix_components")) return { rows: [{ id: "component" }] };
      if (sql.includes("FROM personal_mixes m") && sql.includes("GROUP BY m.id")) return { rows: [{id:"personal-1",title:"Evening",score:5,comment:"Good",isApproximate:false,components:[{id:"component-1",freeformName:"Lemon",percentage:40,position:1},{id:"component-2",freeformName:"Mint",percentage:60,position:2}]}] };
      return { rows: [] };
    },
    release() {}
  };
  const database = {
    query: async (sql: string) => authenticatedQuery(sql) as never,
    connect: async () => client
  };
  const app = buildApp(database as never, false, verifier);
  const response = await app.inject({
    method: "POST", url: "/v1/me/personal-mixes", headers,
    payload: {
      title: "Evening", score: 5, comment: "Good",
      components: [{ freeformName: "Lemon", percentage: 40 }, { freeformName: "Mint", percentage: 60 }]
    }
  });
  await app.close();

  assert.equal(response.statusCode, 201);
  assert.equal(response.json().data.components[0].position, 1);
  assert.equal(response.json().data.components[1].position, 2);
  assert.equal(transactionCalls[0]?.sql, "BEGIN");
  assert.equal(transactionCalls.at(-1)?.sql, "COMMIT");
  const componentCalls = transactionCalls.filter(call => call.sql.includes("INSERT INTO personal_mix_components"));
  assert.match(transactionCalls.find(call => call.sql.includes("INSERT INTO personal_mixes"))?.sql ?? "", /ON CONFLICT\(id\)/);
  assert.equal(componentCalls[0]?.values?.[3], 1);
  assert.equal(componentCalls[1]?.values?.[3], 2);
});

test("idempotent repeated create returns the hydrated persisted mix, not the repeated request",async()=>{
  const persisted={id:"00000000-0000-4000-8000-000000000007",title:"Persisted",score:null,comment:null,isApproximate:true,createdAt:"then",updatedAt:"then",components:[{id:"component-1",productId:"product-1",privateProductId:null,freeformName:null,percentage:100,position:1,brandName:"Brand",lineName:"Line",flavorName:"Iceberg",flavorProfiles:["fresh"]}]};
  const client={query:async(sql:string)=>{if(sql.includes("INSERT INTO personal_mixes"))return{rows:[{id:persisted.id,inserted:false}]};if(sql.includes("FROM personal_mixes m"))return{rows:[persisted]};return{rows:[]}},release(){}};
  const database={query:async(sql:string)=>authenticatedQuery(sql) as never,connect:async()=>client};const app=buildApp(database as never,false,verifier);
  const response=await app.inject({method:"POST",url:"/v1/me/personal-mixes",headers,payload:{clientId:persisted.id,title:"Retried stale request",components:[{freeformName:"Wrong",percentage:100}]}});await app.close();
  assert.equal(response.statusCode,201);assert.deepEqual(response.json().data,persisted);
});

test("update cannot modify a mix owned by another user", async () => {
  const transactionCalls: string[] = [];
  const client = {
    query: async (sql: string) => {
      transactionCalls.push(sql);
      return { rows: [] };
    },
    release() {}
  };
  const database = { query: async (sql: string) => authenticatedQuery(sql) as never, connect: async () => client };
  const app = buildApp(database as never, false, verifier);
  const response = await app.inject({
    method: "PUT", url: "/v1/me/personal-mixes/someone-elses-mix", headers,
    payload: { components: [{ freeformName: "Mint" }] }
  });
  await app.close();

  assert.equal(response.statusCode, 404);
  assert.match(transactionCalls[1] ?? "", /WHERE id = \$1 AND user_id = \$2/);
  assert.equal(transactionCalls[2], "ROLLBACK");
});

test("private component ownership failure rolls back the transaction", async () => {
  const transactionCalls: string[] = [];
  const client = {
    query: async (sql: string) => {
      transactionCalls.push(sql);
      if (sql.includes("INSERT INTO personal_mixes")) return { rows: [{ id: "personal-1" }] };
      return { rows: [] };
    },
    release() {}
  };
  const database = { query: async (sql: string) => authenticatedQuery(sql) as never, connect: async () => client };
  const app = buildApp(database as never, false, verifier);
  const response = await app.inject({
    method: "POST", url: "/v1/me/personal-mixes", headers,
    payload: { components: [{ privateProductId: "private-product-of-someone-else" }] }
  });
  await app.close();

  assert.equal(response.statusCode, 400);
  assert.equal(response.json().error, "component_source_not_found");
  assert.match(transactionCalls[2] ?? "", /AND user_id = \$5/);
  assert.equal(transactionCalls.at(-1), "ROLLBACK");
});

test("list, detail and delete queries are owner-scoped", async () => {
  const calls: Array<{ sql: string; values?: readonly unknown[] }> = [];
  const database = {
    query: async (sql: string, values?: readonly unknown[]) => {
      calls.push({ sql, values });
      if (sql.includes("INSERT INTO app_users")) return authenticatedQuery(sql) as never;
      if (sql.includes("GROUP BY m.id") && sql.includes("m.id = $1")) return { rows: [{ id: "personal-1", components: [] }] } as never;
      if (sql.includes("DELETE FROM personal_mixes")) return { rows: [{ id: "personal-1" }] } as never;
      return { rows: [] } as never;
    }
  };
  const app = buildApp(database as never, false, verifier);
  assert.equal((await app.inject({ method: "GET", url: "/v1/me/personal-mixes", headers })).statusCode, 200);
  assert.equal((await app.inject({ method: "GET", url: "/v1/me/personal-mixes/personal-1", headers })).statusCode, 200);
  assert.equal((await app.inject({ method: "DELETE", url: "/v1/me/personal-mixes/personal-1", headers })).statusCode, 204);
  await app.close();

  const personalCalls = calls.filter(call => !call.sql.includes("INSERT INTO app_users"));
  assert.match(personalCalls[0]?.sql ?? "", /WHERE m.user_id = \$1/);
  assert.match(personalCalls[1]?.sql ?? "", /m.id = \$1 AND m.user_id = \$2/);
  assert.match(personalCalls[2]?.sql ?? "", /id = \$1 AND user_id = \$2/);
});
