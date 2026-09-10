# HookahBoss MVP audit

Дата аудита: 2026-09-09. Основание: `PRODUCT.md` и текущий worktree. Статус `proven` означает, что требование подтверждается конкретным кодом и/или автоматическим тестом. Компиляция сама по себе не считается доказательством runtime UX.

## Платформа, доступ и жизненный цикл аккаунта

| Требование | Evidence | Статус |
|---|---|---|
| Нативный SwiftUI, iPhone, iOS 17+ | `project.yml`: application/iOS, deployment 17.0, `TARGETED_DEVICE_FAMILY=1`; `HookahBoss/HookahBossApp.swift` | proven |
| RU и EN | RU/EN key sets имеют parity 280/280; locale передаётся в `APIClient`/`PublicContentStore`; Admin field/status/validation labels используют localization keys | proven source parity; runtime locale QA не выполнен |
| Accessibility semantics | Icon-only bookmark/favorite/settings/delete/back controls have labels and practical targets; rating/inventory/bookmark/favorite expose state values; decorative artwork/badges are hidden; component cards use adaptive minimum height | proven source paths and localization parity; accessibility XXXL public-flow XCUITest passes; manual VoiceOver/device visual QA remains |
| Anonymous UI smoke matrix | DEBUG-only deterministic fixture and age reset/bypass; XCUITest covers age gate plus Home, Mixes→detail/composition, filters→results, Articles→reader, signed-out Create auth prompt and My placeholders in EN light, RU dark and EN accessibility XXXL | proven by one combined 4/4 XCUITest suite at `/private/tmp/hb-ui-dynamic-full/Logs/Test/Test-HookahBoss-2026.09.10_04-59-12-+0300.xcresult`; no authenticated Apple/Admin flow is faked |
| Анонимный каталог, статьи и рейтинги | public `GET /v1/brands`, `/products`, `/mixes`, `/articles` в `backend/src/app.ts`; public методы `APIClient` не передают bearer; `APIClientTests.testPublicBrandsGET...` | proven на уровне контракта; runtime UI не прогнан |
| Sign in with Apple | `HookahBoss/AuthCore.swift`: native `SignInWithAppleButton`, Keychain; `HookahBoss.entitlements`; `backend/src/auth.ts`: Apple JWKS verifier; `auth-core.test.ts` | proven на уровне кода/fixtures; реальный Apple credential flow требует подписанной device-сборки |
| Контекстная auth sheet, cancel без ухода, resume один раз | `AuthGate`, `AuthGateSheet`; `AuthGateTests`: success once, cancel/failure, retry, concurrent prompt | proven state machine; presentation runtime не прогнан |
| Личные действия gated | favorite/rating в `MixDetailView`; bookmark в `ArticlesView`; create/inventory в `HookahBossApp.RootView`; placeholders в `SignedOutCollectionView` | proven code paths |
| Logged-out «Моё»: placeholders и повторный prompt | `CollectionView`, `SignedOutCollectionView`, action-specific `ProtectedAction` | proven code path; runtime presentation не прогнан |
| Logout сохраняет, но скрывает account cache | `AuthRuntime.logout`, `AccountCache.key`, `AccountWorkspace.activate(nil)`; account cache/workspace regression tests | proven |
| Удаление аккаунта с подтверждением, provider revoke и server delete-all | `AccountCollectionView`; `DELETE /v1/me/account`; migrations `005_auth_sessions.sql`, `008_apple_provider_credentials.sql`; `appleProvider.ts`; `auth-core.test.ts`, `apple-provider.test.ts` | proven by fixtures — available provider token is revoked before transactional deletion; transient revoke failure preserves the account; legacy absence is explicit. Live Apple verification remains an external release smoke |
| 18+ при первом запуске | `HookahBossApp.hasConfirmedAdultAge`, `AgeConfirmationView` | proven code path; persistence/runtime QA не прогнан |
| Нет рекламы, покупок, уведомлений, публикаций | dependencies in `project.yml`/`backend/package.json`; отсутствие StoreKit/ad/push/user-publish routes | proven статическим аудитом |
| Нет продаж/магазинов/цен | public DTO/routes и seed validators/manifests не содержат commerce endpoints/data | proven для текущего контента |

## Навигация и публичный контент

