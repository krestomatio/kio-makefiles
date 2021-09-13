##@ Go

.PHONY: go-lint
HAS_GOLINT := $(shell which $(PROJECT_DIR)/bin/golangci-lint)
go-lint: ## Verifies `golint` passes
	@echo "+ $@"
ifndef HAS_GOLINT
	$(call go-get-tool,$(PROJECT_DIR)/bin/golangci-lint,github.com/golangci/golangci-lint/cmd/golangci-lint@v1.26.0)
endif
	@bin/golangci-lint run --timeout 5m
