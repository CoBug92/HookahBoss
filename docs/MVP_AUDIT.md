# HookahBoss MVP audit

Дата аудита: 2026-09-12. Основание: `docs/PRODUCT.md` и текущий worktree. Статус `proven` означает, что требование подтверждается конкретным кодом и/или автоматическим тестом. Компиляция сама по себе не считается доказательством runtime UX.

## Платформа, доступ и жизненный цикл аккаунта

| Требование | Evidence | Статус |
|---|---|---|
| Нативный SwiftUI, iPhone, iOS 18+ | `ios/scripts/xcodegen/Application.yml`: application/iOS, deployment 18.0, `TARGETED_DEVICE_FAMILY=1`; `ios/HookahBoss/App/HookahBossApp.swift` | proven |
| RU и EN | RU/EN key sets имеют parity 280/280; locale передаётся в `APIClient`/`PublicContentStore`; Admin field/status/validation labels используют localization keys | proven source parity; runtime locale QA не выполнен |
| Accessibility semantics | Icon-only bookmark/favorite/settings/delete/back controls have labels and practical targets; rating/inventory/bookmark/favorite expose state values; decorative artwork/badges are hidden; component cards use adaptive minimum height | proven source paths and localization parity; manual VoiceOver/device visual QA remains |
| UI smoke matrix | Automated iOS test targets and their DEBUG-only fixtures are temporarily removed | manual checks are required for age gate, public flows, signed-out states, RU/EN, light/dark and accessibility sizes |
| Анонимный каталог, статьи и рейтинги | public `GET /v1/brands`, `/products`, `/mixes`, `/articles` в `backend/src/app.ts`; public методы `APIClient` не передают bearer | proven на уровне контракта; runtime UI не прогнан |
| Sign in with Apple | `ios/HookahBoss/App/AuthRuntime.swift`, `ios/HookahBoss/Features/Auth/AuthGateSheet.swift`; `ios/HookahBoss/Resources/Plists/HookahBoss.entitlements`; `backend/src/auth.ts`: Apple JWKS verifier; `auth-core.test.ts` | proven на уровне кода/fixtures; реальный Apple credential flow требует подписанной device-сборки |
| Контекстная auth sheet, cancel без ухода, resume один раз | `AuthGate`, `AuthGateSheet`; signed-out Collection placeholders resume through `AppNavigation.openCollection` into Favorites, Personal mixes or Inventory | proven code path; state-machine and real Apple presentation require manual release smoke |
| Личные действия gated | favorite/rating в `MixDetailView`; bookmark в `ArticlesView`; create/inventory в `RootView`; placeholders в `SignedOutCollectionView` | proven code paths |
| Logged-out «Моё»: placeholders и повторный prompt | `CollectionView`, `SignedOutCollectionView`, action-specific `ProtectedAction` | proven code path; runtime presentation не прогнан |
| Logout сохраняет, но скрывает account cache | `AuthRuntime.logout`, `AccountCache.key`, `AccountWorkspace.activate(nil)` | proven code path; runtime regression check is manual |
| Удаление аккаунта с подтверждением, provider revoke и server delete-all | `AccountCollectionView`; `DELETE /v1/me/account`; migrations `005_auth_sessions.sql`, `008_apple_provider_credentials.sql`; `appleProvider.ts`; `auth-core.test.ts`, `apple-provider.test.ts` | proven by fixtures — available provider token is revoked before transactional deletion; transient revoke failure preserves the account; legacy absence is explicit. Live Apple verification remains an external release smoke |
| 18+ при первом запуске | `HookahBossApp.hasConfirmedAdultAge`, `AgeConfirmationView` | proven code path; persistence/runtime QA не прогнан |
| Нет рекламы, покупок, уведомлений, публикаций | dependencies in `ios/scripts/xcodegen/Application.yml`/`backend/package.json`; отсутствие StoreKit/ad/push/user-publish routes | proven статическим аудитом |
| Нет продаж/магазинов/цен | public DTO/routes и seed validators/manifests не содержат commerce endpoints/data | proven для текущего контента |

