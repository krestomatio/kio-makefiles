##@ Go

# go-install will 'go install' any package $2 to $1.
define go-install
@[ -f $(1) ] || { \
set -e ;\
TMP_DIR=$$(mktemp -d) ;\
cd $$TMP_DIR ;\
go mod init tmp ;\
echo "Downloading $(2)" ;\
GOBIN=$${GOBIN:-$(shell dirname $$(realpath -m $(1)))} go install $(2) ;\
rm -rf $$TMP_DIR ;\
}
endef

.PHONY: go-lint-install
go-lint-install: ## Install go linter package
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	$(call go-install,$(LOCALBIN)/golangci-lint,github.com/golangci/golangci-lint/cmd/golangci-lint@v$(GO_LINT_VERSION))

.PHONY: go-lint
go-lint: go-lint-install ## Verifies `golint` passes
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	$(LOCALBIN)/golangci-lint run --verbose
