##@ Go

.PHONY: go-lint
HAS_GOLINT := $(shell which $(PROJECT_DIR)/bin/golangci-lint)
go-lint: ## Verifies `golint` passes
	@echo "+ $@"
ifndef HAS_GOLINT
	$(call go-get-tool,$(PROJECT_DIR)/bin/golangci-lint,github.com/golangci/golangci-lint/cmd/golangci-lint@v1.26.0)
endif
	@bin/golangci-lint run --timeout 5m


.PHONY: kio-go-cache
kio-go-cache: ## Verifies `golint` passes
	@echo "+ $@"
	mkdir -p /shared/operator-sdk.$(OPERATOR_VERSION)/go/{bin,testbin,.cache}
	ln -s /shared/operator-sdk.$(OPERATOR_VERSION)/go/bin/ bin
	ln -s /shared/operator-sdk.$(OPERATOR_VERSION)/go/testbin/ testbin
	ln -s /shared/operator-sdk.$(OPERATOR_VERSION)/go/ ~/go
	ln -s /shared/operator-sdk.$(OPERATOR_VERSION)/go/.cache/ ~/.cache
