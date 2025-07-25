# iframe-dashboard - Makefile

##@ Project Configuration
# ------------------------------------------------------------------------------
PROJECT_NAME := iframe-dashboard
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
BUILD_TIME := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
GO_VERSION := $(shell go version | awk '{print $$3}')

# Binary and build configuration
BINARY_NAME := iframe-dashboard
BUILD_DIR := ./build

# Docker configuration
DOCKER_REGISTRY := release.daocloud.io/ndx-product
DOCKER_IMAGE := $(DOCKER_REGISTRY)/iframe-dashboard
DOCKER_TAG ?= $(shell echo $${DOCKER_TAG:-v0.1.2})

# Go build flags
LDFLAGS := -ldflags "-X main.version=$(VERSION) -X main.buildTime=$(BUILD_TIME) -X main.goVersion=$(GO_VERSION)"

# Terminal colors for output formatting
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
PURPLE := \033[0;35m
CYAN := \033[0;36m
NC := \033[0m

##@ General
.PHONY: help
help: ## Display available commands
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Development
.PHONY: fmt
fmt: ## Format Go code with goimports
	@echo "$(BLUE)Formatting Go code...$(NC)"
	@if ! command -v goimports >/dev/null 2>&1; then \
		echo "$(YELLOW)Installing goimports...$(NC)"; \
		cd backend/ && go install golang.org/x/tools/cmd/goimports@latest; \
	fi
	@cd backend/ && goimports -w -local iframe-dashboard-backend .
	@echo "$(GREEN)Code formatting completed$(NC)"

.PHONY: lint
lint: ## Run golangci-lint code analysis
	@echo "$(BLUE)Running code analysis...$(NC)"
	@if ! command -v golangci-lint >/dev/null 2>&1; then \
		echo "$(YELLOW)Installing golangci-lint...$(NC)"; \
		curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $$(go env GOPATH)/bin v1.55.2; \
	fi
	@cd backend/ && golangci-lint run
	@echo "$(GREEN)Code analysis completed$(NC)"

.PHONY: lint-fix
lint-fix: ## Run golangci-lint with auto-fix
	@echo "$(BLUE)Running code analysis with auto-fix...$(NC)"
	@if ! command -v golangci-lint >/dev/null 2>&1; then \
		echo "$(YELLOW)Installing golangci-lint...$(NC)"; \
		curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $$(go env GOPATH)/bin v1.55.2; \
	fi
	@cd backend/ && golangci-lint run --fix
	@echo "$(GREEN)Code analysis and fixes completed$(NC)"

.PHONY: debug
debug: ## Run application in debug mode
	@if [ ! -f backend/.env ]; then \
		echo "$(RED)Warning: backend/.env file not found, using default config$(NC)"; \
		echo "$(BLUE)Running application in debug mode...$(NC)"; \
		cd backend/ && go run .; \
	else \
		echo "$(BLUE)Running application in debug mode...$(NC)"; \
		cd backend/ && export $$(cat .env | grep -v '^#' | xargs) && go run .; \
	fi
	@echo "$(GREEN)Application exited$(NC)"

##@ Build
.PHONY: build
build: ## Build binary for production
	@echo "$(BLUE)Building Go binary...$(NC)"
	@mkdir -p $(BUILD_DIR)
	@cd backend/ && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build $(LDFLAGS) -o ../$(BUILD_DIR)/$(BINARY_NAME) .
	@echo "$(GREEN)Build completed: $(BUILD_DIR)/$(BINARY_NAME)$(NC)"

##@ Testing
.PHONY: test
test: ## Run Go tests with race detection
	@echo "$(BLUE)Running Go tests...$(NC)"
	@cd backend/ && go test -v -race -timeout=30s ./...
	@echo "$(GREEN)Tests completed$(NC)"

.PHONY: test-coverage
test-coverage: ## Run tests with coverage report
	@echo "$(BLUE)Running tests with coverage report...$(NC)"
	@cd backend/ && go test -v -race -timeout=30s -coverprofile=coverage.out ./...
	@cd backend/ && go tool cover -html=coverage.out -o coverage.html
	@echo "$(GREEN)Coverage report generated: backend/coverage.html$(NC)"

.PHONY: test-short
test-short: ## Run short tests (skip long-running tests)
	@echo "$(BLUE)Running short tests...$(NC)"
	@cd backend/ && go test -v -race -short -timeout=10s ./...
	@echo "$(GREEN)Short tests completed$(NC)"

.PHONY: test-bench
test-bench: ## Run benchmark tests
	@echo "$(BLUE)Running benchmark tests...$(NC)"
	@cd backend/ && go test -v -bench=. -benchmem ./...
	@echo "$(GREEN)Benchmark tests completed$(NC)"

##@ Quality Assurance
.PHONY: check
check: fmt lint test ## Run complete quality checks (format + lint + test)
	@echo "$(GREEN)All quality checks passed!$(NC)"

.PHONY: ci
ci: ## Run CI checks (read-only validation)
	@echo "$(BLUE)Running CI checks...$(NC)"
	@echo "$(CYAN)1. Checking code format...$(NC)"
	@cd backend/ && goimports -l . | grep -q . && echo "$(RED)Code format issues found, run 'make fmt'$(NC)" && exit 1 || echo "$(GREEN)Code format check passed$(NC)"
	@echo "$(CYAN)2. Running code analysis...$(NC)"
	@cd backend/ && golangci-lint run
	@echo "$(CYAN)3. Running tests...$(NC)"
	@cd backend/ && go test -v -race -timeout=30s ./...
	@echo "$(GREEN)All CI checks passed!$(NC)"

##@ Setup
.PHONY: install-hooks
install-hooks: ## Install Git pre-commit hooks
	@echo "$(BLUE)Installing Git hooks...$(NC)"
	@./scripts/install-hooks.sh
	@echo "$(GREEN)Git hooks installation completed$(NC)"

##@ Cleanup
.PHONY: clean
clean: ## Clean build artifacts and test outputs
	@echo "$(BLUE)Cleaning build artifacts and test outputs...$(NC)"
	@rm -rf $(BUILD_DIR)
	@cd backend/ && rm -f coverage.out coverage.html
	@echo "$(GREEN)Cleanup completed$(NC)"

.PHONY: clean-all
clean-all: clean frontend-clean ## Clean all build artifacts (including frontend)
	@echo "$(GREEN)All build artifacts cleaned$(NC)"

##@ Frontend Development
.PHONY: frontend-install
frontend-install: ## Install frontend dependencies
	@echo "$(BLUE)Installing frontend dependencies...$(NC)"
	@cd frontend/ && npm install
	@echo "$(GREEN)Frontend dependencies installation completed$(NC)"

.PHONY: frontend-dev
frontend-dev: ## Start frontend development server
	@echo "$(BLUE)Starting frontend development server...$(NC)"
	@cd frontend/ && npm run serve

.PHONY: frontend-build
frontend-build: ## Build frontend for production
	@echo "$(BLUE)Building frontend for production...$(NC)"
	@cd frontend/ && npm run build
	@echo "$(GREEN)Frontend build completed$(NC)"

.PHONY: frontend-lint
frontend-lint: ## Lint frontend code
	@echo "$(BLUE)Linting frontend code...$(NC)"
	@cd frontend/ && npm run lint
	@echo "$(GREEN)Frontend code linting completed$(NC)"

.PHONY: frontend-clean
frontend-clean: ## Clean frontend build artifacts and dependencies
	@echo "$(BLUE)Cleaning frontend build artifacts and dependencies...$(NC)"
	@cd frontend/ && rm -rf node_modules dist
	@echo "$(GREEN)Frontend cleanup completed$(NC)"

##@ Docker Operations
.PHONY: docker-backend
docker-backend: ## Build backend Docker image
	@echo "$(BLUE)Building backend Docker image: $(DOCKER_IMAGE):$(DOCKER_TAG)$(NC)"
	@cd backend/ && docker build -t $(DOCKER_IMAGE):$(DOCKER_TAG) .
	@echo "$(GREEN)Backend Docker image build completed: $(DOCKER_IMAGE):$(DOCKER_TAG)$(NC)"

.PHONY: docker-frontend
docker-frontend: ## Build frontend Docker image
	@echo "$(BLUE)Building frontend Docker image: $(DOCKER_REGISTRY)/iframe-dashboard-frontend:$(DOCKER_TAG)$(NC)"
	@cd frontend/ && docker build -t $(DOCKER_REGISTRY)/iframe-dashboard-frontend:$(DOCKER_TAG) .
	@echo "$(GREEN)Frontend Docker image build completed: $(DOCKER_REGISTRY)/iframe-dashboard-frontend:$(DOCKER_TAG)$(NC)"

##@ Deployment
.PHONY: build-all
build-all: frontend-build docker-backend docker-frontend ## Build all components (frontend static files + Docker images)
	@echo "$(GREEN)All components build completed$(NC)"

.PHONY: build-push-backend
build-push-backend: docker-backend ## Build and push backend image
	@echo "$(BLUE)Pushing backend Docker image: $(DOCKER_IMAGE):$(DOCKER_TAG)$(NC)"
	@docker push $(DOCKER_IMAGE):$(DOCKER_TAG)
	@echo "$(GREEN)Backend image push completed: $(DOCKER_IMAGE):$(DOCKER_TAG)$(NC)"

.PHONY: build-push-frontend
build-push-frontend: docker-frontend ## Build and push frontend image
	@echo "$(BLUE)Pushing frontend Docker image: $(DOCKER_REGISTRY)/iframe-dashboard-frontend:$(DOCKER_TAG)$(NC)"
	@docker push $(DOCKER_REGISTRY)/iframe-dashboard-frontend:$(DOCKER_TAG)
	@echo "$(GREEN)Frontend image push completed: $(DOCKER_REGISTRY)/iframe-dashboard-frontend:$(DOCKER_TAG)$(NC)"

.PHONY: build-push-all
build-push-all: ## Build and push all images in parallel
	@echo "$(BLUE)Starting parallel build and push for all images...$(NC)"
	@$(MAKE) -j2 build-push-backend build-push-frontend
	@echo "$(GREEN)All images parallel build and push completed$(NC)"
	@echo "$(PURPLE)Backend image: $(DOCKER_IMAGE):$(DOCKER_TAG)$(NC)"
	@echo "$(PURPLE)Frontend image: $(DOCKER_REGISTRY)/iframe-dashboard-frontend:$(DOCKER_TAG)$(NC)"

.DEFAULT_GOAL := help