## Навигация и публичный контент

| Требование | Evidence | Статус |
|---|---|---|
| 5 вкладок Home/Mixes/Create/Articles/My | `RootView` TabView; RU/EN `tab.*` | proven code path |
| Home: full-page initial skeleton, mix of day, два действия, рекомендации, отдельные cached/empty/error states | `HomeView`, `HomeViewModel`, `HomeViewState`, `HomeCachedContentView`, `HomeStatusView`; `PublicCatalogSnapshot.freshness` отличает свежий ответ от кэша после ошибки, а отсутствие обоих источников приводит к failure; every recommendation is a `NavigationLink` and Home resynchronizes favorite/rating projections on return | proven code path; loading/cached/error transitions and navigation require manual runtime QA |
| Mix of day анонимный и стабильный за день | `MixRanker.mixOfDay` | proven deterministic code path |
| Рекомендации учитывают favorite/rating/collective confidence | `MixRanker`, `HomeView.personalized` | proven deterministic code path |
| Mix catalog grid, search, filters, full-page skeleton and separate cached/empty/error states | `MixesView`, `MixCatalogViewModel`, `MixesViewState`, `MixesSkeletonView`, `MixesCachedNoticeView`, `MixesStatusView`; `PublicCatalogSnapshot.freshness` separates fresh and cached catalog content, while an unavailable source without usable data produces failure | proven code path; loading/cached/error transitions and visual runtime require manual QA |
| Отдельная выдача ideal/possible без процента | `MixResultsView` | proven code path |
| Ranking: match section, personal signals, collective, stable feed tie | `MixResultsView`, `MixRanker` | proven code path; «новизна» представлена только стабильным порядком feed, не отдельной publish-date метрикой |
| Public cache/SWR/offline fallback | `DiskPublicCache`, `PublicContentStore` | proven code path for list/detail cache; network-transition QA is manual |
| Release API config fail closed | explicit `ios/HookahBoss/Resources/Plists/Info.plist`, Debug/Release settings in `ios/scripts/xcodegen/Application.yml`, `AppConfig` | proven build config; production HTTPS URL ещё не задан |

## Карточка и экран официального микса

| Требование | Evidence | Статус |
|---|---|---|
| Две колонки, ratio 0.86, full artwork/gradient/title/cloud/rating/strength | `MixesView`, `MixCardView`, `FlavorCloud` | proven code; screenshot/device QA не выполнен |
| Heart outline/filled без подложки | `MixCardView` | proven code |
| Personal rating badge и rating-dependent gradient border | `MixCardView`, `AppTheme.ratingColor` | proven code |
| Logical artwork mapping from flavor profiles | `ArtworkPalette.forProfiles`; native asset resources | proven code/resource path |
| Native card-to-detail zoom, system large navigation title, Ken Burns and cascaded detail content | `MixTransitionSourceModifier`, `MixNavigationTransitionModifier`, `MixDetailView`, `MixDetailCoverView`, `MixDetailContentView`; the cover animation has no scroll-dependent geometry, parallax or pull-down transform | proven code path; transition timing and scrolling behavior require manual runtime QA |
| Authoritative rich detail hydration from every navigation path | Home/Mixes/My pass their `PublicContentStore` into `MixDetailView`; summary renders immediately, then cached detail and `/v1/mixes/:id` refresh hydrate components/profile/intensities/strength while favorite/rating remain independent optimistic state | proven code path; stale fallback requires manual runtime QA |
| Rating sheet 1–5, mutable one-per-user | `MixRatingSheet`, `AuthRuntime.setRating`; DB unique constraint in `001_initial.sql`; `MixPreview.applyingPersonalRatingChange` immediately projects create/change/delete into collective average/count, preserves rollback, and catalog `onAppear` resynchronizes the personal badge/favorite after detail dismissal | proven by API, aggregate projection, ViewModel rollback and catalog resynchronization tests |
| Horizontal noninteractive component cards; no bulk inventory action | `MixCompositionView`, `MixIngredientCard`; no bulk action | proven code |
| Rich ID-driven detail DTO | `/v1/mixes/:id`, `OfficialMixDetailDTO`, `PublicContentStore.cachedMixDetail/mixDetail`; every in-app entry passes its store and `MixDetailView.task` hydrates by ID | proven for all current in-app paths and future ID-driven construction; an external URL scheme is neither defined nor required by PRODUCT |

