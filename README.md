# Mixing / Миксовка

Native iOS application and its API live in one repository, with platform code kept in separate top-level directories.

## Repository map

| Path | Purpose |
|---|---|
| `ios/` | SwiftUI application, project-local Makefile/Gemfile, Xcode project, tests, localization and generation/release tooling |
| `backend/` | Node.js/TypeScript API, PostgreSQL, Compose definitions, seeds, tests and VDS helpers |
| `docs/PRODUCT.md` | Shared product specification |
| `docs/MVP_AUDIT.md` | Evidence-based implementation audit |
| `docs/RELEASE_CHECKLIST.md` | Cross-platform release gates |
| `docs/DEVICE_TEST.md` | Device-test deployment runbook |

## iOS

Open `ios/HookahBoss.xcodeproj` in Xcode, or build from the repository root:

```sh
xcodebuild -project ios/HookahBoss.xcodeproj -scheme HookahBoss \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
```

The checked-in Xcode project and typed resources are generated from specifications in `ios/scripts/`. See [`ios/README.md`](ios/README.md) for architecture, tooling and Fastlane details. Regenerate them with:

```sh
cd ios
make generate
```

## Backend

```sh
cd backend
npm ci
npm run check
```

After dependencies are installed, the same check is available as `cd ios && make backend-check`. `cd ios && make verify` runs lint, iOS build/tests and the backend check.

For the local Compose environment:

```sh
cd backend
docker compose up --build
```

Local secrets belong in ignored `.env` files. Start with `backend/.env.example`; never commit Apple private keys or production credentials.
