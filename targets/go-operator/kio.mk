##@ Testing deploy

KIND_CLUSTER_NAME ?= kio-operator
KIND_NAMESPACE ?= site-sample

.PHONY: local-install
local-install: kustomize kubectl kind-create kind-context deploy-csi-nfs deploy-operators install ## Install a local dev env

.PHONY: local-uninstall
local-uninstall: uninstall undeploy-operators undeploy-csi-nfs ## Uninstall the local dev env

.PHONY: local-purge
local-purge: kind-delete ## Purge the local dev env

.PHONY: testing-deploy
testing-deploy: testing-image testing-deploy-prepare testing-deploy-apply-safe testing-deploy-samples-safe ## Test deployment using kustomize

.PHONY: testing-deploy-prepare
testing-deploy-prepare: IMG = $(BUILD_IMAGE_TAG_BASE):$(BUILD_VERSION)
testing-deploy-prepare: ## Test deployment preparation
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	cd config/testing; \
	kustomize edit set image testing=${OPERATOR_IMAGE}; \
	kustomize edit set namespace ${TEST_OPERATOR_NAMESPACE}; \
	kustomize edit set nameprefix ${TEST_OPERATOR_NAMEPREFIX}
	cd config/testing/m4e; \
	kustomize edit set namespace ${TEST_OPERATOR_NAMESPACE}; \
	kustomize edit set nameprefix ${TEST_OPERATOR_NAMEPREFIX}
	cd config/testing/keydb; \
	kustomize edit set namespace ${TEST_OPERATOR_NAMESPACE}; \
	kustomize edit set nameprefix ${TEST_OPERATOR_NAMEPREFIX}
	cd config/testing/nfs; \
	kustomize edit set namespace ${TEST_OPERATOR_NAMESPACE}; \
	kustomize edit set nameprefix ${TEST_OPERATOR_NAMEPREFIX}
	cd config/testing/postgres; \
	kustomize edit set namespace ${TEST_OPERATOR_NAMESPACE}; \
	kustomize edit set nameprefix ${TEST_OPERATOR_NAMEPREFIX}

.PHONY: testing-deploy-apply-safe
testing-deploy-apply-safe: ## Try test deployment operators
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@$(MAKE) testing-deploy-apply || { $(MAKE) testing-undeploy; exit 2; }

.PHONY: testing-deploy-apply
testing-deploy-apply: ## Test deployment operators
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	kustomize build config/testing/postgres | sed -e "s@${TEST_OPERATOR_NAMEPREFIX}postgres-operator@${TEST_OPERATOR_NAMEPREFIX}postgres@" | kubectl apply -f -
	kustomize build config/testing/nfs | sed -e "s@${TEST_OPERATOR_NAMEPREFIX}nfs-operator@${TEST_OPERATOR_NAMEPREFIX}nfs@" | kubectl apply -f -
	kustomize build config/testing/keydb | sed -e "s@${TEST_OPERATOR_NAMEPREFIX}keydb-operator@${TEST_OPERATOR_NAMEPREFIX}keydb@" | kubectl apply -f -
	kustomize build config/testing/m4e | sed -e "s@${TEST_OPERATOR_NAMEPREFIX}m4e-operator@${TEST_OPERATOR_NAMEPREFIX}m4e@" | kubectl apply -f -
	kustomize build --load-restrictor LoadRestrictionsNone config/testing | kubectl apply -f -

.PHONY: testing-deploy-samples-safe
testing-deploy-samples-safe: ## Try test deployment samples
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@$(MAKE) testing-deploy-samples || { $(MAKE) testing-manager-logs testing-undeploy; exit 2; }

.PHONY: testing-deploy-samples
testing-deploy-samples: ## Test deployment samples
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	kustomize build config/samples | kubectl apply -f -
	kubectl wait --for=condition=ready --timeout=600s Site site-sample

.PHONY: testing-undeploy
testing-undeploy: testing-undeploy-samples testing-undeploy-delete testing-undeploy-restore ## Test undeployment using kustomize

.PHONY: testing-undeploy-samples
testing-undeploy-samples: ## Test undeployment samples
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	kustomize build config/samples | kubectl delete --ignore-not-found=true --wait=true --timeout=600s -f - || echo

.PHONY: testing-manager-logs
testing-manager-logs: ## Output logs from all managers in namespace
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	kubectl -n ${TEST_OPERATOR_NAMESPACE} logs -l control-plane=controller-manager -c manager --tail=-1 --limit-bytes=10240000

.PHONY: testing-undeploy-delete
testing-undeploy-delete: ## Test undeployment delete operators
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	kustomize build --load-restrictor LoadRestrictionsNone config/testing | kubectl delete --ignore-not-found=true --timeout=600s -f - || echo
	kustomize build config/testing/m4e | sed -e "s@${TEST_OPERATOR_NAMEPREFIX}m4e-operator@${TEST_OPERATOR_NAMEPREFIX}m4e@" | kubectl delete --ignore-not-found=true --timeout=600s -f - || echo
	kustomize build config/testing/keydb | sed -e "s@${TEST_OPERATOR_NAMEPREFIX}keydb-operator@${TEST_OPERATOR_NAMEPREFIX}keydb@" | kubectl delete --ignore-not-found=true --timeout=600s -f - || echo
	kustomize build config/testing/nfs | sed -e "s@${TEST_OPERATOR_NAMEPREFIX}nfs-operator@${TEST_OPERATOR_NAMEPREFIX}nfs@" | kubectl delete --ignore-not-found=true --timeout=600s -f - || echo
	kustomize build config/testing/postgres | sed -e "s@${TEST_OPERATOR_NAMEPREFIX}postgres-operator@${TEST_OPERATOR_NAMEPREFIX}postgres@" | kubectl delete --ignore-not-found=true --timeout=600s -f - || echo
	# in case sc remains
	kubectl delete --ignore-not-found=true sc site-site-sample-nfs-sc || echo

.PHONY: testing-undeploy-restore
testing-undeploy-restore: ## Test undeployment restore files
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	cd config/testing; \
	kustomize edit set image testing=testing-operator; \
	kustomize edit set namespace kio-test; \
	kustomize edit set nameprefix kio-
	cd config/testing/m4e; \
	kustomize edit set namespace kio-test; \
	kustomize edit set nameprefix kio-
	cd config/testing/keydb; \
	kustomize edit set namespace kio-test; \
	kustomize edit set nameprefix kio-
	cd config/testing/nfs; \
	kustomize edit set namespace kio-test; \
	kustomize edit set nameprefix kio-
	cd config/testing/postgres; \
	kustomize edit set namespace kio-test; \
	kustomize edit set nameprefix kio-

##@ Dependant operators

.PHONY: deploy-operators
deploy-operators: ## Deploy kio operator and dependant operators to the K8s cluster specified in ~/.kube/config.
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	cd config/manager && kustomize edit set image controller=${IMG}
	kustomize build config/operators | kubectl apply -f -

.PHONY: undeploy-operators
undeploy-operators: ## Undeploy kio operator and dependant operators from the K8s cluster specified in ~/.kube/config.
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	kustomize build config/operators | kubectl delete --ignore-not-found=true --timeout=600s -f -
