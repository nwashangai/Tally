.PHONY: dev dev-web dev-macos dev-android dev-ios build build-web build-apk build-appbundle build-ios test test-coverage gate format analyze clean help

help:
	@echo "Tally Engineering Commands:"
	@echo "  make dev             - Run local development server (Chrome / Web on port 3000)"
	@echo "  make dev-macos       - Run macOS desktop development"
	@echo "  make dev-android     - Run Android emulator/device development"
	@echo "  make dev-ios         - Run iOS simulator/device development"
	@echo "  make build           - Build Web/PWA production bundle"
	@echo "  make build-web       - Build Web/PWA production bundle"
	@echo "  make build-apk       - Build Android release APK"
	@echo "  make build-appbundle - Build Android release App Bundle"
	@echo "  make build-ios       - Build iOS release bundle"
	@echo "  make test            - Run all unit and widget tests"
	@echo "  make test-coverage   - Run tests and generate coverage report"
	@echo "  make gate            - Run complete Quality Gate audit (format, analyze, test)"
	@echo "  make format          - Format all Dart source files"
	@echo "  make analyze         - Run static analysis"
	@echo "  make clean           - Clean build cache and restore packages (flutter clean -> flutter pub get)"
	@echo "  make rebuild         - Clean cache, resolve packages, and launch dev environment"
	@echo "  make rebuild-android - Clean cache, resolve packages, and rebuild/launch Android"
	@echo "  make rebuild-ios     - Clean cache, resolve packages, and rebuild/launch iOS"
	@echo "  make rebuild-web     - Clean cache, resolve packages, and rebuild/launch Web"


dev:
	@./scripts/dev.sh $(ARGS)

dev-web:
	@./scripts/dev.sh --web $(ARGS)

dev-macos:
	@./scripts/dev.sh --macos $(ARGS)

dev-android:
	@./scripts/dev.sh --android $(ARGS)

dev-ios:
	@./scripts/dev.sh --ios $(ARGS)

build: build-web

build-web:
	@./scripts/build.sh web

build-apk:
	@./scripts/build.sh apk

build-appbundle:
	@./scripts/build.sh appbundle

build-ios:
	@./scripts/build.sh ios

test:
	@./scripts/test.sh

test-coverage:
	@./scripts/test.sh --coverage

gate:
	@./scripts/gate.sh

format:
	@dart format .

analyze:
	@dart analyze

clean:
	@./scripts/clean.sh

rebuild: clean dev

rebuild-android: clean dev-android

rebuild-ios: clean dev-ios

rebuild-web: clean dev-web

