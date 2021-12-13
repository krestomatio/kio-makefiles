##@ Kio Web App


KUSTOMIZE_DIR ?= .config/
KIND_CLUSTER_NAME ?= kio-web-app
KIND_NAMESPACE ?= local-kio-web-app-system

install: kustomize skaffold kubectl kind kind-create kind-context

buildah-build: ## Build the container image using buildah
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@echo -e "\nBuilding container image..."
	buildah --storage-driver vfs bud -t $(IMG) .


buildah-push: ## Push the container image using buildah
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@echo -e "\nPushing container image..."
	buildah --storage-driver vfs push $(IMG)

deploy: ## Deploy to the K8s cluster specified in ~/.kube/config.
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	$(KUSTOMIZE) build $(KUSTOMIZE_DIR)/$(KIO_WEB_APP_ENV) | kubectl apply -f -

undeploy: ## Undeploy  from the K8s cluster specified in ~/.kube/config.
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	$(KUSTOMIZE) build $(KUSTOMIZE_DIR)/$(KIO_WEB_APP_ENV) | kubectl delete --ignore-not-found=true -f -

kind-create: ## Create kind clusters
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifeq (0, $(shell $(KIND) get nodes --name $(KIND_CLUSTER_NAME) 2>/dev/null; echo $$?))
	$(KIND) create cluster --name $(KIND_CLUSTER_NAME) --image=kindest/node:v$(KIND_IMAGE_VERSION)
endif

kind-delete: ## Delete kind clusters
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	$(KIND) delete cluster --name $(KIND_CLUSTER_NAME)

kind-context: ## Use kind cluster by setting its context
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	$(KUBECTL) config use-context kind-$(KIND_CLUSTER_NAME)
	$(KUBECTL) config set-context --current --namespace=$(KIND_NAMESPACE)

kind-pause: ## Pause kind cluster container
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	$(KIND) get nodes --name $(KIND_CLUSTER_NAME) | xargs docker pause

kind-unpause: ## Unpause kind cluster container
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	$(KIND) get nodes --name $(KIND_CLUSTER_NAME) | xargs docker unpause

local-deploy-base: ## Deploy base manifests for local env
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@echo "# deploying base..."
	$(KUSTOMIZE) build $(KUSTOMIZE_DIR)/local/base | kubectl apply -f -

local-deploy-db: ## Deploy db manifests for local env
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@echo "# deploying db, it could take some seconds..."
	$(KUSTOMIZE) build $(KUSTOMIZE_DIR)/local/db --load-restrictor LoadRestrictionsNone | kubectl apply -f -
	$(KUBECTL) -n $(KIND_NAMESPACE) wait --for=condition=Available --timeout=90s deploy postgres-deploy

local-undeploy-base: ## Delete base manifests for local env
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	$(KUSTOMIZE) build $(KUSTOMIZE_DIR)/local/base | kubectl delete --ignore-not-found=true -f -

local-undeploy-db: ## Delete db manifests for local env
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	$(KUSTOMIZE) build $(KUSTOMIZE_DIR)/local/db --load-restrictor LoadRestrictionsNone | kubectl delete --ignore-not-found=true -f -

local-purge: local-undeploy-base kind-delete ## Purge local env: base (ns, db, pvc), k8s objects and local cluster

local-dev: install ## Run local dev
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@[ -f .env ] || { echo "${RED}# .env file does not exist${RESET}"; exit 1; }
ifeq (n,$(findstring n,$(firstword -$(MAKEFLAGS))))
	@$(SKAFFOLD) dev
else
	@bash -c "trap '$(MAKE) local-undeploy-db' EXIT; $(SKAFFOLD) dev"
endif
