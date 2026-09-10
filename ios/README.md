# Mixing iOS

Native SwiftUI client targeting iPhone on iOS 17 and later.

## Architecture

The application uses feature-oriented MVVM with one composition root:

- `HookahBoss/App` — application entry point, navigation and dependency composition.
- `HookahBoss/Core` — configuration and design system shared by features.
- `HookahBoss/Domain` — app models, pure ranking/sync rules and service protocols.
- `HookahBoss/Data` — HTTP client, authentication, caches and concrete stores.
- `HookahBoss/Features` — SwiftUI screens and `@MainActor` view models. Feature code depends on protocols rather than concrete networking or persistence APIs.
- `HookahBoss/Resources` — localized strings and bundled artwork.
- `HookahBoss/Generated` — checked-in SwiftGen output. Do not edit generated files manually.

`HookahBossApp.RootView` owns shared concrete stores and injects them into features. `ArchitectureGuardTests` prevents concrete network and persistence APIs from leaking into `Features`.

## Toolchain

Verified versions:

- XcodeGen 2.46.0
- SwiftGen 6.6.3
- Fastlane 2.238.0 through Bundler
- SwiftLint is installed by `make bootstrap` when absent

From the `ios/` directory:

```sh
make bootstrap   # install Ruby gems and missing generation/lint tools
make generate    # SwiftGen, then XcodeGen
make build       # unsigned generic iOS build
make test        # unit, ViewModel and architecture tests
make ui-test     # UI tests on DESTINATION
make lint        # strict SwiftLint
```

Override `DESTINATION`, `DERIVED_DATA_PATH`, `CONFIGURATION` and related Make variables as required. Example:

```sh
make test DESTINATION='platform=iOS Simulator,name=iPhone 15 Pro,OS=17.5'
```

## Generated resources

[`scripts/swiftgen/swiftgen.yml`](scripts/swiftgen/swiftgen.yml) produces typed `L10n` and `AssetFiles` accessors from the English base localization and the artwork directory. Generation runs explicitly through `make generate` and as an Xcode pre-build phase, so stale generated output fails visibly when SwiftGen is unavailable. Generated Swift is checked in for review and deterministic builds. XcodeGen uses [`scripts/xcodegen/Application.yml`](scripts/xcodegen/Application.yml) as the application source of truth.

## Fastlane

Run lanes through Bundler:

```sh
cd ios
bundle exec fastlane ios test
bundle exec fastlane ios build
bundle exec fastlane ios archive
```

The iOS Makefile automatically runs Bundler through rbenv when rbenv is available, avoiding an older system Ruby/Bundler earlier in `PATH`. Direct lane invocation should use `rbenv exec bundle exec fastlane …` on such machines.

The archive lane prepares a local archive only; it never uploads or publishes. Its fixed App Store identifier is `ru.kostyuchenko.mixing`. Supply signing and release configuration through environment variables such as `DEVELOPMENT_TEAM`, `HOOKAHBOSS_RELEASE_API_BASE_URL`, `ARCHIVE_PATH` and `SKIP_CODE_SIGNING`. No credentials belong in the repository.

For a signed local App Store IPA (still without upload), provide all required release settings and run `make release` from `ios/`. The lane fails before archiving unless `TEAM_ID` and an HTTPS `HOOKAHBOSS_RELEASE_API_BASE_URL` are present. `make deploy` additionally requires App Store Connect API-key and match credentials, is restricted to `master`, and uploads to TestFlight. `OUTPUT_DIRECTORY` and `IPA_NAME` are optional.