| Требование | Evidence | Статус |
|---|---|---|
| 5 вкладок Home/Mixes/Create/Articles/My | `RootView` TabView; RU/EN `tab.*` | proven code path |
| Home: mix of day, два действия, рекомендации | `HomeView`; `AppNavigation`; `MixRankingTests`; hero использует тот же `MixArtwork(palette:)` с сильным readability gradient | proven logic/artwork path; runtime layout не прогнан |
| Mix of day анонимный и стабильный за день | `MixRanker.mixOfDay`; `MixRankingTests.testMixOfDayIsStableAndChangesOnNextDay` | proven |
| Рекомендации учитывают favorite/rating/collective confidence | `MixRanker`, `HomeView.personalized`; `MixRankingTests` | proven deterministic logic |
| Mix catalog grid, search, filters | `MixesView`, `MixFilterView` | proven code path; visual runtime не прогнан |
| Отдельная выдача ideal/possible без процента | `MixResultsView` | proven code path |
| Ranking: match section, personal signals, collective, stable feed tie | `MixResultsView`, `MixRanker`; `MixRankingTests` | proven; «новизна» представлена только стабильным порядком feed, не отдельной publish-date метрикой |
| Public cache/SWR/offline fallback | `DiskPublicCache`, `PublicContentStore`; `PublicContentStoreTests` | proven logic for list/detail cache; no network-transition UI test |
| Release API config fail closed | explicit `HookahBoss/Info.plist`, Debug/Release settings in `project.yml`, `AppConfig`; `AppConfigBundleTests` | proven build config; production HTTPS URL ещё не задан |

## Карточка и экран официального микса

| Требование | Evidence | Статус |
|---|---|---|
| Две колонки, ratio 0.86, full artwork/gradient/title/cloud/rating/strength | `MixesView`, `MixCardView`, `FlavorCloud` | proven code; screenshot/device QA не выполнен |
| Heart outline/filled без подложки | `MixCardView` | proven code |
| Personal rating badge и rating-dependent gradient border | `MixCardView`, `AppTheme.ratingColor` | proven code |
| Logical artwork mapping from flavor profiles | `ArtworkPalette.forProfiles`; `PublicContentStoreTests.testArtworkMapping...`; bundled PNG tests | proven |
| Authoritative rich detail hydration from every navigation path | Home/Mixes/My pass their `PublicContentStore` into `MixDetailView`; summary renders immediately, then cached detail and `/v1/mixes/:id` refresh hydrate components/profile/intensities/strength while favorite/rating remain independent optimistic state | proven by detail hydration + stale fallback runtime test |
| Rating sheet 1–5, mutable one-per-user | `RatingSheet`, `AuthRuntime.setRating`; DB unique constraint in `001_initial.sql`; personal API tests | proven |
| Horizontal noninteractive component cards; no bulk inventory action | `MixDetailView.composition`, `IngredientCard`; no bulk action | proven code |
| Rich ID-driven detail DTO | `/v1/mixes/:id`, `OfficialMixDetailDTO`, `PublicContentStore.cachedMixDetail/mixDetail`; every in-app entry passes its store and `MixDetailView.task` hydrates by ID | proven for all current in-app paths and future ID-driven construction; an external URL scheme is neither defined nor required by PRODUCT |

## Inventory и matching

| Требование | Evidence | Статус |
|---|---|---|
| Только добавленные позиции, three states | `InventoryStore` starts empty; `InventoryLevel`; `AuthGateTests.testNewInventoryContainsNoImplicitEmptyCatalogRows` | proven |
| Inline single expanded selector | `InventoryFullList.expanded`, `InventoryRow` | proven code; interaction runtime не прогнан |
| Add/search, custom private positions, delete | `InventoryAddView`, `PrivateProductAddView`; `/v1/me/private-products`; `personal.test.ts` ownership/validation | proven |
| Three result sections and substitution/missing notes | `InventoryMixResultsView` | proven code |
| Exact product, private exact flavor, tag substitute, deny rules | SQL in `GET /v1/me/inventory/matches`; `personal.test.ts: inventory matching applies deny rules...` | proven server logic |
| Successful empty response is not mistaken for offline fallback | `InventoryMatchLoadState.loaded([])` and server-only classification; `SyncSupportTests.testInventoryMatchCacheDistinguishes...` | proven |
| Offline matching | `InventoryMatchCache`, account-scoped last successful server result; no local invented substitute heuristic | proven cache semantics; first-ever offline visit correctly shows error because no authoritative result exists |
| Inventory durable outbox/account isolation | `InventoryStore` outbox + projection; `SyncSupportTests` pending overlay, order, account isolation | proven |

## Личные миксы и коллекция

