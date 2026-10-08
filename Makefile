SHELL := /bin/bash
.DEFAULT_GOAL := help

WORKSPACE := OmniKeys.xcworkspace
SCHEME := OmniKeys
DERIVED := build/DerivedData
XCODEBUILD := xcodebuild -workspace $(WORKSPACE) -scheme $(SCHEME) -destination 'platform=macOS' -derivedDataPath $(DERIVED)
DEBUG_APP := $(DERIVED)/Build/Products/Debug/OmniKeys.app

# GitHub Actions sets CI=true: treat warnings as errors there.
ifdef CI
XCODE_FLAGS += SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
endif

.PHONY: help bootstrap generate build test lint format run render clean

help: ## Show this help
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-12s %s\n", $$1, $$2}'

bootstrap: ## Install Tuist (mise) and SwiftFormat/SwiftLint (Homebrew), then generate the project
	mise install
	brew install --quiet swiftformat swiftlint
	$(MAKE) generate

generate: ## Generate OmniKeys.xcworkspace from Project.swift
	mise exec -- tuist generate --no-open

build: generate ## Debug build
	$(XCODEBUILD) -configuration Debug -quiet build $(XCODE_FLAGS)

test: generate ## Run all tests
	$(XCODEBUILD) -configuration Debug -quiet test $(XCODE_FLAGS)

lint: ## Check formatting and lint rules
	swiftformat --lint .
	swiftlint lint --strict --quiet

format: ## Apply formatting and autocorrectable lint fixes
	swiftformat .
	swiftlint lint --fix --quiet

run: build ## Build and launch the debug app (quits a running copy first)
	-pkill -x OmniKeys
	open $(DEBUG_APP)

clean: ## Remove build output and generated projects
	rm -rf build Derived *.xcodeproj *.xcworkspace

render: build ## Render the fixture sheet to build/render.png
	$(DEBUG_APP)/Contents/MacOS/OmniKeys --render build/render.png --settings Tests/OmniKeysCoreTests/Fixtures/settings.toml --config /dev/null
	@echo "Wrote build/render.png"
