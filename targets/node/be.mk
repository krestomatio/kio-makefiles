##@ Kio Web App API


KUSTOMIZE_DIR ?= .config/
KIND_CLUSTER_NAME ?= kio-web-app
KIND_NAMESPACE ?= local-kio-web-app-system
KIND_SITE_CLUSTER_NAMES ?= dev-eks-us-east-1-lms-01 dev-eks-us-west-1-lms-01
KIO_WEB_APP_KUBECONFIG_NAME ?= local-kubeconfig-kio-web-app
KIO_WEB_APP_KUBECONFIG ?= $(shell echo "$${HOME}/.kube/$(KIO_WEB_APP_KUBECONFIG_NAME)")
KIO_WEB_APP_VAULT_ENVVARS_PATH ?= $(VAULT_LOCAL_MOUNT_POINT)/config/be/envvars
IMAGE_PULL_SECRET_NS ?= kio-operator-system
export KUBECONFIG := $(KIO_WEB_APP_KUBECONFIG)

.PHONY: install
install: kustomize skaffold kubectl dot-env-download-if kind-create-kio-web-app-cluster ## install the environment

.PHONY: install-remote-sites
install-remote-sites: install kubeconfig-remote ## install the local environment using remote cluster for sites

.PHONY: install-local-sites
install-local-sites: install kind-create-site-clusters ## install the local environment along with two local cluster for sites

.PHONY: local-deploy-base
local-deploy-base: ## Deploy base manifests for local env
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@echo -e "${YELLOW}++ deploying base...${RESET}"
	@$(KUSTOMIZE) build $(KUSTOMIZE_DIR)/local/base | $(KUBECTL) apply -f -

.PHONY: local-deploy-db
local-deploy-db: local-deploy-base ## Deploy db manifests for local env
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@echo -e "${YELLOW}++ deploying db, it could take some seconds...${RESET}"
	@$(KUSTOMIZE) build $(KUSTOMIZE_DIR)/local/db --load-restrictor LoadRestrictionsNone | $(KUBECTL) apply -f -
	@$(KUBECTL) -n $(KIND_NAMESPACE) wait --for=condition=Available --timeout=90s deploy postgres-deploy

.PHONY: local-undeploy-base
local-undeploy-base: local-undeploy-db ## Delete base manifests for local env
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@touch $(KUSTOMIZE_DIR)/local/base/$(KIO_WEB_APP_KUBECONFIG_NAME)
	@$(KUSTOMIZE) build $(KUSTOMIZE_DIR)/local/base | $(KUBECTL) delete --ignore-not-found=true -f -

.PHONY: local-undeploy-db
local-undeploy-db: ## Delete db manifests for local env
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@$(KUSTOMIZE) build $(KUSTOMIZE_DIR)/local/db --load-restrictor LoadRestrictionsNone | $(KUBECTL) delete --ignore-not-found=true -f -

.PHONY: local-purge
local-purge: kind-delete kind-delete-site-clusters kubeconfig-remove dot-env-remove delete-project-bin ## Purge local env: base (ns, db, pvc), k8s objects and local cluster

.PHONY: local-dev
local-dev: install ## Run local dev
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@[ -f .env ] || { echo "${RED}# .env file does not exist${RESET}"; exit 1; }
ifeq (n,$(findstring n,$(firstword -$(MAKEFLAGS))))
	@$(SKAFFOLD) dev
else
	@bash -c "trap '$(MAKE) local-undeploy-db' EXIT; $(SKAFFOLD) dev"
endif

.PHONY: local-db
local-db: install ## Run local db only
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@[ -f .env ] || { echo "${RED}# .env file does not exist${RESET}"; exit 1; }
ifeq (n,$(findstring n,$(firstword -$(MAKEFLAGS))))
	$(SKAFFOLD) dev -p db-only
else
	@bash -c "trap '$(MAKE) local-undeploy-db' EXIT; $(SKAFFOLD) dev -p db-only"
endif

