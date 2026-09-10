import assert from "node:assert/strict";
import test from "node:test";
import { exportJWK, generateKeyPair, SignJWT } from "jose";
import { buildApp } from "../src/app.js";
import { InvalidAppleTokenError, ProductionAppleTokenVerifier, SessionTokenService } from "../src/auth.js";
import { loadConfig } from "../src/config.js";

async function fixture() {
  const { privateKey, publicKey } = await generateKeyPair("RS256");
  const jwk = await exportJWK(publicKey); Object.assign(jwk, { kid: "key-1", alg: "RS256", use: "sig" });
  const sign = (claims: Record<string, unknown> = {}, kid = "key-1") => new SignJWT({ email: "hidden@example.com" })
    .setProtectedHeader({ alg: "RS256", kid }).setSubject("apple-subject").setIssuer("https://appleid.apple.com")
    .setAudience("ru.kostyuchenko.mixery").setIssuedAt().setExpirationTime("5m").setIssuer(String(claims.iss ?? "https://appleid.apple.com"))
    .setAudience(String(claims.aud ?? "ru.kostyuchenko.mixery")).setIssuedAt(Number(claims.iat ?? Math.floor(Date.now()/1000)))
    .setExpirationTime(Number(claims.exp ?? Math.floor(Date.now()/1000)+300)).sign(privateKey);
  return { jwks: { keys: [jwk] }, sign };
}

test("production Apple verifier validates signature and required claims", async () => {
  const f = await fixture(); const verifier = new ProductionAppleTokenVerifier(["ru.kostyuchenko.mixery"], async () => f.jwks);
  assert.deepEqual(await verifier.verify(await f.sign()), { subject: "apple-subject", email: "hidden@example.com" });
});

test("production Apple verifier rejects issuer, audience, expiry, future iat and malformed token", async () => {
  const f = await fixture(); const verifier = new ProductionAppleTokenVerifier(["ru.kostyuchenko.mixery"], async () => f.jwks);
  const tokens = [await f.sign({ iss: "bad" }), await f.sign({ aud: "bad" }), await f.sign({ exp: 1 }), await f.sign({ iat: Math.floor(Date.now()/1000)+60 }), "not.jwt"];
  for (const token of tokens) await assert.rejects(verifier.verify(token), InvalidAppleTokenError);
});

test("Apple JWKS is cached and refreshed once for an unknown kid", async () => {
  const f = await fixture(); let calls = 0;
  const verifier = new ProductionAppleTokenVerifier(["ru.kostyuchenko.mixery"], async () => { calls++; return f.jwks; });
  await verifier.verify(await f.sign()); await verifier.verify(await f.sign()); assert.equal(calls, 1);
  await assert.rejects(verifier.verify(await f.sign({}, "unknown")), InvalidAppleTokenError); assert.equal(calls, 2);
});

test("config denies startup without Apple clients or a strong session secret", () => {
  assert.throws(() => loadConfig({ DATABASE_URL: "postgres://db", SESSION_TOKEN_SECRET: "x".repeat(32) }), /APPLE_CLIENT/);
  assert.throws(() => loadConfig({ DATABASE_URL: "postgres://db", APPLE_CLIENT_ID: "app", SESSION_TOKEN_SECRET: "short" }), /SESSION_TOKEN_SECRET/);
  assert.throws(()=>loadConfig({DATABASE_URL:"postgres://db",APPLE_CLIENT_ID:"app",SESSION_TOKEN_SECRET:"local-development-only-change-me-32-bytes",NODE_ENV:"production"}),/Development SESSION_TOKEN_SECRET/);
});

