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

.PHONY: go-lint
go-lint: ## Verifies `golint` passes
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	$(call go-install,$(LOCAL_BIN)/golangci-lint,github.com/golangci/golangci-lint/cmd/golangci-lint@v1.26.0)
	@bin/golangci-lint run --timeout 5m

.PHONY: kio-go-cache
kio-go-cache: ## Verifies `golint` passes
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	mkdir -p /shared/operator-sdk.$(OPERATOR_VERSION)/go/{bin,testbin,.cache}
	ln -s /shared/operator-sdk.$(OPERATOR_VERSION)/go/bin/ bin
	ln -s /shared/operator-sdk.$(OPERATOR_VERSION)/go/testbin/ testbin
	ln -s /shared/operator-sdk.$(OPERATOR_VERSION)/go/ ~/go
	ln -s /shared/operator-sdk.$(OPERATOR_VERSION)/go/.cache/ ~/.cache
