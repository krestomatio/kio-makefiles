##@ Testing deploy

KIND_CLUSTER_NAME ?= lms-moodle-operator
KIND_NAMESPACE ?= lmsmoodle-sample

.PHONY: local-install
local-install: kustomize kubectl kind-create kind-context deploy-operators install ## Install a local dev env

.PHONY: local-uninstall
local-uninstall: uninstall undeploy-operators ## Uninstall the local dev env

.PHONY: local-purge
local-purge: kind-delete delete-project-bin ## Purge the local dev env

.PHONY: gen-operators-kustomization
gen-operators-kustomization: ## Generate operators kustomization files
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	makejinja -i config/templates/operators -o config/operators -f --undefined strict \
		--jinja-suffix .j2 \
		-D moodle_operator_version=$(MOODLE_OPERATOR_VERSION) \
		-D postgres_operator_version=$(POSTGRES_OPERATOR_VERSION) \
		-D nfs_operator_version=$(NFS_OPERATOR_VERSION) \
		-D keydb_operator_version=$(KEYDB_OPERATOR_VERSION)

.PHONY: gen-bundle-dependencies
gen-bundle-dependencies: ## Generate bundle dependencies file
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	makejinja -i config/templates/metadata -o bundle/metadata -f --undefined strict \
		--jinja-suffix .j2 \
		-D moodle_operator_version=$(MOODLE_OPERATOR_VERSION) \
		-D postgres_operator_version=$(POSTGRES_OPERATOR_VERSION) \
		-D nfs_operator_version=$(NFS_OPERATOR_VERSION) \
		-D keydb_operator_version=$(KEYDB_OPERATOR_VERSION)

.PHONY: testing-deploy
testing-deploy: gen-operators-kustomization testing-deploy-prepare testing-deploy-apply-safe testing-deploy-samples-safe ## Test deployment using kustomize

.PHONY: testing-deploy-prepare
testing-deploy-prepare: ## Test deployment preparation
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	cd config/testing; \
	kustomize edit set image testing=${OPERATOR_IMAGE}; \
	kustomize edit set namespace ${TEST_OPERATOR_NAMESPACE}; \
	kustomize edit set nameprefix ${TEST_OPERATOR_NAMEPREFIX}
	cd config/testing/moodle; \
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
	kustomize build config/testing/postgres | sed -e "s@${TEST_OPERATOR_NAMEPREFIX}postgres-operator@${TEST_OPERATOR_NAMEPREFIX}postgres@" | $(KUBECTL) apply -f -
	kustomize build config/testing/nfs | sed -e "s@${TEST_OPERATOR_NAMEPREFIX}nfs-operator@${TEST_OPERATOR_NAMEPREFIX}nfs@" | $(KUBECTL) apply -f -
	kustomize build config/testing/keydb | sed -e "s@${TEST_OPERATOR_NAMEPREFIX}keydb-operator@${TEST_OPERATOR_NAMEPREFIX}keydb@" | $(KUBECTL) apply -f -
	kustomize build config/testing/moodle | sed -e "s@${TEST_OPERATOR_NAMEPREFIX}moodle-operator@${TEST_OPERATOR_NAMEPREFIX}moodle@" | $(KUBECTL) apply -f -
	kustomize build --load-restrictor LoadRestrictionsNone config/testing | $(KUBECTL) apply --server-side=true -f -
	# wait for lms-moodle-operator deploy to be available, otherwise recreate pod
	timeout 120 bash -c "until $(KUBECTL) -n ${TEST_OPERATOR_NAMESPACE} wait --for=condition=available --timeout=30s deploy ${TEST_OPERATOR_NAMEPREFIX}controller-manager &>/dev/null; do $(KUBECTL) -n ${TEST_OPERATOR_NAMESPACE} delete pod -l control-plane=controller-manager --field-selector=status.phase!=Running; done"

.PHONY: testing-deploy-samples-safe
testing-deploy-samples-safe: ## Try test deployment samples
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@$(MAKE) testing-deploy-samples || { $(MAKE) testing-manager-logs testing-undeploy; exit 2; }

