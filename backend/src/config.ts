export type Config = {
  databaseUrl: string;
  host: string;
  port: number;
  logLevel: string;
  adminAppleSubjects: string[];
  appleClientIds: string[];
  sessionTokenSecret: string;
  appleProvider?: { clientId:string;teamId:string;keyId:string;privateKey:string;encryptionKeys:Map<string,Buffer>;keyVersion:string };
};

export function loadConfig(env: NodeJS.ProcessEnv = process.env): Config {
  const databaseUrl = env.DATABASE_URL;
  if (!databaseUrl) throw new Error("DATABASE_URL is required");

  const port = Number(env.PORT ?? 3000);
  if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error("PORT must be a valid TCP port");

  const appleClientIds = (env.APPLE_CLIENT_IDS ?? env.APPLE_CLIENT_ID ?? "").split(",").map(value => value.trim()).filter(Boolean);
  if (appleClientIds.length === 0) throw new Error("APPLE_CLIENT_ID or APPLE_CLIENT_IDS is required");
  const sessionTokenSecret = env.SESSION_TOKEN_SECRET ?? "";
  if (Buffer.byteLength(sessionTokenSecret) < 32) throw new Error("SESSION_TOKEN_SECRET must be at least 32 bytes");
  if(env.NODE_ENV==="production" && sessionTokenSecret==="local-development-only-change-me-32-bytes")throw new Error("Development SESSION_TOKEN_SECRET is forbidden in production");
  const providerMode=env.APPLE_PROVIDER_MODE??(env.NODE_ENV==="production"?"enabled":"disabled");if(!["enabled","disabled"].includes(providerMode))throw new Error("APPLE_PROVIDER_MODE must be enabled or disabled");if(env.NODE_ENV==="production"&&providerMode!=="enabled")throw new Error("APPLE_PROVIDER_MODE must be enabled in production");
  const providerValues=[env.APPLE_PROVIDER_CLIENT_ID,env.APPLE_TEAM_ID,env.APPLE_KEY_ID,env.APPLE_PRIVATE_KEY,env.APPLE_TOKEN_KEY_VERSION];
  if(providerMode==="enabled"&&providerValues.some(v=>!v))throw new Error("Apple provider exchange and encryption credentials are required when enabled");
  const keyEntries=(env.APPLE_TOKEN_ENCRYPTION_KEYS??"").split(",").filter(Boolean).map(entry=>{const separator=entry.indexOf(":");if(separator<1)throw new Error("APPLE_TOKEN_ENCRYPTION_KEYS must use version:base64 entries");return [entry.slice(0,separator),Buffer.from(entry.slice(separator+1),"base64")] as const});
  if(providerMode==="enabled"&&keyEntries.length===0)throw new Error("APPLE_TOKEN_ENCRYPTION_KEYS is required when Apple provider lifecycle is enabled");
  if(providerMode==="disabled"&&(providerValues.some(Boolean)||keyEntries.length))throw new Error("Apple provider credentials require APPLE_PROVIDER_MODE=enabled");
  if(keyEntries.some(([,key])=>key.length!==32))throw new Error("Apple token encryption keys must decode to 32 bytes");
  const encryptionKeys=new Map(keyEntries);if(encryptionKeys.size!==keyEntries.length)throw new Error("Apple token encryption key versions must be unique");
  if(env.APPLE_TOKEN_KEY_VERSION&&!encryptionKeys.has(env.APPLE_TOKEN_KEY_VERSION))throw new Error("Active Apple token encryption key is missing");
  if(env.APPLE_PROVIDER_CLIENT_ID&&!appleClientIds.includes(env.APPLE_PROVIDER_CLIENT_ID))throw new Error("APPLE_PROVIDER_CLIENT_ID must be included in APPLE_CLIENT_IDS");
  const appleProvider=providerMode==="enabled"?{clientId:env.APPLE_PROVIDER_CLIENT_ID!,teamId:env.APPLE_TEAM_ID!,keyId:env.APPLE_KEY_ID!,privateKey:env.APPLE_PRIVATE_KEY!,encryptionKeys,keyVersion:env.APPLE_TOKEN_KEY_VERSION!}:undefined;
  return {
    databaseUrl,
    host: env.HOST ?? "0.0.0.0",
    port,
    logLevel: env.LOG_LEVEL ?? "info"
    ,adminAppleSubjects: (env.ADMIN_APPLE_SUBJECTS ?? "").split(",").map(value => value.trim()).filter(Boolean), appleClientIds, sessionTokenSecret,appleProvider
  };
}
