SHELL := /bin/bash
.DEFAULT_GOAL := build

PROJECT ?= HookahBoss.xcodeproj
SCHEME ?= HookahBoss
CONFIGURATION ?= Debug
DESTINATION ?= platform=iOS Simulator,name=iPhone 17 Pro
BUILD_DESTINATION ?= generic/platform=iOS
DERIVED_DATA_PATH ?= $(CURDIR)/.build/DerivedData
ARCHIVE_PATH ?= $(CURDIR)/.build/Mixery.xcarchive
RBENV ?= $(shell command -v rbenv 2>/dev/null)
BUNDLE ?= $(if $(RBENV),$(RBENV) exec bundle,bundle)

.PHONY: bootstrap generate build test ui-test lint archive release deploy backend-check verify

bootstrap:
	@missing=""; for tool in xcodegen swiftgen swiftlint; do command -v $$tool >/dev/null || missing="$$missing $$tool"; done; if [[ -n "$$missing" ]]; then command -v brew >/dev/null || { echo "Homebrew is required to install:$$missing" >&2; exit 1; }; brew install $$missing; fi
	$(BUNDLE) config set --local path vendor/bundle
	$(BUNDLE) install

generate:
	./scripts/swiftgen/run
	./scripts/xcodegen/run

build: generate
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration $(CONFIGURATION) -destination '$(BUILD_DESTINATION)' -derivedDataPath '$(DERIVED_DATA_PATH)' CODE_SIGNING_ALLOWED=NO build

test: generate
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration $(CONFIGURATION) -destination '$(DESTINATION)' -derivedDataPath '$(DERIVED_DATA_PATH)' -only-testing:HookahBossTests test

ui-test: generate
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration $(CONFIGURATION) -destination '$(DESTINATION)' -derivedDataPath '$(DERIVED_DATA_PATH)' -only-testing:HookahBossUITests test

lint:
	./scripts/swiftlint/run

archive: generate
	cd scripts && SCHEME='$(SCHEME)' CONFIGURATION=Release BUILD_DESTINATION='$(BUILD_DESTINATION)' DERIVED_DATA_PATH='$(DERIVED_DATA_PATH)' ARCHIVE_PATH='$(ARCHIVE_PATH)' $(BUNDLE) exec fastlane ios archive

release: generate
	cd scripts && SCHEME='$(SCHEME)' DERIVED_DATA_PATH='$(DERIVED_DATA_PATH)' ARCHIVE_PATH='$(ARCHIVE_PATH)' $(BUNDLE) exec fastlane ios release

deploy: generate
	cd scripts && SCHEME='$(SCHEME)' DERIVED_DATA_PATH='$(DERIVED_DATA_PATH)' ARCHIVE_PATH='$(ARCHIVE_PATH)' $(BUNDLE) exec fastlane ios deploy

backend-check:
	cd ../backend && npm run check

verify: lint build test backend-check