## Inventory и matching

| Требование | Evidence | Статус |
|---|---|---|
| Только добавленные позиции, three states | `InventoryStore` starts empty; `InventoryLevel` | proven code path |
| Inline single expanded selector | `InventoryView`, `InventoryRow`, `CollectionViewModel.expandedItemID` | proven code; interaction runtime не прогнан |
| Add/search, custom private positions, delete | `InventoryAddView`, `PrivateProductAddView`; `/v1/me/private-products`; `personal.test.ts` ownership/validation | proven |
| Full-page loading plus separate content/empty/failure matching states | `InventoryMatchesView`, `InventoryMatchesViewState`, `InventoryMatchesSkeletonView`, `InventoryMatchesStatusView` | proven code path; state transitions require manual QA |
| Three result sections and substitution/missing notes | `InventoryMatchesSection`, `InventoryMixResultCard` | proven code |
| Exact product, private exact flavor, tag substitute, deny rules | SQL in `GET /v1/me/inventory/matches`; `personal.test.ts: inventory matching applies deny rules...` | proven server logic |
| Successful empty response is not mistaken for offline fallback | `InventoryMatchesViewModel` maps an empty server result to `.empty`; `.failure` exposes a localized Retry action | proven code path; transient failure and retry require manual QA |
| Offline matching | `InventoryMatchCache`, account-scoped last successful server result; no local invented substitute heuristic | proven cache semantics; first-ever offline visit correctly shows error because no authoritative result exists |
| Inventory durable outbox/account isolation | `InventoryStore` outbox + projection | proven code path; persistence regression check is manual |

## Личные миксы и коллекция

| Требование | Evidence | Статус |
|---|---|---|
| Modal create, empty initial composition, optional title, no rating/comment fields | `RootView.fullScreenCover`, `CreateMixView`; loading blocks premature picker/save actions, save exposes progress and dismisses only after `didSave` | proven code and ViewModel success/failure/retry tests |
| Horizontal component cards; catalog/private/inventory picker; no duplicates | `CreateMixView`, `ComponentPicker(excluding:)`; picker uses shared cached inventory/private metadata and overlays refreshed private products | proven logic; runtime picker QA not run |
| Partial percentages auto-fill; >100 blocked; deterministic exact 100 transport | `PercentageDistributor`, `CreateMixView.save`, `PersonalMixStore` | proven code path |
| Minimum one component and source invariant | client distributor; `validatePersonalMix`/personal mix routes; `personal-mixes.test.ts` | proven |
| Optional score/comment supported by model/API | migrations, `PersonalMixBody`, DTO | proven backend contract; intentionally absent from quick-create UI |
| Personal mix remains private/owner scoped | `/v1/me/personal-mixes`; `personal-mixes.test.ts` ownership | proven |
| «Моё»: initial skeleton, counters, previews, full favorites/personal/inventory, settings | `CollectionViewState`, `CollectionSkeletonView`, `CollectionView` and atomic feature-local sections; favorites use typed RU/EN `L10n.Collection.favorites` | proven code; state transition and navigation require manual QA |
| Collection flows have independent feature boundaries | sibling `Favorites`, `Inventory`, `InventoryAdd`, `InventoryMatches`, `PersonalMixes` and `PersonalMixDetail` folders; `Collection` retains only its screen state, sections and presentation composition | proven source layout and generated project membership |
| Open a saved personal mix and inspect its generated cover/composition | `PersonalMixDetailView` + `PersonalMixDetailViewModel`; compact and full personal lists both navigate to it; horizontal cards show persisted brand/line/flavor/percentage | proven code path; runtime presentation requires manual QA |
| Personal mix generated template cover | `PersonalMixArtwork` derives a deterministic template from persisted component `flavorProfiles`; personal-mix detail hydration resolves official/private product names and profiles | proven code path; visual screenshot QA not run |
| Equal-without-input is marked approximate in personal profile | migration `007_personal_mix_profile.sql`, personal mix API DTO/write paths, backward-compatible local decoding, and `personalMix.approximate` RU/EN marker | proven code path |
| Personal repository cache/outbox/reconcile | one `AccountWorkspace` store instance is shared by Create and My; `PersonalMixStore`, `PersonalMixReconciler`; workspace account-switch tests and real `CreateMixService → PersonalMixStore → reloaded account cache` integration test | proven logic; no global unauth singleton |

