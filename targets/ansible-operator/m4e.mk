##@ M4e


testing_deploy_postgres_cr ?= https://raw.githubusercontent.com/krestomatio/postgres-operator/main/config/samples/postgres_v1alpha1_postgres.yaml

.PHONY: testing-deploy-postgres
testing-deploy-postgres: kustomize ## Deploy postgres operator for testing purposes
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifneq (destroy, $(MOLECULE_SEQUENCE))
	@ cd config/testing/postgres; \
	$(KUSTOMIZE) edit set namespace ${TEST_OPERATOR_NAMESPACE}; \
	$(KUSTOMIZE) edit set nameprefix ${TEST_OPERATOR_NAMEPREFIX}
	@$(KUSTOMIZE) build config/testing/postgres| $(KUBECTL) apply -f -
	@$(KUBECTL) -n ${TEST_OPERATOR_NAMESPACE} apply -f $(testing_deploy_postgres_cr)
	@$(KUBECTL) -n ${TEST_OPERATOR_NAMESPACE} wait --for=condition=ready --timeout=600s -f $(testing_deploy_postgres_cr)
endif

.PHONY: testing-undeploy-postgres
testing-undeploy-postgres: ## Undeploy postgres operator for testing purposes
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifeq (test, $(MOLECULE_SEQUENCE))
	@$(KUBECTL) -n ${TEST_OPERATOR_NAMESPACE} delete --ignore-not-found=true --timeout=600s -f $(testing_deploy_postgres_cr)
	@$(KUSTOMIZE) build config/testing/postgres | kubectl delete --ignore-not-found=true --timeout=600s -f - || echo
	@cd config/testing/postgres; \
	$(KUSTOMIZE) edit set namespace m4e-test; \
	$(KUSTOMIZE) edit set nameprefix m4e-
endif
