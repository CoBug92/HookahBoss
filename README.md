# HookahBoss

Native iOS application and its API live in one repository, with platform code kept in separate top-level directories.

## Repository map

| Path | Purpose |
|---|---|
| `ios/` | SwiftUI application, Xcode project, unit/UI tests, localizations and iOS project specification |
| `backend/` | Node.js/TypeScript API, PostgreSQL migrations, seeds, content refreshers and backend tests |
| `scripts/` | Repository-level deployment and environment-status scripts |
| `docker-compose.yml` | Local backend/PostgreSQL environment |
| `compose.device-test.yaml` | Isolated VDS device-test environment |
| `PRODUCT.md` | Shared product specification |
| `MVP_AUDIT.md` | Evidence-based implementation audit |
| `RELEASE_CHECKLIST.md` | Cross-platform release gates |
| `DEVICE_TEST.md` | Device-test deployment runbook |

## iOS

Open `ios/HookahBoss.xcodeproj` in Xcode, or build from the repository root:

```sh
xcodebuild -project ios/HookahBoss.xcodeproj -scheme HookahBoss \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
```

The checked-in Xcode project and typed resources are generated from `ios/project.yml` and `ios/swiftgen.yml`. See [`ios/README.md`](ios/README.md) for architecture, tooling and Fastlane details. Regenerate them from the repository root:

```sh
make generate
```

## Backend

```sh
cd backend
npm ci
npm run check
```

After dependencies are installed, the same check is available from the root as `make backend-check`. `make verify` runs lint, iOS build/tests and the backend check.

For the local Compose environment:

```sh
docker compose up --build
```

Local secrets belong in ignored `.env` files. Start with `backend/.env.example`; never commit Apple private keys or production credentials.