## Articles

| Требование | Evidence | Статус |
|---|---|---|
| Large Navigation Bar, category-first cards, editorial grid and «Продолжить чтение» list | `ArticlesView` owns the large title and bookmark toolbar item; `ArticleCategory.allCases`, `ArticleEditorialSelection`; specific editorial artwork uses native namespaced `ImageResource` symbols | proven code/resource path; runtime layout requires manual QA |
| Full-page loading, content, cached warning, empty and failure states | `ArticlesViewState`, `ArticlesViewModel`, `ArticlesSkeletonView`, `ArticlesCachedContentView`, `ArticlesStatusView`; `PublicCatalogSnapshot.freshness` separates fresh and cached results | proven code path; state transitions require manual QA |
| Time, no author/date | `ArticleRow`, `ArticleDetailView`; public Article DTO excludes author/date | proven |
| Structured localized reader + immersive hero | sibling `Features/ArticleDetail` module with atomic hero, skeleton, content, section, error and related-card views; shared artwork maps all five categories to bundled `Images.xcassets` through native Xcode symbols; `/v1/articles/:id` | proven code/resource path; runtime layout not run |
| Native article opening transition and reduced-motion fallback | article artwork sources use `matchedTransitionSource`; `ArticleDetailView` uses native iOS 18 zoom transition followed by independent Ken Burns and cascade; Reduce Motion disables the additional animation | proven code path; visual timing requires manual QA |
| 2–3 related | article seed validator and public detail query; `RelatedArticlesView` pushes the selected `ArticleDTO` through the parent navigation destination into another hydrated detail screen | proven seed/contract and code path; detail navigation requires manual QA |
| Account-scoped server bookmarks + offline outbox | article bookmark routes, `AuthRuntime`; recommended/category/bookmark lists derive state live from `ArticlesViewModel`, reader/list publish rollback errors, and parent resynchronizes on return; `personal.test.ts` | proven backend contract and iOS code path |
| Substantive bilingual editorial content and safety constraints | `backend/seeds/articles-v1.ts` contains three or more sections per locale for every article; validator checks section count, body substance, balanced categories and provenance | proven content artifact; medical editorial review remains external |

## Backend, auth, cache and admin

