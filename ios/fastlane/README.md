# Fastlane

Run from `ios/` through the pinned Bundler environment:

```sh
make archive
make release
make deploy
```

`archive` creates an archive without upload. `release` creates a signed local App Store IPA. `deploy` is allowed only from `master`, reads App Store Connect credentials from the environment, synchronizes read-only signing assets with match, increments the TestFlight build number without editing tracked files, and uploads the resulting build.

Required release variables are documented in `../scripts/.env.example`; never commit their values.