test("Apple exchange returns an API session and rejects malformed identity tokens", async () => {
  const sessions = new SessionTokenService("s".repeat(32));
  const apple = { verify: async (token: string) => { if (token !== "apple") throw new InvalidAppleTokenError(); return { subject: "sub" }; } };
  const database = { query: async (sql: unknown) => String(sql).includes("auth_sessions") ? ({ rows: [{ id: "session-id" }], rowCount: 1 }) as never : ({ rows: [{ id: "user-id", apple_subject: "sub", auth_session_version: 1 }], rowCount: 1 }) as never };
  const app = buildApp(database, false, sessions, undefined, apple, sessions);
  const ok = await app.inject({ method: "POST", url: "/v1/auth/apple", payload: { identityToken: "apple", authorizationCode: "device-code" } });
  const bad = await app.inject({ method: "POST", url: "/v1/auth/apple", payload: { identityToken: "bad" } });
  assert.equal(ok.statusCode, 200); assert.equal(typeof ok.json().data.accessToken, "string"); assert.equal(ok.json().data.expiresIn, 900);assert.equal(ok.json().data.accountId,"user-id");
  assert.equal(bad.statusCode, 401); await app.close();
});

test("refresh rotates the opaque token and persists only hashes", async () => {
  const sessions = new SessionTokenService("s".repeat(32)); const calls:Array<{sql:string;values?:readonly unknown[]}>=[];
  const client={query:async(sql:string,values?:readonly unknown[])=>{calls.push({sql,values});if(sql.includes("SELECT s.id"))return {rows:[{id:"old",family_id:"family",user_id:"user",apple_subject:"sub",auth_session_version:1,revoked_at:null,expired:false}]};if(sql.includes("INSERT INTO auth_sessions"))return {rows:[{id:"new"}]};return {rows:[],rowCount:1}},release(){}};
  const database={query:async()=>({rows:[]}) as never,connect:async()=>client as never};const app=buildApp(database,false,sessions,undefined,undefined,sessions);
  const response=await app.inject({method:"POST",url:"/v1/auth/refresh",payload:{refreshToken:"raw-old-token"}});await app.close();
  assert.equal(response.statusCode,200);assert.notEqual(response.json().data.refreshToken,"raw-old-token");
  assert.equal(calls.some(call=>call.values?.includes("raw-old-token")),false);assert(calls.some(call=>call.sql.includes("replaced_by")));
});

test("refresh reuse revokes the complete token family", async () => {
  const sessions=new SessionTokenService("s".repeat(32));const calls:string[]=[];
  const client={query:async(sql:string)=>{calls.push(sql);if(sql.includes("SELECT s.id"))return {rows:[{id:"old",family_id:"family",user_id:"user",apple_subject:"sub",auth_session_version:1,revoked_at:"now",expired:false}]};return {rows:[]}},release(){}};
  const app=buildApp({query:async()=>({rows:[]}) as never,connect:async()=>client as never},false,sessions,undefined,undefined,sessions);
  const response=await app.inject({method:"POST",url:"/v1/auth/refresh",payload:{refreshToken:"reused"}});await app.close();
  assert.equal(response.statusCode,401);assert.equal(response.json().error,"refresh_token_reused");assert(calls.some(sql=>sql.includes("WHERE family_id")));
});

test("expired refresh token is rejected without rotation", async () => {
  const sessions=new SessionTokenService("s".repeat(32));let inserts=0;
  const client={query:async(sql:string)=>{if(sql.includes("SELECT s.id"))return {rows:[{id:"old",expired:true,revoked_at:null}]};if(sql.includes("INSERT"))inserts++;return {rows:[]}},release(){}};
  const app=buildApp({query:async()=>({rows:[]}) as never,connect:async()=>client as never},false,sessions,undefined,undefined,sessions);
  const response=await app.inject({method:"POST",url:"/v1/auth/refresh",payload:{refreshToken:"expired"}});await app.close();assert.equal(response.statusCode,401);assert.equal(inserts,0);
});

