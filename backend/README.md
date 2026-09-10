# HookahBoss API

Backend for the native iOS application. It exposes public catalog/content APIs, authenticated personal APIs, and a protected Admin API (no visual admin UI).

## Local development

```sh
cp .env.example .env
npm install
npm run migrate
npm run seed:validate
npm run seed:catalog
npm run dev
```

`seed:catalog` imports the RF/CIS catalog transactionally and can be run repeatedly: sources, brands, lines, flavor tags, products and tag links are upserted by stable natural keys. The combined catalog currently contains 383 products across 13 brands. Provenance, verification/access dates, confidence and translation origin live beside each seed. `seed:validate` checks the combined dataset, including duplicates across versions. The importer never stores prices or purchase links.

BlackBurn is maintained from its official complete taste catalog. `npm run catalog:refresh:blackburn` discovers the Tilda `recid` and `storepartuid` from `https://www.blckburn.com/taste`, follows official API pagination, validates and atomically regenerates `seeds/blackburn-generated.ts`. It persists only canonical title, official Russian description/summary, official family mapping, inferred flavor metadata and provenance; commerce, media and availability fields are discarded. Use `--dry-run` for a diff without writing and `--check` in CI to fail on drift. Import archives, but never deletes, former BlackBurn records missing from the authoritative snapshot. The `cooling` / `Охлаждение` tag is distinct from mint and uses the `fresh` profile.

DARKSIDE is maintained from its official full catalog. `npm run catalog:refresh:darkside` opens `https://darkside-world.com/products/brand/darkside`, discovers the API base, public client token and DARKSIDE brand id from the official Nuxt runtime, follows every declared `/ext_api/v1/flavors` page, validates the declared total and atomically regenerates `seeds/darkside-generated.ts`. The snapshot contains 75 canonical titles, official Russian descriptions, official tags/categories and strength only; names stay canonical in both locale fields because the source provides no official English translation. Prices, availability, packaging, likes, bookmarks and every media field are excluded. `--dry-run` prints a diff without writing and `--check` fails on drift. Import merges the former subsets into one line, retains the separately sourced `lime-up` record required by an existing published recipe, and archives—but never deletes—other missing source-owned DARKSIDE products.

MUSTHAVE is maintained from the official server-rendered tobacco category. `npm run catalog:refresh:musthave` discovers the declared pagination at `https://musthave.ru/category/tabak-dlya-kalyana/`, follows all category pages, accepts only canonical MUSTHAVE tobacco product cards, validates uniqueness/classification and atomically regenerates `seeds/musthave-generated.ts`. The current snapshot contains 99 products. It preserves the official product title and Russian flavor note; the canonical title is reused for English where no official English translation exists. Prices, availability, packaging and media are never persisted. `--dry-run` prints a diff without writing and `--check` fails on drift. Import merges previous MUSTHAVE subsets, preserves stable slugs referenced by published recipes, and archives—but never deletes—missing records owned by the official MUSTHAVE catalog source.

The latest full post-refresh provenance run is `reports/provenance-sources-live-2026-09-10-darkside.json`: 64/64 URLs valid, with 34 MUSTHAVE recipe pages semantically verified and 30 sources explicitly classified as reachability-only; the verifier exited zero and did not mutate seed verification dates.

Inventory matching can be verified against a migrated, seeded PostgreSQL instance with `npm run integration:inventory-matching`. It creates unique fixtures inside one transaction, exercises ready/substitution/missing-one groups plus private exact-flavor and deny-rule behavior through the same SQL used by the API, and always rolls back in `finally`; it neither depends on nor retains an application user.

`GET /v1/products` and `GET /v1/mixes` remain exhaustive with the legacy `{data}` response when `pageSize` is omitted. New clients use cursor pagination with `pageSize=1...100` and the opaque `cursor` returned by the previous page; paged responses add `pagination.nextCursor` and `pagination.hasMore`. Invalid sizes or cursors return 400. Ordering is stable (`brand/line/product/id` and `publishedAt desc/title/id`). Consumers must finish every page before replacing a cached catalog snapshot.

The recipe batch in `seeds/mixes-v1.ts` contains 20 directly attributable recipes whose pages print a numeric percentage for every component (no ratios were converted or rounded): 5 MUSTHAVE editorial recipes and 15 user-authored recipes hosted by MUSTHAVE with explicit author attribution. Run `npm run seed:catalog` first (it also imports the separate confirmed MUSTHAVE support products), then `npm run seed:mixes:validate` and `npm run seed:mixes`. Recipe import replaces each mix composition inside one transaction and is idempotent by mix slug. Prices and purchase information from source pages are intentionally ignored.

`seeds/mixes-v2.ts` adds 12 DARKSIDE recipes with source-explicit numeric percentages: 10 recipes from official editorial/ambassador mixpacks and two individually published MIX BOT pages (one attributed user recipe and one DARKSIDE editorial recipe). The combined importer and validator process 32 recipes. Candidates expressed only as ratios and candidates requiring unverified products are rejected rather than rounded or substituted.

