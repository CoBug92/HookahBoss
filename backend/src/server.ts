import { buildApp } from "./app.js";
import { loadConfig } from "./config.js";
import { createPool } from "./db/pool.js";
import { AppleSubjectAllowlist, ProductionAppleTokenVerifier, SessionTokenService } from "./auth.js";
import { AESGCMProviderTokenCipher,ProductionAppleProviderLifecycle } from "./appleProvider.js";

const config = loadConfig();
const pool = createPool(config.databaseUrl);
const sessions = new SessionTokenService(config.sessionTokenSecret);
const provider=config.appleProvider ? new ProductionAppleProviderLifecycle(config.appleProvider.clientId,config.appleProvider.teamId,config.appleProvider.keyId,config.appleProvider.privateKey):undefined;
const cipher=config.appleProvider ? new AESGCMProviderTokenCipher(config.appleProvider.keyVersion,config.appleProvider.encryptionKeys):undefined;
const app = buildApp(pool, { level: config.logLevel }, sessions, new AppleSubjectAllowlist(config.adminAppleSubjects), new ProductionAppleTokenVerifier(config.appleClientIds), sessions,provider,cipher);

const close = async (signal: string) => {
  app.log.info({ signal }, "shutting down");
  await app.close();
  await pool.end();
  process.exit(0);
};

process.on("SIGINT", () => void close("SIGINT"));
process.on("SIGTERM", () => void close("SIGTERM"));

await app.listen({ host: config.host, port: config.port });
