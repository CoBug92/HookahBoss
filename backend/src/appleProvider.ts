import { createCipheriv, createDecipheriv, randomBytes } from "node:crypto";
import { importPKCS8, SignJWT } from "jose";

export interface AppleProviderLifecycle {
  exchange(code: string): Promise<string>;
  revoke(refreshToken: string): Promise<void>;
}

export interface ProviderTokenCipher {
  readonly keyVersion: string;
  encrypt(value: string): string;
  decrypt(envelope: string, keyVersion: string): string;
}

export class AESGCMProviderTokenCipher implements ProviderTokenCipher {
  private readonly keys:ReadonlyMap<string,Buffer>;
  constructor(readonly keyVersion:string,keys:Buffer|ReadonlyMap<string,Buffer>){this.keys=Buffer.isBuffer(keys)?new Map([[keyVersion,keys]]):keys;if(!this.keys.has(keyVersion))throw new Error("Active Apple token encryption key is missing");for(const key of this.keys.values())if(key.length!==32)throw new Error("Apple token encryption keys must decode to 32 bytes")}
  encrypt(value:string):string{const key=this.keys.get(this.keyVersion)!;const iv=randomBytes(12),cipher=createCipheriv("aes-256-gcm",key,iv);const encrypted=Buffer.concat([cipher.update(value,"utf8"),cipher.final()]);return [iv,cipher.getAuthTag(),encrypted].map(v=>v.toString("base64url")).join(".")}
  decrypt(envelope:string,keyVersion:string):string{const key=this.keys.get(keyVersion);if(!key)throw new Error("Unknown Apple token encryption key version");const parts=envelope.split(".");if(parts.length!==3||parts.some(v=>!v))throw new Error("Invalid Apple token envelope");let iv:Buffer,tag:Buffer,data:Buffer;try{[iv,tag,data]=parts.map(v=>Buffer.from(v,"base64url")) as [Buffer,Buffer,Buffer]}catch{throw new Error("Invalid Apple token envelope")}if(iv.length!==12||tag.length!==16||data.length===0)throw new Error("Invalid Apple token envelope");const decipher=createDecipheriv("aes-256-gcm",key,iv);decipher.setAuthTag(tag);return Buffer.concat([decipher.update(data),decipher.final()]).toString("utf8")}
}

export class ProductionAppleProviderLifecycle implements AppleProviderLifecycle {
  constructor(private readonly clientId:string,private readonly teamId:string,private readonly keyId:string,private readonly privateKey:string,private readonly fetcher:typeof fetch=fetch){}
  private async clientSecret(){const key=await importPKCS8(this.privateKey.replace(/\\n/g,"\n"),"ES256");return new SignJWT({}).setProtectedHeader({alg:"ES256",kid:this.keyId}).setIssuer(this.teamId).setSubject(this.clientId).setAudience("https://appleid.apple.com").setIssuedAt().setExpirationTime("5m").sign(key)}
  async exchange(code:string):Promise<string>{const body=new URLSearchParams({client_id:this.clientId,client_secret:await this.clientSecret(),code,grant_type:"authorization_code"});const response=await this.fetcher("https://appleid.apple.com/auth/token",{method:"POST",headers:{"content-type":"application/x-www-form-urlencoded"},body});if(!response.ok)throw new Error("Apple authorization code exchange failed");const json=await response.json() as {refresh_token?:unknown};if(typeof json.refresh_token!=="string"||!json.refresh_token)throw new Error("Apple refresh token missing");return json.refresh_token}
  async revoke(token:string):Promise<void>{const body=new URLSearchParams({client_id:this.clientId,client_secret:await this.clientSecret(),token,token_type_hint:"refresh_token"});const response=await this.fetcher("https://appleid.apple.com/auth/revoke",{method:"POST",headers:{"content-type":"application/x-www-form-urlencoded"},body});if(!response.ok)throw new Error("Apple token revocation failed")}
}