| Требование | Evidence | Статус |
|---|---|---|
| Public contract hardening | Public mixes/matching exclude unpublished dependencies; matching locale is used; malformed catalog/inventory UUIDs return 400; article nullable storage is normalized to non-null DTOs; inventory upsert returns display metadata | proven by `app.test.ts`/`personal.test.ts` regression paths; backend 60/60 |
| Node/TypeScript/PostgreSQL/Docker Compose | `backend/package.json`, migrations, `backend/docker-compose.yml`, `backend/compose.device-test.yaml` | proven locally; isolated VDS device-test API and PostgreSQL are healthy, and the public HTTPS tunnel passes `/health` plus live mixes/products/articles smoke checks |
| Apple JWKS signature/iss/aud/exp/iat/cache refresh | `backend/src/auth.ts`; `auth-core.test.ts` | proven fixture tests; live Apple JWKS/production credentials not exercised |
| Short access + rotated hashed refresh, reuse revoke | migrations `005`, auth services/routes; `auth-core.test.ts`; actor-held refresh task; concurrent runtime single-flight test | proven |
| Ratings/favorites/library sync optimistic + rollback/outbox | personal routes, `AuthRuntime` | proven code path; rollback/outbox regression check is manual |
| Account cache namespace/delete purge | `AccountCache`, inventory/personal/library/match keys | proven code path; purge regression check is manual |
| Server admin capability, hidden UI, 401/403 | `/v1/me/admin-capabilities`, `AuthRuntime.isAdmin`, conditional service section in My via `AdminEntryVisibility`; settings contain only logout/delete; backend auth tests | proven backend policy and iOS code path |
| Admin CRUD all named entities | `backend/src/admin.ts`; `AdminResource.all`, `AdminResourceListView`, `AdminEditorView` | proven vertical CRUD code paths; runtime end-to-end against DB not run in this audit |
| Publish/archive provenance and localization validation | backend admin validators/tests; `AdminFormValidator`, form status | proven server-side; product/mix status changes are done through full edit form, not list swipe |
| Native compact component/tag/article section rows, no raw JSON | `AdminEditorView` filters `.json`, row editors; `AdminAggregateMapper` | proven code path |
| Полный Admin list/reference catalog без silent truncation | `APIClient.adminList` последовательно получает limit/offset pages, сохраняет порядок и останавливается на short/empty/no-new page; API client tests cover 229 и exact multiple | proven logic; runtime API integration не прогнана |
| Полная публичная загрузка products/mixes без silent truncation | Backend cursor contract keeps legacy exhaustive shape when `pageSize` is absent and provides opaque keyset cursors for bounded pages; `APIClient.allCursorPages` requests 100, deduplicates UUIDs, rejects repeated cursors/over 1000 pages, and returns only after the complete traversal; `PublicContentStore` applies and caches the combined snapshot atomically | proven by backend 100/100 and targeted APIClient 15/15 tests; live production-volume HTTP smoke remains release QA |
| Admin dashboard: catalog sections as compact rows | `AdminDashboardView`/`AdminDashboardRow`: icon, localized section name, live full-list count/status and navigation chevron | proven code path; runtime layout not run |

## Content and visual system

| Требование | Evidence | Статус |
|---|---|---|
| Russia/CIS target and provenance/date/translation origin | versioned seeds and source manifests in `backend/seeds`; catalog/mix/article validators | proven artifacts |
| 10–15 brands, 150–250 flavors, 40–60 mixes, 8–12 articles | validators: combined catalog, 60 official mixes, 10 articles; seed tests | proven (exact catalog counts are emitted by validation command) |
| Current + archived with explicit status | schema status enums, seed records, Admin filters; public product route forces published | proven |
| Collective ratings start at zero | ratings table empty by seeds; public SQL aggregates user ratings | proven by seed/schema inspection |
| Cream light, graphite dark, system-only theme, gold | `AppTheme`, screen surfaces; `PRODUCT.md` | proven code path; visual and contrast QA is manual |
| Official artwork bundled and profile-mapped | `ios/HookahBoss/Resources/Assets/Images.xcassets`, native namespaced `ImageResource` symbols, `ArtworkResource`, `MixArtwork`; bundle/mapping tests | proven |
| Production iOS project architecture/tooling | `ios/scripts/xcodegen/Application.yml` is the reproducible XcodeGen source; top-level `App/Core/Domain/Data/Features/Resources` layout with `Assets`, `Plists` and `Generated` inside `Resources`; `HookahBossApp` is lifecycle-only and `RootView` owns composition; shared concrete stores are created in the composition root; feature services are protocol-injected; SwiftGen provides typed `L10n`, while Xcode generates native symbols for the separate `Resources/Assets/Images.xcassets` and `Resources/Assets/Colors.xcassets` catalogs; SF Symbols and layout values are centralized in `AppSymbol` and `Margin`; large aggregate files are split by responsibility; Make/Fastlane entry points are documented in `ios/README.md` | proven by reproducible generation, strict lint and unsigned generic Simulator build; automated iOS test targets are temporarily absent |

## External blockers and release gates