| Требование | Evidence | Статус |
|---|---|---|
| Modal create, empty initial composition, optional title, no rating/comment fields | `RootView.fullScreenCover`, `CreateMixView` | proven code |
| Horizontal component cards; catalog/private/inventory picker; no duplicates | `CreateMixView`, `ComponentPicker(excluding:)`; picker uses shared cached inventory/private metadata and overlays refreshed private products | proven logic; runtime picker QA not run |
| Partial percentages auto-fill; >100 blocked; deterministic exact 100 transport | `PercentageDistributor`, `CreateMixView.save`, `PersonalMixStore`; `PercentageDistributorTests`, `SyncSupportTests.testCreateWrite...` | proven |
| Minimum one component and source invariant | client distributor; `validatePersonalMix`/personal mix routes; `personal-mixes.test.ts` | proven |
| Optional score/comment supported by model/API | migrations, `PersonalMixBody`, DTO | proven backend contract; intentionally absent from quick-create UI |
| Personal mix remains private/owner scoped | `/v1/me/personal-mixes`; `personal-mixes.test.ts` ownership | proven |
| «Моё»: counters, previews, full favorites/personal/inventory, settings | `AccountCollectionView`, `CollectionSection` destinations | proven code; navigation runtime not run |
| Personal mix generated template cover | `PersonalMixArtwork` derives a deterministic template from persisted component `flavorProfiles`; personal-mix detail hydration resolves official/private product names and profiles | proven code path; visual screenshot QA not run |
| Equal-without-input is marked approximate in personal profile | migration `007_personal_mix_profile.sql`, personal mix API DTO/write paths, backward-compatible local decoding, and `personalMix.approximate` RU/EN marker | proven code path |
| Personal repository cache/outbox/reconcile | one `AccountWorkspace` store instance is shared by Create and My; `PersonalMixStore`, `PersonalMixReconciler`; workspace create→My/account-switch tests | proven logic; no global unauth singleton |

## Articles

| Требование | Evidence | Статус |
|---|---|---|
| Five category-first cards + recommended list | `ArticlesView`, `ArticleCategory.allCases` | proven code |
| Time, no author/date | `ArticleRow`, `ArticleReaderView`; public Article DTO excludes author/date | proven |
| Structured localized reader + immersive hero | `ArticleReaderView` maps all five `ArticleCategory.artworkFilename` values to bundled raster artwork via `ArtworkResource`, with gradient/SF Symbol fallback; bundle mapping test; `/v1/articles/:id` | proven code/resource path; runtime layout not run |
| 2–3 related | article seed validator and public detail query; `ArticleReaderView` related cards | proven seed/contract |
| Account-scoped server bookmarks + offline outbox | article bookmark routes, `AuthRuntime`; `personal.test.ts`, `SyncSupportTests` | proven |
| Safety editorial constraints | `backend/seeds/articles-v1.ts`; `article-seed.test.ts` balanced bilingual validation and provenance | proven content artifact; medical editorial review remains external |

## Backend, auth, cache and admin

| Требование | Evidence | Статус |
|---|---|---|
| Public contract hardening | Public mixes/matching exclude unpublished dependencies; matching locale is used; malformed catalog/inventory UUIDs return 400; article nullable storage is normalized to non-null DTOs; inventory upsert returns display metadata | proven by `app.test.ts`/`personal.test.ts` regression paths; backend 60/60 |
| Node/TypeScript/PostgreSQL/Docker Compose | `backend/package.json`, migrations, `docker-compose.yml` | proven locally; VDS deployment missing |
| Apple JWKS signature/iss/aud/exp/iat/cache refresh | `backend/src/auth.ts`; `auth-core.test.ts` | proven fixture tests; live Apple JWKS/production credentials not exercised |
| Short access + rotated hashed refresh, reuse revoke | migrations `005`, auth services/routes; `auth-core.test.ts`; actor-held refresh task; concurrent runtime single-flight test | proven |
| Ratings/favorites/library sync optimistic + rollback/outbox | personal routes, `AuthRuntime`; `SyncSupportTests` | proven deterministic logic |
| Account cache namespace/delete purge | `AccountCache`, inventory/personal/library/match keys; `AuthGateTests`, `SyncSupportTests` | proven |
| Server admin capability, hidden UI, 401/403 | `/v1/me/admin-capabilities`, `AuthRuntime.isAdmin`, conditional service section in My via `AdminEntryVisibility`; settings contain only logout/delete; backend auth tests + visibility unit tests | proven |
| Admin CRUD all named entities | `backend/src/admin.ts`; `AdminResource.all`, `AdminResourceListView`, `AdminEditorView` | proven vertical CRUD code paths; runtime end-to-end against DB not run in this audit |
| Publish/archive provenance and localization validation | backend admin validators/tests; `AdminFormValidator`, form status | proven server-side; product/mix status changes are done through full edit form, not list swipe |
| Native compact component/tag/article section rows, no raw JSON | `AdminEditorView` filters `.json`, row editors; `AdminAggregateMapper`; `AdminFormTests` | proven |
| Полный Admin list/reference catalog без silent truncation | `APIClient.adminList` последовательно получает limit/offset pages, сохраняет порядок и останавливается на short/empty/no-new page; API client tests cover 229 и exact multiple | proven logic; runtime API integration не прогнана |
| Полная публичная загрузка products/mixes без silent truncation | Backend cursor contract keeps legacy exhaustive shape when `pageSize` is absent and provides opaque keyset cursors for bounded pages; `APIClient.allCursorPages` requests 100, deduplicates UUIDs, rejects repeated cursors/over 1000 pages, and returns only after the complete traversal; `PublicContentStore` applies and caches the combined snapshot atomically | proven by backend 93/93 and targeted APIClient 15/15 tests; live production-volume HTTP smoke remains release QA |
| Admin dashboard: catalog sections as compact rows | `AdminDashboardView`/`AdminDashboardRow`: icon, localized section name, live full-list count/status and navigation chevron | proven code path; runtime layout not run |