.PHONY: kubeconfig-remote-if
kubeconfig-remote-if: vault ## download kubeconfig file for kio web app role, but only if it does not exist on disk
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifeq (,$(wildcard $(KIO_WEB_APP_KUBECONFIG)))
	@$(MAKE) kubeconfig-remote
endif

.PHONY: kubeconfig-remote
kubeconfig-remote: vault ## download and overwrite kubeconfig file for kio web app role
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@echo -e "${YELLOW}++ VAULT_ADDR=$(VAULT_ADDR)${RESET}"
	@mkdir -p $(dir $(KIO_WEB_APP_KUBECONFIG))
	@if [ -f "$(KIO_WEB_APP_KUBECONFIG)" ]; then\
		mv -f "$(KIO_WEB_APP_KUBECONFIG)" "$(KIO_WEB_APP_KUBECONFIG).bak";\
	fi
	$(call vault-save-secret-field-in-file,config,$(VAULT_LOCAL_MOUNT_POINT)/auth/kubeconfig/kio-web-app,$(KIO_WEB_APP_KUBECONFIG))
	@if [ -f "$(KIO_WEB_APP_KUBECONFIG).bak" ]; then\
		KUBECONFIG="$(KIO_WEB_APP_KUBECONFIG).bak":"$(KIO_WEB_APP_KUBECONFIG)" kubectl config view --flatten > "$(KIO_WEB_APP_KUBECONFIG).bak2";\
		mv -f "$(KIO_WEB_APP_KUBECONFIG).bak2" "$(KIO_WEB_APP_KUBECONFIG)";\
		rm -f "$(KIO_WEB_APP_KUBECONFIG).bak" "$(KIO_WEB_APP_KUBECONFIG).bak2";\
	fi

.PHONY: kubeconfig-remove
kubeconfig-remove: ## Remove kubeconfig file for kio web app role
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	rm -f $(KIO_WEB_APP_KUBECONFIG)

.PHONY: dot-env-download-if
dot-env-download-if: vault ## download .env file for kio web app api, but only if it does not exist on disk
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifeq (,$(wildcard .env))
	@$(MAKE) dot-env-download
endif

.PHONY: dot-env-download
dot-env-download: vault envconsul ## download and overwrite .env file for kio web app api
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@echo -e "${YELLOW}++ VAULT_ADDR=$(VAULT_ADDR)${RESET}"
	$(call vault-save-secret-json-to-env,$(KIO_WEB_APP_VAULT_ENVVARS_PATH),.env)

.PHONY: dot-env-remove
dot-env-remove: ## Remove .env file for kio web app api
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	rm -f .env

.PHONY: kind-create-kio-web-app-cluster
kind-create-kio-web-app-cluster: kind-create kind-start kind-context ## Create/Start kind local cluster

.PHONY: kind-create-site-clusters
kind-create-site-clusters: kind ## Create/Start kind clusters for sites
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@echo -e "${YELLOW}++ empty kubeconfig: $(KIO_WEB_APP_KUBECONFIG_NAME)${RESET}"
	@mkdir -p $(dir $(KIO_WEB_APP_KUBECONFIG))
	@for cluster in $(KIND_SITE_CLUSTER_NAMES); do \
		export KIND_CLUSTER_NAME=$${cluster} KIND_CONTEXT_NO_PREFIX=true; \
		$(MAKE) kind-create kind-start; \
		$(KUBECTL) config rename-context kind-$${cluster} $${cluster} || echo ignoring; \
		$(MAKE) kind-context; \
		$(MAKE) deploy-csi-driver-nfs deploy-kio-operators image-pull-secret operator-env-secret api-endpoint-dns; \
	done

.PHONY: kind-delete-site-clusters
kind-delete-site-clusters: ## Delete kind clusters for sites
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@for cluster in $(KIND_SITE_CLUSTER_NAMES); do \
		$(KUBECTL) config rename-context $${cluster} kind-$${cluster}; \
		$(MAKE) kind-delete KIND_CLUSTER_NAME=$${cluster}; \
	done