Automated source provenance audit is available as `cd backend && npm run sources:verify`; it writes a deduplicated machine-readable report and performs strict seeded-recipe evidence checks for MUSTHAVE pages. Other publishers are explicitly classified `reachability_only`; a 2xx dynamic HTML shell with at least 1 KB raw body but little server-rendered text is retained only with `dynamic_shell_visible_text_short`, never promoted to semantic verification. Latest live evidence is 78/78 valid: 48 MUSTHAVE pages semantically verified and 30 sources explicitly reachability-only; the CLI exited zero. Report: `backend/reports/provenance-sources-live-2026-09-13-mixes-v4.json`. The verifier never mutates `verifiedAt`; dates change only after genuine source review. Backend automated suite: 106/106 passed.

BlackBurn catalog provenance is generated from the official `/taste` page and its discovered public catalog API: 80 validated products replace the former 15-item fallback subset, with commerce/media excluded and missing authoritative products archived, never deleted, on import. `npm run catalog:refresh:blackburn -- --dry-run` reports drift without writing; `--check` exits nonzero on drift. Iceberg is classified with the localized `cooling`/`Охлаждение` tag and explicitly not mint.

DARKSIDE full-line ingestion is generated from the official brand page and the public catalog API discovered from its Nuxt runtime. `npm run catalog:refresh:darkside -- --check` completed with 75 products and zero added/changed/removed/unclassified drift. The snapshot retains canonical source titles for RU/EN, official RU descriptions, official tags/categories and strength, and excludes commerce, availability and media. The combined catalog contains a single DARKSIDE brand with 76 products: 75 current official API records plus the separately sourced `lime-up` required by a published mix. Seed validation proves all existing mix component references remain resolvable; archival is constrained to known DARKSIDE source URLs and never deletes records.

MUSTHAVE full-line ingestion is generated from all nine pages of the official server-rendered tobacco category. `npm run catalog:refresh:musthave -- --check` verifies the checked-in deterministic 99-product snapshot against the live source. Only canonical tobacco product cards, official titles and Russian flavor notes are retained; commerce, availability and media are excluded. Existing recipe-referenced slugs are preserved, old subsets are merged without duplicates, and archival is restricted to records owned by official MUSTHAVE catalog/product URLs and never deletes them. Seed and mix validators prove that all published recipe component references remain resolvable.

The `fresh` profile is propagated through the database constraint, private-product API validation, public DTO mapping, filter `allCases`, RU/EN localization and deterministic tropical artwork fallback. Regression tests cover API acceptance, Swift mapping/palette behavior, and Iceberg remaining exact `cooling` without implicit mint/herbal equivalence. The final live BlackBurn `--check` reported 80 products with zero added/changed/removed/unclassified drift.

The owner/input/validation handoff for these gates is maintained in [`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md).

- Automated iOS unit and UI test targets are temporarily absent. The unsigned generic Simulator Debug target builds successfully; VoiceOver announcements, interaction regressions and screenshot-level clipping require a manual pass.
- `external blocker`: the isolated VDS device-test deployment is live, but a stable production HTTPS `HOOKAHBOSS_RELEASE_API_BASE_URL` is not configured; the Debug Quick Tunnel URL is temporary by design.
- `external blocker`: live Sign in with Apple exchange/revoke requires signing/team/App ID and real Apple credentials. Implementation and local fixtures exist, but production Apple endpoints require staging smoke.
- `external blocker`: App Store age-rating questionnaire, distribution strategy and review risk under Guideline 1.4.3 cannot be proven by repository tests.
- `missing by explicit deferral`: final icon and distribution choice.

## Verification commands

- Backend: `cd backend && npm run check`
- Seed validation: `npm run seed:validate`, `npm run seed:mixes:validate`, `npm run seed:articles:validate`
- iOS project: `cd ios && xcodegen generate`
- iOS build: `cd ios && make build`
- Bundle configuration: `plutil -extract API_BASE_URL raw <DerivedData>/Build/Products/Debug-iphonesimulator/HookahBoss.app/Info.plist`
