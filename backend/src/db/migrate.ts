import { readdir, readFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { loadConfig } from "../config.js";
import { createPool } from "./pool.js";

export async function migrate(databaseUrl: string, migrationsDirectory = resolve(dirname(fileURLToPath(import.meta.url)), "../../../migrations")): Promise<void> {
  const pool = createPool(databaseUrl);
  const client = await pool.connect();
  try {
    await client.query("CREATE TABLE IF NOT EXISTS schema_migrations (version text PRIMARY KEY, applied_at timestamptz NOT NULL DEFAULT now())");
    const applied = new Set((await client.query<{ version: string }>("SELECT version FROM schema_migrations")).rows.map(row => row.version));
    const files = (await readdir(migrationsDirectory)).filter(file => file.endsWith(".sql")).sort();

    for (const file of files) {
      if (applied.has(file)) continue;
      const sql = await readFile(resolve(migrationsDirectory, file), "utf8");
      await client.query("BEGIN");
      try {
        await client.query(sql);
        await client.query("INSERT INTO schema_migrations(version) VALUES ($1)", [file]);
        await client.query("COMMIT");
      } catch (error) {
        await client.query("ROLLBACK");
        throw error;
      }
    }
  } finally {
    client.release();
    await pool.end();
  }
}

if (process.argv[1] && import.meta.url === new URL(`file://${process.argv[1]}`).href) {
  await migrate(loadConfig().databaseUrl);
}
