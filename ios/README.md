# Mixery iOS

Native SwiftUI client targeting iPhone on iOS 18 and later.

## Architecture

The application uses feature-oriented MVVM with one composition root:

- `HookahBoss/App` — application entry point, navigation and dependency composition.
- `HookahBoss/Core` — configuration and design system shared by features.
- `HookahBoss/Domain` — app models, pure ranking/sync rules and service protocols.
- `HookahBoss/Data` — HTTP client, authentication, caches and concrete stores.
- `HookahBoss/Features` — SwiftUI screens and `@MainActor` view models. Feature code depends on protocols rather than concrete networking or persistence APIs.
- `HookahBoss/Resources` — localized strings, asset catalogs in `Assets` and plist-format configuration in `Plists`.
- `HookahBoss/Resources/Generated` — checked-in SwiftGen localization output. Do not edit generated files manually.

`RootView` owns shared concrete stores and injects them into features.

Layout spacing and offsets use the `Margin` scale. `Margin.x(_:)` accepts only integer steps; fractional values and fractional multipliers are not allowed.

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
make build       # unsigned generic iOS Simulator build
make lint        # strict SwiftLint
```

## Generated resources

[`scripts/swiftgen/swiftgen.yml`](scripts/swiftgen/swiftgen.yml) produces the typed `L10n` accessor from the English base localization. Images and colors live in separate `Resources/Assets/Images.xcassets` and `Resources/Assets/Colors.xcassets` catalogs and are accessed through native Xcode-generated `ImageResource` and `ColorResource` symbols. SwiftGen does not generate image or color accessors. Generation runs explicitly through `make generate` and as an Xcode pre-build phase. Generated localization Swift is checked in for review and deterministic builds. XcodeGen uses [`scripts/xcodegen/Application.yml`](scripts/xcodegen/Application.yml) as the application source of truth.

## Fastlane

Run lanes through Bundler:

```sh
cd ios/scripts
bundle exec fastlane ios build
bundle exec fastlane ios archive
```

Fastlane configuration lives in [`scripts/fastlane`](scripts/fastlane). The iOS Makefile automatically runs Bundler through rbenv when rbenv is available, avoiding an older system Ruby/Bundler earlier in `PATH`. Direct lane invocation from `ios/scripts` should use `rbenv exec bundle exec fastlane …` on such machines.

The archive lane prepares a local archive only; it never uploads or publishes. Its fixed App Store identifier is
`ru.kostyuchenko.mixery`. Copy `scripts/.env.example` to the ignored `scripts/.env`; XcodeGen reads `TEAM_ID` when
present and writes it to `DEVELOPMENT_TEAM`, while unsigned generation and Simulator builds work without a team.
A process environment value remains available for CI. Supply the remaining signing and release configuration through
environment variables such as `HOOKAHBOSS_RELEASE_API_BASE_URL`, `ARCHIVE_PATH` and `SKIP_CODE_SIGNING`. No credentials
belong in the repository.

For a signed local App Store IPA (still without upload), provide all required release settings and run `make release` from `ios/`. The lane fails before archiving unless `TEAM_ID` and an HTTPS `HOOKAHBOSS_RELEASE_API_BASE_URL` are present. `make deploy` additionally requires App Store Connect API-key and match credentials, is restricted to `master`, and uploads to TestFlight. `OUTPUT_DIRECTORY` and `IPA_NAME` are optional.
