.DEFAULT_GOAL := help

.PHONY: help get analyze test build-debug clean

help: ## Show this help message
	@echo "Mobile Flutter Application Make Commands"
	@echo "========================================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-16s\033[0m %s\n", $$1, $$2}'

get: ## Resolve pub dependencies
	flutter pub get

analyze: ## Run Flutter static code analysis
	flutter analyze

test: ## Run Flutter test suite
	flutter test

build-debug: ## Build debug APK for Android
	flutter build apk --debug

build-pwa: ## Build production Progressive Web App (PWA)
	flutter build web --release --no-tree-shake-icons

run-pwa: ## Run Progressive Web App locally in Chrome on port 3000
	flutter run -d chrome --web-port=3000

clean: ## Clean Flutter build artifacts
	flutter clean
