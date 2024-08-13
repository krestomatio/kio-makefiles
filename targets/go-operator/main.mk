include $(MK_TARGETS_DIR)/go/main.mk

.PHONY: go-crd-ref-docs-install
go-crd-ref-docs-install: ## Install go crd-ref-docs package
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	$(call go-install,$(LOCALBIN)/crd-ref-docs,github.com/elastic/crd-ref-docs@v$(CRD_REF_DOCS_VERSION))

.PHONY: gen-api-docs
gen-api-docs: go-crd-ref-docs-install ## Generate api docs
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	sed -i "s@kubernetesVersion:.*@kubernetesVersion: $(K8S_VERSION)@" config/docs/go-crd-ref-docs.yaml
	$(LOCALBIN)/crd-ref-docs \
		--source-path=./api \
		--renderer=markdown \
		--config=config/docs/go-crd-ref-docs.yaml \
		--output-path=docs/api.md

.PHONY: go-operator-cache
go-operator-cache: ## Configure go operator cache
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	mkdir -p /shared/$(ARCH)/operator-sdk.$(OPERATOR_VERSION)/go/{bin,testbin,.cache}
	test -h $${HOME:-~}/go || ln -s /shared/$(ARCH)/operator-sdk.$(OPERATOR_VERSION)/go/ $${HOME:-~}/go
	test -h bin || ln -s /shared/$(ARCH)/operator-sdk.$(OPERATOR_VERSION)/go/bin/ bin
	test -h testbin || ln -s /shared/$(ARCH)/operator-sdk.$(OPERATOR_VERSION)/go/testbin/ testbin
	test -h $${HOME:-~}/.cache || ln -s /shared/$(ARCH)/operator-sdk.$(OPERATOR_VERSION)/go/.cache/ $${HOME:-~}/.cache
