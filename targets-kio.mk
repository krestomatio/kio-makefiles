##@ Testing deploy

testing-deploy: testing-image testing-deploy-prepare testing-deploy-apply-safe testing-deploy-samples-safe ## Test deployment using kustomize

testing-deploy-prepare: IMG = $(BUILD_IMAGE_TAG_BASE):$(BUILD_VERSION)
testing-deploy-prepare:
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
	cd config/testing/rook-nfs/operator; \
	kustomize edit set namespace ${TEST_OPERATOR_NAMESPACE}
	cd config/testing/rook-nfs/server; \
	kustomize edit set namespace ${TEST_OPERATOR_NAMESPACE}

testing-deploy-apply-safe:
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@$(MAKE) testing-deploy-apply || { $(MAKE) testing-undeploy; exit 2; }

testing-deploy-apply:
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	kustomize build config/testing/rook-nfs/operator | kubectl apply -f -
	kustomize build config/testing/rook-nfs/server | kubectl apply -f -
	kustomize build config/testing/nfs | kubectl apply -f -
	kustomize build config/testing/keydb | kubectl apply -f -
	kustomize build config/testing/m4e | kubectl apply -f -
	kustomize build --load-restrictor LoadRestrictionsNone config/testing | kubectl apply -f -

testing-deploy-samples-safe:
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@$(MAKE) testing-deploy-samples || { $(MAKE) testing-undeploy; exit 2; }

testing-deploy-samples:
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	kustomize build config/samples | kubectl apply -f -
	kubectl wait --for=condition=ready --timeout=600s Site site-sample

testing-undeploy: testing-undeploy-samples testing-undeploy-delete testing-undeploy-restore ## Test undeployment using kustomize

testing-undeploy-samples:
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	kustomize build config/samples | kubectl delete --ignore-not-found=true --timeout=600s --wait=true --cascade=foreground -f - || echo

testing-undeploy-delete:
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	kustomize build --load-restrictor LoadRestrictionsNone config/testing | kubectl delete --ignore-not-found=true -f - || echo
	kustomize build config/testing/nfs | kubectl delete --ignore-not-found=true -f - || echo
	kustomize build config/testing/keydb | kubectl delete --ignore-not-found=true -f - || echo
	kustomize build config/testing/m4e | kubectl delete --ignore-not-found=true -f - || echo
	kustomize build config/testing/rook-nfs/server | kubectl delete --ignore-not-found=true -f - || echo
	kustomize build config/testing/rook-nfs/operator | kubectl delete --ignore-not-found=true -f - || echo

testing-undeploy-restore:
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
	cd config/testing/rook-nfs/operator; \
	kustomize edit set namespace kio-test
	cd config/testing/rook-nfs/server; \
	kustomize edit set namespace kio-test

##@ Dependant operators

deploy-operators: ## Deploy kio operator and dependant operators to the K8s cluster specified in ~/.kube/config.
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	cd config/manager && kustomize edit set image controller=${IMG}
	kustomize build config/operators | kubectl apply -f -

undeploy-operators: ## Undeploy kio operator and dependant operators from the K8s cluster specified in ~/.kube/config.
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	kustomize build config/operators | kubectl delete --ignore-not-found=true -f -