.PHONY: testing-deploy-samples
testing-deploy-samples: ## Test deployment samples
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	kustomize build config/samples | $(KUBECTL) apply -f -
	$(KUBECTL) wait --for=condition=ready --timeout=1200s LMSMoodle lmsmoodle-sample

.PHONY: testing-undeploy
testing-undeploy: testing-undeploy-samples testing-undeploy-delete testing-undeploy-restore ## Test undeployment using kustomize

.PHONY: testing-undeploy-samples
testing-undeploy-samples: ## Test undeployment samples
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	kustomize build config/samples | $(KUBECTL) delete --ignore-not-found=true --wait=true --timeout=1200s -f - || echo

.PHONY: testing-manager-logs
testing-manager-logs: ## Output logs from all managers in namespace
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	$(KUBECTL) -n ${TEST_OPERATOR_NAMESPACE} logs -l control-plane=controller-manager -c manager --tail=-1 --limit-bytes=10240000

.PHONY: testing-undeploy-delete
testing-undeploy-delete: ## Test undeployment delete operators
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	kustomize build --load-restrictor LoadRestrictionsNone config/testing | $(KUBECTL) delete --ignore-not-found=true --timeout=600s -f - || echo
	kustomize build config/testing/moodle | sed -e "s@${TEST_OPERATOR_NAMEPREFIX}moodle-operator@${TEST_OPERATOR_NAMEPREFIX}moodle@" | $(KUBECTL) delete --ignore-not-found=true --timeout=600s -f - || echo
	kustomize build config/testing/keydb | sed -e "s@${TEST_OPERATOR_NAMEPREFIX}keydb-operator@${TEST_OPERATOR_NAMEPREFIX}keydb@" | $(KUBECTL) delete --ignore-not-found=true --timeout=600s -f - || echo
	kustomize build config/testing/nfs | sed -e "s@${TEST_OPERATOR_NAMEPREFIX}nfs-operator@${TEST_OPERATOR_NAMEPREFIX}nfs@" | $(KUBECTL) delete --ignore-not-found=true --timeout=600s -f - || echo
	kustomize build config/testing/postgres | sed -e "s@${TEST_OPERATOR_NAMEPREFIX}postgres-operator@${TEST_OPERATOR_NAMEPREFIX}postgres@" | $(KUBECTL) delete --ignore-not-found=true --timeout=600s -f - || echo
	# in case sc remains
	$(KUBECTL) delete --ignore-not-found=true sc site-lmsmoodle-sample-nfs-sc || echo

.PHONY: testing-undeploy-restore
testing-undeploy-restore: ## Test undeployment restore files
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	cd config/testing; \
	kustomize edit set image testing=testing-operator; \
	kustomize edit set namespace lms-moodle-test; \
	kustomize edit set nameprefix lms-moodle-
	cd config/testing/moodle; \
	kustomize edit set namespace lms-moodle-test; \
	kustomize edit set nameprefix lms-moodle-
	cd config/testing/keydb; \
	kustomize edit set namespace lms-moodle-test; \
	kustomize edit set nameprefix lms-moodle-
	cd config/testing/nfs; \
	kustomize edit set namespace lms-moodle-test; \
	kustomize edit set nameprefix lms-moodle-
	cd config/testing/postgres; \
	kustomize edit set namespace lms-moodle-test; \
	kustomize edit set nameprefix lms-moodle-

##@ Dependant operators

.PHONY: deploy-operators
deploy-operators: ## Deploy LMS Moodle Operator and dependant operators to the K8s cluster specified in ~/.kube/config.
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	cd config/manager && kustomize edit set image controller=$(BUILD_IMG)
	kustomize build config/operators | $(KUBECTL) apply -f -

.PHONY: undeploy-operators
undeploy-operators: ## Undeploy LMS Moodle Operator and dependant operators from the K8s cluster specified in ~/.kube/config.
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	kustomize build config/operators | $(KUBECTL) delete --ignore-not-found=true --timeout=600s -f -