## Content and visual system

| Требование | Evidence | Статус |
|---|---|---|
| Russia/CIS target and provenance/date/translation origin | versioned seeds and source manifests in `backend/seeds`; catalog/mix/article validators | proven artifacts |
| 10–15 brands, 150–250 flavors, 40–60 mixes, 8–12 articles | validators: combined catalog, 46 official mixes, 10 articles; seed tests | proven (exact catalog counts are emitted by validation command) |
| Current + archived with explicit status | schema status enums, seed records, Admin filters; public product route forces published | proven |
| Collective ratings start at zero | ratings table empty by seeds; public SQL aggregates user ratings | proven by seed/schema inspection |
| Cream light, graphite dark, system-only theme, gold | `AppTheme`, screen surfaces; `AppThemeTests`; `PRODUCT.md` | proven code/contrast tests; full visual runtime QA not run |
| Official artwork bundled and profile-mapped | `HookahBoss/Artwork`, `MixArtwork`; bundle/mapping tests | proven |

## External blockers and release gates

Automated source provenance audit is available as `cd backend && npm run sources:verify`; it writes a deduplicated machine-readable report and performs strict seeded-recipe evidence checks for MUSTHAVE pages. Other publishers are explicitly classified `reachability_only`; a 2xx dynamic HTML shell with at least 1 KB raw body but little server-rendered text is retained only with `dynamic_shell_visible_text_short`, never promoted to semantic verification. Latest live evidence is 64/64 valid: 34 MUSTHAVE pages semantically verified and 30 sources explicitly reachability-only; the CLI exited zero. Report: `backend/reports/provenance-sources-live-2026-09-10-blackburn.json`. The verifier never mutates `verifiedAt`; dates change only after genuine source review. Backend automated suite: 86/86 passed.

BlackBurn catalog provenance is generated from the official `/taste` page and its discovered public catalog API: 80 validated products replace the former 15-item fallback subset, with commerce/media excluded and missing authoritative products archived, never deleted, on import. `npm run catalog:refresh:blackburn -- --dry-run` reports drift without writing; `--check` exits nonzero on drift. Iceberg is classified with the localized `cooling`/`Охлаждение` tag and explicitly not mint.

The `fresh` profile is propagated through the database constraint, private-product API validation, public DTO mapping, filter `allCases`, RU/EN localization and deterministic tropical artwork fallback. Regression tests cover API acceptance, Swift mapping/palette behavior, and Iceberg remaining exact `cooling` without implicit mint/herbal equivalence. The final live BlackBurn `--check` reported 80 products with zero added/changed/removed/unclassified drift.

The owner/input/validation handoff for these gates is maintained in [`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md).

- Runtime unit XCTest: 67/67 passed on iPhone 15 Pro Simulator (`/private/tmp/hb-blackburn-unit/Logs/Test/Test-HookahBoss-2026.09.10_05-51-05-+0300.xcresult`). One combined XCUITest suite passed 4/4 (`/private/tmp/hb-ui-dynamic-full/Logs/Test/Test-HookahBoss-2026.09.10_04-59-12-+0300.xcresult`): age EN, anonymous EN light, anonymous RU dark and anonymous EN accessibility XXXL. VoiceOver announcements and screenshot-level device clipping still require a manual pass.
- `external blocker`: production VDS deployment and a real HTTPS `HOOKAHBOSS_RELEASE_API_BASE_URL` are not configured.
- `external blocker`: live Sign in with Apple exchange/revoke requires signing/team/App ID and real Apple credentials. Implementation and local fixtures exist, but production Apple endpoints require staging smoke.
- `external blocker`: App Store age-rating questionnaire, distribution strategy and review risk under Guideline 1.4.3 cannot be proven by repository tests.
- `missing by explicit deferral`: final product name, icon and distribution choice.

## Verification commands

- Backend: `cd backend && npm run check`
- Seed validation: `npm run seed:validate`, `npm run seed:mixes:validate`, `npm run seed:articles:validate`
- iOS project: `xcodegen generate`
- iOS runtime tests: `xcodebuild ... -destination 'platform=iOS Simulator,id=F71385FC-3DF2-45BD-834F-A7DDBFBEF3B5' test`
- Bundle configuration: `plutil -extract API_BASE_URL raw <DerivedData>/Build/Products/Debug-iphonesimulator/HookahBoss.app/Info.plist`