`seeds/mixes-v3.ts` adds 14 publicly attributed user recipes hosted on the official MUSTHAVE platform. Every component is printed with an explicit numeric percentage; ratios and inferred values remain forbidden. `seeds/catalog-mix-support-v3.ts` separately records official product provenance for the six newly required catalog positions. The combined validator/importer now processes 46 recipes (the approved MVP range is 40–60) transactionally and idempotently. Run `npm run seed:validate`, `npm run seed:catalog`, `npm run seed:mixes:validate`, and `npm run seed:mixes`; running both import commands again must preserve counts.

`seeds/articles-v1.ts` contains ten original bilingual editorial articles: two each for fundamentals, preparation, bowls/heat, care and safety. Bodies are structured into localized sections, include 2–3 related article slugs and retain all synthesis sources through `article_sources`. No personal author is stored. Run `npm run seed:articles:validate` and, after migrations, `npm run seed:articles`; repeated imports update articles, source links and related links transactionally. Safety content relies on WHO, CDC and NHS rather than industry marketing and does not claim that water, ventilation or equipment makes smoking safe.

From the `backend/` directory, `docker compose up --build` starts the development PostgreSQL and exposes the API at `http://127.0.0.1:3010` (`3010` on the host to `3000` in the container), matching the iOS Debug configuration. Compose fallback credentials are explicitly local-only; production must supply independent database credentials and a random session secret. Run migrations and all seeds before the first API start with:

```sh
docker compose run --rm api node dist/src/db/migrate.js
docker compose run --rm api node dist/src/db/importCatalogSeed.js
docker compose run --rm api node dist/src/db/importMixSeed.js
docker compose run --rm api node dist/src/db/importArticleSeed.js
```

The VDS device-test deployment and read-only status helpers are backend-owned and resolve repository paths from their own location, so they can be launched from any working directory:

```sh
./backend/deploy-device-test.sh
./backend/device-test-status.sh
```

## Provenance verification

Run `npm run sources:verify` to check every catalog, mix, and article source without changing seed `verifiedAt` values. The command deduplicates URLs, follows redirects, applies bounded concurrency/timeouts and transient-only retries, writes `reports/provenance-sources.json`, prints a human summary, and exits nonzero for unreachable, invalid, or semantically mismatched sources. MUSTHAVE recipe pages receive exact ID/component/percentage checks; other publishers are deliberately reported as `reachability_only` until a source-specific semantic verifier exists. The report is an audit artifact, not an automatic provenance-date update.

## Public endpoints

- `GET /health`
- `GET /v1/brands`
- `GET /v1/products?locale=ru&brandId=<uuid>`
- `GET /v1/mixes?locale=ru`
- `GET /v1/mixes/:id?locale=ru`
- `GET /v1/articles?locale=ru&category=fundamentals&page=1&pageSize=20`
- `GET /v1/articles/:id-or-slug?locale=ru`

`locale` accepts `ru` or `en`. Public catalog endpoints expose only published products whose brand and line are also published; archived content remains available only through the Admin API.

## Authentication and personal endpoints

Personal routes require `Authorization: Bearer <api-access-token>`. Apple identity tokens are accepted only by `POST /v1/auth/apple` for session exchange and are never used as long-lived API bearer credentials.

- `PUT /v1/me/ratings/:mixId` with `{ "score": 1...5 }` creates or replaces the user's rating.
- `DELETE /v1/me/ratings/:mixId` removes it and is idempotent.
- `PUT /v1/me/favorites/:mixId` adds a favorite and is idempotent.
- `DELETE /v1/me/favorites/:mixId` removes it and is idempotent.
- `GET /v1/me/inventory` returns only the authenticated user's inventory.
- `GET /v1/me/library` returns the current account's favorites, ratings, inventory, personal-mix summaries and article bookmark slugs.
- `GET /v1/me/inventory/matches` returns ready, substitution and one-missing matches while applying substitution deny rules and private exact-flavor inventory semantics.
- `PUT /v1/me/inventory` upserts `{ "productId": "...", "level": "plenty|low|empty" }` or the same body with `privateProductId`. Exactly one product identifier is required.
- `DELETE /v1/me/inventory/:itemId` deletes an item only when owned by the authenticated user.
- `GET|POST /v1/me/private-products` lists or creates user-owned positions; `DELETE /v1/me/private-products/:id` deletes only an owned position. Create accepts `brandName`, optional `lineName`, `flavorName`, and normalized `flavorProfiles`.
- `PUT|DELETE /v1/me/article-bookmarks/:id-or-slug` idempotently adds or removes a bookmark for the current account.
- `GET /v1/me/personal-mixes` lists the user's private mixes.
- `GET /v1/me/personal-mixes/:id` returns one owned mix and its ordered components.
- `POST /v1/me/personal-mixes` creates a mix; optional UUID `clientId` makes retries idempotent. `PUT /v1/me/personal-mixes/:id` replaces its editable fields and complete composition atomically.
- `DELETE /v1/me/personal-mixes/:id` deletes an owned mix.

