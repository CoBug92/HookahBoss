fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios generate

```sh
[bundle exec] fastlane ios generate
```

Generate Swift resources and the Xcode project

### ios lint

```sh
[bundle exec] fastlane ios lint
```

Run strict SwiftLint

### ios test

```sh
[bundle exec] fastlane ios test
```

Run unit and architecture tests

### ios build

```sh
[bundle exec] fastlane ios build
```

Build without code signing

### ios archive

```sh
[bundle exec] fastlane ios archive
```

Create a local archive without uploading

### ios release

```sh
[bundle exec] fastlane ios release
```

Create a signed App Store IPA locally without uploading

### ios deploy

```sh
[bundle exec] fastlane ios deploy
```

Increment the build, sign with match and upload to TestFlight

### ios deploy_to_tf

```sh
[bundle exec] fastlane ios deploy_to_tf
```

Alias for deploy

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
