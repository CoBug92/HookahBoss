import assert from "node:assert/strict";
import test from "node:test";
import { generateKeyPair,exportPKCS8 } from "jose";
import { AESGCMProviderTokenCipher,ProductionAppleProviderLifecycle } from "../src/appleProvider.js";
import { loadConfig } from "../src/config.js";

test("provider credential encryption is authenticated and versioned",()=>{
  const cipher=new AESGCMProviderTokenCipher("v1",Buffer.alloc(32,7));
  const envelope=cipher.encrypt("provider-refresh-secret");
  assert.notEqual(envelope,"provider-refresh-secret");
  assert.equal(cipher.decrypt(envelope,"v1"),"provider-refresh-secret");
  const parts=envelope.split(".");
  const tamperedTag=Buffer.from(parts[1]!,"base64url");
  tamperedTag[0]^=0x01;
  parts[1]=tamperedTag.toString("base64url");
  const tamperedEnvelope=parts.join(".");
  assert.notEqual(tamperedEnvelope,envelope);
  assert.throws(()=>cipher.decrypt(tamperedEnvelope,"v1"));
  assert.throws(()=>cipher.decrypt(envelope,"v2"));
});

test("provider key rotation decrypts old envelopes and rejects malformed envelopes",()=>{
  const oldKey=Buffer.alloc(32,1),newKey=Buffer.alloc(32,2);
  const oldCipher=new AESGCMProviderTokenCipher("v1",new Map([["v1",oldKey]]));
  const oldEnvelope=oldCipher.encrypt("old-refresh");
  const rotated=new AESGCMProviderTokenCipher("v2",new Map([["v1",oldKey],["v2",newKey]]));
  assert.equal(rotated.decrypt(oldEnvelope,"v1"),"old-refresh");
  assert.notEqual(rotated.encrypt("new-refresh"),oldEnvelope);
  for(const malformed of ["","one.two","one.two.three.four","...","eA.eA.eA"])assert.throws(()=>rotated.decrypt(malformed,"v2"));
});

test("Apple provider exchanges and revokes using signed client credentials without putting secrets in URLs",async()=>{
  const {privateKey}=await generateKeyPair("ES256",{extractable:true});
  const pem=await exportPKCS8(privateKey);
  const calls:{url:string;body:string}[]=[];
  const fetcher:typeof fetch=async(input,init)=>{calls.push({url:String(input),body:String(init?.body)});return calls.length===1?new Response(JSON.stringify({refresh_token:"provider-refresh"}),{status:200}):new Response(null,{status:200})};
  const provider=new ProductionAppleProviderLifecycle("client","team","kid",pem,fetcher);
  assert.equal(await provider.exchange("one-time-code"),"provider-refresh");
  await provider.revoke("provider-refresh");
  assert.equal(calls[0]!.url,"https://appleid.apple.com/auth/token");
  assert.match(calls[0]!.body,/code=one-time-code/);
  assert.equal(calls[1]!.url,"https://appleid.apple.com/auth/revoke");
  assert.match(calls[1]!.body,/token=provider-refresh/);
  assert.ok(!calls.some(call=>call.url.includes("provider-refresh")||call.url.includes("one-time-code")));
});

test("production fails closed when Apple provider key material is incomplete",()=>{
  const base={NODE_ENV:"production",DATABASE_URL:"postgres://db",APPLE_CLIENT_ID:"client",SESSION_TOKEN_SECRET:"x".repeat(32)};
  assert.throws(()=>loadConfig(base),/provider exchange/);
  const provider={...base,APPLE_PROVIDER_CLIENT_ID:"client",APPLE_TEAM_ID:"team",APPLE_KEY_ID:"kid",APPLE_PRIVATE_KEY:"pem",APPLE_TOKEN_KEY_VERSION:"v1"};
  assert.throws(()=>loadConfig({...provider,APPLE_TOKEN_ENCRYPTION_KEYS:`v1:${Buffer.alloc(31).toString("base64")}`}),/32 bytes/);
  assert.throws(()=>loadConfig({...provider,APPLE_TOKEN_ENCRYPTION_KEYS:`v2:${Buffer.alloc(32).toString("base64")}`}),/Active Apple/);
  assert.throws(()=>loadConfig({...provider,APPLE_PROVIDER_CLIENT_ID:"different",APPLE_TOKEN_ENCRYPTION_KEYS:`v1:${Buffer.alloc(32).toString("base64")}`}),/included in APPLE_CLIENT_IDS/);
  const valid=loadConfig({...provider,APPLE_TOKEN_ENCRYPTION_KEYS:`v1:${Buffer.alloc(32,1).toString("base64")},v0:${Buffer.alloc(32,2).toString("base64")}`});
  assert.equal(valid.appleProvider?.clientId,"client");assert.equal(valid.appleProvider?.encryptionKeys.size,2);
});