.PHONY: kind-start-site-clusters
kind-start-site-clusters: ## Stop container of kind clusters for sites
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@for cluster in $(KIND_SITE_CLUSTER_NAMES); do \
		$(MAKE) kind-start KIND_CLUSTER_NAME=$${cluster}; \
	done

.PHONY: kind-stop-site-clusters
kind-stop-site-clusters: ## Stop container of kind clusters for sites
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@for cluster in $(KIND_SITE_CLUSTER_NAMES); do \
		$(MAKE) kind-stop KIND_CLUSTER_NAME=$${cluster}; \
	done

.PHONY: image-pull-secret
image-pull-secret: vault ## Download and store image pull secret
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@echo -e "${YELLOW}++ VAULT_ADDR=$(VAULT_ADDR)${RESET}"
	@$(KUBECTL) -n $(IMAGE_PULL_SECRET_NS) get secret kio-web-app-dev-pull-secret -o name || $(VAULT) kv get -field regcred $(VAULT_INTERNAL_MOUNT_POINT)/registry/quay/kio-web-app-reader | $(KUBECTL) -n $(IMAGE_PULL_SECRET_NS) create secret docker-registry kio-web-app-dev-pull-secret --from-file=.dockerconfigjson=/dev/stdin

.PHONY: operator-env-secret
operator-env-secret: vault ## Store operator secret to add as environment variables
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@$(KUBECTL) -n moodle-operator-system get secret operator-env-secret -o name || AUTH_JWT_OPERATORS_KEY=$$($(VAULT) kv get -field AUTH_JWT_OPERATORS_KEY $(KIO_WEB_APP_VAULT_ENVVARS_PATH)); \
	$(KUBECTL) -n moodle-operator-system create secret generic operator-env-secret \
		--dry-run=client --save-config -o yaml \
		--from-literal=JWT_TOKEN_SECRET=$${AUTH_JWT_OPERATORS_KEY} \
		| kubectl apply -f -

.PHONY: deploy-kio-operators
deploy-kio-operators: ## Deploy kio operator and dependant operators to the K8s cluster specified in current cluster
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@$(KUSTOMIZE) build .config/local/kio/operators | $(KUBECTL) apply -f -
	@sleep 1
	@$(KUSTOMIZE) build .config/local/kio/flavor | $(KUBECTL) apply -f -

.PHONY: undeploy-kio-operators
undeploy-kio-operators: ## Undeploy kio operator and dependant operators from the K8s cluster specified in current cluster
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@$(KUBECTL) delete --ignore-not-found=true --timeout=600s Site --all
	@$(KUBECTL) delete --ignore-not-found=true --timeout=600s Flavor --all
	@$(KUSTOMIZE) build .config/local/kio/operators/ | $(KUBECTL) delete --ignore-not-found=true --timeout=600s -f -

.PHONY: api-endpoint-dns
api-endpoint-dns: KIND_HOST_IP = $(shell docker network inspect kind --format '{{ (index .IPAM.Config 0).Gateway }}')
api-endpoint-dns:
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@$(KUBECTL) -n kube-system get cm coredns -o json |  sed -e 's@.:53 {\\n    errors\\n    health@.:53 {\\n    errors\\n    hosts {\\n       $(KIND_HOST_IP) api-local.krestomat.io\\n       fallthrough\\n    }\\n    health@' | $(KUBECTL) replace -f -
	@$(KUBECTL) -n kube-system rollout restart deployment/coredns


.PHONY: kubeconfig-secret
kubeconfig-secret: ## Create kubeconfig secret
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@$(KUBECTL) -n $(KIND_NAMESPACE) delete secret server-kubeconfig-secret --ignore-not-found
	@$(KUBECTL) -n $(KIND_NAMESPACE) create secret generic server-kubeconfig-secret --from-literal=local-kubeconfig-kio-web-app="$$(cat $(KUBECONFIG))"
