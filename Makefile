SHELL := /bin/bash
.DEFAULT_GOAL := build

IOS_DIR ?= ios
PROJECT ?= HookahBoss.xcodeproj
SCHEME ?= HookahBoss
CONFIGURATION ?= Debug
DESTINATION ?= platform=iOS Simulator,name=iPhone 17 Pro
BUILD_DESTINATION ?= generic/platform=iOS
DERIVED_DATA_PATH ?= $(CURDIR)/build/DerivedData
ARCHIVE_PATH ?= $(CURDIR)/build/HookahBoss.xcarchive
BUNDLE ?= bundle

.PHONY: bootstrap generate build test ui-test lint archive release backend-check verify

bootstrap:
	@missing=""; for tool in xcodegen swiftgen swiftlint; do command -v $$tool >/dev/null || missing="$$missing $$tool"; done; if [[ -n "$$missing" ]]; then command -v brew >/dev/null || { echo "Homebrew is required to install:$$missing" >&2; exit 1; }; brew install $$missing; fi
	command -v $(BUNDLE) >/dev/null
	$(BUNDLE) config set --local path vendor/bundle
	$(BUNDLE) install

generate:
	mkdir -p $(IOS_DIR)/HookahBoss/Generated
	cd $(IOS_DIR) && swiftgen config run --config swiftgen.yml
	perl -pi -e 's/[ \t]+$$//' $(IOS_DIR)/HookahBoss/Generated/*.swift
	cd $(IOS_DIR) && xcodegen generate

build: generate
	xcodebuild -project $(IOS_DIR)/$(PROJECT) -scheme $(SCHEME) -configuration $(CONFIGURATION) -destination '$(BUILD_DESTINATION)' -derivedDataPath '$(DERIVED_DATA_PATH)' CODE_SIGNING_ALLOWED=NO build

test: generate
	xcodebuild -project $(IOS_DIR)/$(PROJECT) -scheme $(SCHEME) -configuration $(CONFIGURATION) -destination '$(DESTINATION)' -derivedDataPath '$(DERIVED_DATA_PATH)' -only-testing:HookahBossTests test

ui-test: generate
	xcodebuild -project $(IOS_DIR)/$(PROJECT) -scheme $(SCHEME) -configuration $(CONFIGURATION) -destination '$(DESTINATION)' -derivedDataPath '$(DERIVED_DATA_PATH)' -only-testing:HookahBossUITests test

lint:
	cd $(IOS_DIR) && swiftlint lint --strict --no-cache --config .swiftlint.yml

archive: generate
	cd $(IOS_DIR) && SCHEME='$(SCHEME)' CONFIGURATION=Release BUILD_DESTINATION='$(BUILD_DESTINATION)' DERIVED_DATA_PATH='$(DERIVED_DATA_PATH)' ARCHIVE_PATH='$(ARCHIVE_PATH)' $(BUNDLE) exec fastlane ios archive

release: generate
	cd $(IOS_DIR) && SCHEME='$(SCHEME)' DERIVED_DATA_PATH='$(DERIVED_DATA_PATH)' ARCHIVE_PATH='$(ARCHIVE_PATH)' $(BUNDLE) exec fastlane ios release

backend-check:
	cd backend && npm run check

verify: lint build test backend-check
