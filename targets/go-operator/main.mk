##@ Go

# go-install will 'go install' any package $2 to $1.
define go-install
@[ -f $(1) ] || { \
set -e ;\
TMP_DIR=$$(mktemp -d) ;\
cd $$TMP_DIR ;\
go mod init tmp ;\
echo "Downloading $(2)" ;\
GOBIN=$(shell dirname $$(realpath $(1))) go install $(2) ;\
rm -rf $$TMP_DIR ;\
}
endef

.PHONY: go-lint-install
go-lint-install: ## Install go linter package
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	$(call go-install,$(LOCAL_BIN)/golangci-lint,github.com/golangci/golangci-lint/cmd/golangci-lint@v1.53.3)

.PHONY: go-lint
go-lint: go-lint-install ## Verifies `golint` passes
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	$(LOCAL_BIN)/golangci-lint run --verbose

.PHONY: kio-go-cache
kio-go-cache: ## Verifies `golint` passes
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	mkdir -p /shared/$(ARCH)/operator-sdk.$(OPERATOR_VERSION)/go/{bin,testbin,.cache}
	test -h $${HOME:-~}/go || ln -s /shared/$(ARCH)/operator-sdk.$(OPERATOR_VERSION)/go/ $${HOME:-~}/go
	test -h bin || ln -s /shared/$(ARCH)/operator-sdk.$(OPERATOR_VERSION)/go/bin/ bin
	test -h testbin || ln -s /shared/$(ARCH)/operator-sdk.$(OPERATOR_VERSION)/go/testbin/ testbin
	test -h $${HOME:-~}/.cache || ln -s /shared/$(ARCH)/operator-sdk.$(OPERATOR_VERSION)/go/.cache/ $${HOME:-~}/.cache