test("account deletion is owner-scoped and transactional", async () => {
  const calls:Array<{sql:string;values?:readonly unknown[]}>=[];
  const client={query:async(sql:string,values?:readonly unknown[])=>{calls.push({sql,values});return {rows:[],rowCount:sql.startsWith("DELETE")?1:0}},release(){}};
  const database={query:async(sql:string)=>sql.includes("INSERT INTO app_users")?({rows:[{id:"owner",apple_subject:"sub"}]}) as never:({rows:[]}) as never,connect:async()=>client as never};
  const verifier={verify:async()=>({subject:"sub"})};const app=buildApp(database,false,verifier);
  const response=await app.inject({method:"DELETE",url:"/v1/me/account",headers:{authorization:"Bearer valid"}});await app.close();
  assert.equal(response.statusCode,200);assert.equal(response.json().data.providerRevocation,"unavailable");assert.deepEqual(calls.map(c=>c.sql),["BEGIN","DELETE FROM app_users WHERE id=$1","COMMIT"]);assert.deepEqual(calls[1]!.values,["owner"]);
});

test("new Apple account fails when authorization-code exchange fails, while an existing provider credential preserves login",async()=>{
  const sessions=new SessionTokenService("s".repeat(32));const apple={verify:async()=>({subject:"sub"})};let stored=false,inserts=0;
  const database={query:async(sql:string)=>{if(sql.startsWith("SELECT apple_refresh"))return {rows:[{has_token:stored}]};if(sql.includes("INSERT INTO app_users")){inserts++;return {rows:[{id:"user",apple_subject:"sub",auth_session_version:1}]};}if(sql.includes("INSERT INTO auth_sessions"))return {rows:[{id:"session"}]};return {rows:[]}}};
  const provider={exchange:async()=>{throw new Error("invalid code")},revoke:async()=>{}};const cipher={keyVersion:"v1",encrypt:(v:string)=>v,decrypt:(v:string)=>v};
  const app=buildApp(database as never,false,sessions,undefined,apple,sessions,provider,cipher);
  const first=await app.inject({method:"POST",url:"/v1/auth/apple",payload:{identityToken:"id",authorizationCode:"used"}});assert.equal(first.statusCode,401);assert.equal(inserts,0);
  stored=true;const repeat=await app.inject({method:"POST",url:"/v1/auth/apple",payload:{identityToken:"id",authorizationCode:"used"}});assert.equal(repeat.statusCode,200);assert.equal(inserts,1);await app.close();
});

test("provider revocation failure leaves account data intact for retry",async()=>{
  const sessions=new SessionTokenService("s".repeat(32));let deletes=0;
  const database={query:async(sql:string)=>sql.startsWith("SELECT apple_refresh")?{rows:[{apple_refresh_token_encrypted:"cipher",apple_refresh_token_key_version:"v1"}]}:{rows:[{id:"owner",apple_subject:"sub"}]},connect:async()=>({query:async(sql:string)=>{if(sql.startsWith("DELETE"))deletes++;return {rows:[],rowCount:1}},release(){}})};
  const provider={exchange:async()=>"",revoke:async()=>{throw new Error("offline")}};const cipher={keyVersion:"v1",encrypt:(v:string)=>v,decrypt:()=>"raw"};
  const app=buildApp(database as never,false,{verify:async()=>({subject:"sub"})},undefined,undefined,undefined,provider,cipher);
  const response=await app.inject({method:"DELETE",url:"/v1/me/account",headers:{authorization:"Bearer valid"}});assert.equal(response.statusCode,503);assert.equal(deletes,0);await app.close();
});

test("account deletion rolls back on database failure", async () => {
  const calls:string[]=[];const client={query:async(sql:string)=>{calls.push(sql);if(sql.startsWith("DELETE"))throw new Error("db failure");return {rows:[]}},release(){}};
  const database={query:async()=>({rows:[{id:"owner",apple_subject:"sub"}]}) as never,connect:async()=>client as never};const app=buildApp(database,false,{verify:async()=>({subject:"sub"})});
  const response=await app.inject({method:"DELETE",url:"/v1/me/account",headers:{authorization:"Bearer valid"}});await app.close();assert.equal(response.statusCode,500);assert.deepEqual(calls,["BEGIN","DELETE FROM app_users WHERE id=$1","ROLLBACK"]);
});