Personal mix write bodies accept optional `title`, `score` (`1...5`) and `comment`, plus a required non-empty `components` array. Each component must contain exactly one of `productId`, `privateProductId`, or non-empty `freeformName`. Array order is persisted as stable `position` values starting at 1. Percentages may be omitted from every component; when present, every component must have one and the total must equal 100. Composition replacement and the parent write run in one database transaction.

The database primary keys enforce one rating and one favorite per user/mix. Partial unique indexes enforce one inventory row per user/product. Private products are selected with the authenticated user ID in the mutation query, preventing cross-user attachment.

## Authentication

`APPLE_PROVIDER_MODE` is explicit: use `disabled` only for local/test injection and `enabled` in production. Production refuses disabled or partially configured provider lifecycle settings.

Production requires `APPLE_CLIENT_ID` (or comma-separated `APPLE_CLIENT_IDS`), a random `SESSION_TOKEN_SECRET` of at least 32 bytes, and `APPLE_PROVIDER_CLIENT_ID`, `APPLE_TEAM_ID`, `APPLE_KEY_ID`, `APPLE_PRIVATE_KEY`, `APPLE_TOKEN_ENCRYPTION_KEYS`, and `APPLE_TOKEN_KEY_VERSION`. The explicit provider client must be present in the verifier audience list. `APPLE_TOKEN_ENCRYPTION_KEYS` is a comma-separated keyring of `version:base64-encoded-32-byte-key`; the active version encrypts new values, while stored versions select their decryption key. Retain retired keys until all corresponding database envelopes are re-encrypted or deleted. Missing/inconsistent provider credentials fail startup in production; local/test mode omits the complete set explicitly and uses injected fixtures. `POST /v1/auth/apple` accepts the ephemeral Apple identity token and optional single-use `authorizationCode`. A new account requires successful code exchange at Apple's `/auth/token`; the returned provider refresh token is stored only as a versioned AES-256-GCM envelope. A failed repeat exchange never overwrites an existing provider token. The endpoint returns a 15-minute API access token with a rotating opaque 30-day app refresh token. Only the SHA-256 app refresh-token hash is stored. `POST /v1/auth/refresh` rotates it; reuse revokes its complete family. `POST /v1/auth/logout` revokes the current device session.

`GET /v1/me/admin-capabilities` is authenticated and returns only the current server-side admin grant. The iOS app uses this response to expose its native administration entry; it has no local admin allowlist. Every `/v1/admin/*` route independently enforces the same policy and returns 401/403 as appropriate. The Admin API supports sources, brands, lines, localized products/tags, official mixes with transactional components, localized structured articles, and substitution deny rules. Published or archived content requires provenance.

`DELETE /v1/me/account` first revokes an available provider refresh token at Apple's `/auth/revoke`, then transactionally deletes the user; cascades remove personal mixes/components, ratings, favorites, inventory, private products, and app sessions. A transient provider failure returns `503 apple_provider_revocation_failed` and leaves the account intact for retry. A genuinely legacy account without a stored provider token is deleted and returns `providerRevocation: unavailable`; the UI must not claim Apple authorization was revoked.

Tokens and PII must never be included in application logs.

The iOS app reads `API_BASE_URL` from its generated Info.plist. The checked-in Debug default is `http://127.0.0.1:3010`; production configuration must override it with a valid HTTPS origin. Missing/malformed values and non-HTTPS Release values leave networking signed out with a configuration error rather than creating a fallback or fake session.

## Admin API

Admin routes use the same verified Apple identity and then apply a separate `AdminAuthorizationPolicy`. Production uses `AppleSubjectAllowlist`, configured by the comma-separated `ADMIN_APPLE_SUBJECTS`; an empty allowlist denies everyone. A valid user outside the allowlist receives `403`, while missing or invalid authentication receives `401`.

Protected CRUD resources under `/v1/admin` are:

- `/sources`, `/brands`, `/lines`, `/flavor-tags`, `/articles`;
- `/products` (the write body includes the complete `tags` array of `{ tagId, weight }`);
- `/official-mixes` (the write body includes the complete ordered `components` array of `{ productId, percentage }`);
- `/substitution-deny-rules` (identified by `sourceProductId` and `substituteProductId`).

List endpoints use `limit` (maximum 100) and `offset` where the resource can grow substantially, with `status`, `brandId`, or `lineId` filters where applicable. Product/tag and official-mix/component writes are transactional. Published or archived records require `sourceId` and `verifiedAt`; official mix percentages must total 100; required RU/EN fields cannot be blank.
