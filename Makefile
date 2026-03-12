.PHONY: help plugin-install dep-build lint yamllint kubeconform lint-all test snapshot-update package clean all

# Default target
help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

## Install required tools (helm-unittest plugin, yamllint, kubeconform)
plugin-install: ## Install helm-unittest plugin and lint tools
	helm plugin install https://github.com/helm-unittest/helm-unittest --version "~1"
	@echo "Install yamllint: brew install yamllint"
	@echo "Install kubeconform: brew install kubeconform"

## Build chart dependencies (main chart + test wrapper)
dep-build: ## Build helm dependencies for main chart and test wrapper
	@echo "Building sql-database dependencies..."
	helm dependency build .
	@echo "Building test chart dependencies..."
	helm dependency build tests/chart
	@echo "Dependencies built successfully"

## Lint the chart with helm
lint: ## Lint the Helm chart with helm lint
	@echo "Linting sql-database..."
	helm lint .
	@echo ""
	@echo "Helm lint passed"

## Lint YAML files with yamllint
yamllint: ## Lint YAML files with yamllint
	@echo "Running yamllint..."
	yamllint -c .yamllint.yml .
	@echo "yamllint passed"

## Validate rendered manifests with kubeconform
kubeconform: ## Validate rendered Kubernetes manifests with kubeconform
	@echo "Running kubeconform..."
	helm template sql-database . | kubeconform --strict --ignore-missing-schemas
	@echo "kubeconform passed"

## Run all linting tools (helm lint + yamllint + kubeconform)
lint-all: lint yamllint kubeconform ## Run helm lint, yamllint, and kubeconform
	@echo ""
	@echo "All linting passed"

## Run helm-unittest tests
test: ## Run helm-unittest tests
	@if [ -n "$$(find tests/chart/tests/unit -name '*_test.yaml' 2>/dev/null | head -1)" ]; then \
		echo "Building test chart dependencies..."; \
		helm dependency build tests/chart > /dev/null 2>&1; \
		echo "Running helm-unittest tests..."; \
		helm unittest -f 'tests/unit/*.yaml' tests/chart; \
	else \
		echo "No tests found in tests/chart/tests/unit/ — skipping"; \
	fi

## Update helm-unittest snapshots
snapshot-update: ## Update helm-unittest snapshots
	@if [ -n "$$(find tests/chart/tests/unit -name '*_test.yaml' 2>/dev/null | head -1)" ]; then \
		echo "Building test chart dependencies..."; \
		helm dependency build tests/chart > /dev/null 2>&1; \
		echo "Updating helm-unittest snapshots..."; \
		helm unittest -u -f 'tests/unit/*.yaml' tests/chart; \
		echo "Snapshot update complete"; \
	else \
		echo "No tests found in tests/chart/tests/unit/ — nothing to snapshot"; \
	fi

## Package the chart into a .tgz archive
package: ## Package the chart into a versioned .tgz archive
	@echo "Packaging sql-database..."
	helm package .
	@echo "Package complete"

## Remove packaged .tgz archive
clean: ## Remove packaged .tgz archive
	@echo "Cleaning sql-database..."
	rm -f sql-database-*.tgz
	@echo "Cleanup complete"

## Run all linting and tests
all: lint-all test ## Run lint-all and test
	@echo ""
	@echo "All targets completed successfully"
