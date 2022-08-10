##@ Kio Web App API


KUSTOMIZE_DIR ?= .config/
KIND_CLUSTER_NAME ?= kio-web-app
KIND_NAMESPACE ?= local-kio-web-app-system
KIND_SITE_CLUSTER_NAMES ?= e87ef9fe-3886-586e-8091-da1b4512c2e8 aadb72d7-520f-57a0-9437-126265951892
KUBE_CURRENT_CONTEXT = $(shell $(KUBECTL) config current-context)
KIO_WEB_APP_ENV ?= local
ifeq ($(KIO_WEB_APP_ENV),local)
KIO_WEB_APP_KUBECONFIG_NAME ?= dev-kubeconfig-kio-web-app
else
KIO_WEB_APP_KUBECONFIG_NAME ?= $(KIO_WEB_APP_ENV)-kubeconfig-kio-web-app
endif

.PHONY: install
install: kustomize skaffold kubectl kind-create kind-start kind-context dot-env-download-if ## install the local environment

.PHONY: install-remote-sites
install-remote-sites: kubectl kubeconfig-remote install ## install the local environment using remote cluster for sites

.PHONY: install-local-sites
install-local-sites: kubectl kind-create-site-clusters install ## install the local environment along with two local cluster for sites

.PHONY: deploy
deploy: ## Deploy to the K8s cluster specified in ~/.kube/config.
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@$(KUSTOMIZE) build $(KUSTOMIZE_DIR)/$(KIO_WEB_APP_ENV) | $(KUBECTL) apply -f -

.PHONY: undeploy
undeploy: ## Undeploy  from the K8s cluster specified in ~/.kube/config.
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@$(KUSTOMIZE) build $(KUSTOMIZE_DIR)/$(KIO_WEB_APP_ENV) | $(KUBECTL) delete --ignore-not-found=true -f -

.PHONY: local-deploy-base
local-deploy-base: ## Deploy base manifests for local env
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@echo -e "${YELLOW}++ deploying base...${RESET}"
	@cp -pf ~/.kube/$(KIO_WEB_APP_KUBECONFIG_NAME) $(KUSTOMIZE_DIR)/$(KIO_WEB_APP_ENV)/base/$(KIO_WEB_APP_KUBECONFIG_NAME)
	@$(KUSTOMIZE) build $(KUSTOMIZE_DIR)/local/base | $(KUBECTL) apply -f -
	rm $(KUSTOMIZE_DIR)/$(KIO_WEB_APP_ENV)/base/$(KIO_WEB_APP_KUBECONFIG_NAME)

.PHONY: local-deploy-db
local-deploy-db: local-deploy-base ## Deploy db manifests for local env
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@echo -e "${YELLOW}++ deploying db, it could take some seconds...${RESET}"
	@$(KUSTOMIZE) build $(KUSTOMIZE_DIR)/local/db --load-restrictor LoadRestrictionsNone | $(KUBECTL) apply -f -
	@$(KUBECTL) -n $(KIND_NAMESPACE) wait --for=condition=Available --timeout=90s deploy postgres-deploy

.PHONY: local-undeploy-base
local-undeploy-base: local-undeploy-db ## Delete base manifests for local env
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@touch $(KUSTOMIZE_DIR)/$(KIO_WEB_APP_ENV)/base/$(KIO_WEB_APP_KUBECONFIG_NAME)
	@$(KUSTOMIZE) build $(KUSTOMIZE_DIR)/local/base | $(KUBECTL) delete --ignore-not-found=true -f -

.PHONY: local-undeploy-db
local-undeploy-db: ## Delete db manifests for local env
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@$(KUSTOMIZE) build $(KUSTOMIZE_DIR)/local/db --load-restrictor LoadRestrictionsNone | $(KUBECTL) delete --ignore-not-found=true -f -

.PHONY: local-purge
local-purge: kind-delete kind-delete-site-clusters kubeconfig-remove dot-env-remove ## Purge local env: base (ns, db, pvc), k8s objects and local cluster

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
ifeq (,$(wildcard ~/.kube/$(KIO_WEB_APP_KUBECONFIG_NAME)))
	@echo -e "${YELLOW}++ VAULT_ADDR=$(VAULT_ADDR)${RESET}"
	@mkdir -p ~/.kube
	@$(VAULT) kv get -field $(KIO_WEB_APP_KUBECONFIG_NAME) kio_secrets/kio-web-app > ~/.kube/$(KIO_WEB_APP_KUBECONFIG_NAME)
endif

.PHONY: kubeconfig-remote
kubeconfig-remote: vault ## download and overwrite kubeconfig file for kio web app role
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@echo -e "${YELLOW}++ VAULT_ADDR=$(VAULT_ADDR)${RESET}"
	@mkdir -p ~/.kube
	@$(VAULT) kv get -field $(KIO_WEB_APP_KUBECONFIG_NAME) kio_secrets/kio-web-app > ~/.kube/$(KIO_WEB_APP_KUBECONFIG_NAME)

.PHONY: kubeconfig-remove
kubeconfig-remove: ## Remove kubeconfig file for kio web app role
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	rm -f ~/.kube/$(KIO_WEB_APP_KUBECONFIG_NAME)

.PHONY: dot-env-download-if
dot-env-download-if: vault ## download and overwrite .env file for kio web app api, but only if it does not exist on disk
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifeq (,$(wildcard .env))
	@echo -e "${YELLOW}++ VAULT_ADDR=$(VAULT_ADDR)${RESET}"
	@$(VAULT) kv get -field kio-api-env kio_secrets/kio-web-app > .env
endif

.PHONY: dot-env-download
dot-env-download: vault ## download and overwrite .env file for kio web app api
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@echo -e "${YELLOW}++ VAULT_ADDR=$(VAULT_ADDR)${RESET}"
	@$(VAULT) kv get -field kio-api-env kio_secrets/kio-web-app > .env

.PHONY: dot-env-remove
dot-env-remove: ## Remove .env file for kio web app api
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	rm -f .env

.PHONY: kind-create-site-clusters
kind-create-site-clusters: konfig kind ## Create/Start kind clusters for sites
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@echo -e "${YELLOW}++ empty kubeconfig: $(KIO_WEB_APP_KUBECONFIG_NAME)${RESET}"
	@for cluster in $(KIND_SITE_CLUSTER_NAMES); do \
		$(MAKE) kind-create kind-start kind-context deploy-csi-driver-nfs deploy-kio-operators image-pull-secret operator-env-secret api-endpoint-dns KIND_CLUSTER_NAME=$${cluster} KIND_NAMESPACE=kio-operator-system || { $(KUBECTL) config use-context $(KUBE_CURRENT_CONTEXT); exit 2; }; \
	done
	@$(MAKE) kubeconfig-local
	@echo -e "${YELLOW}++ setting kubeconfig original context${RESET}"
	@$(KUBECTL) config use-context $(KUBE_CURRENT_CONTEXT)

.PHONY: kind-delete-site-clusters
kind-delete-site-clusters: ## Delete kind clusters for sites
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@for cluster in $(KIND_SITE_CLUSTER_NAMES); do \
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

.PHONY: kubeconfig-local
kubeconfig-local: kubectl konfig ## Generate and overwrite kubeconfig file for kio web app role
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@echo -e "${YELLOW}++ saving new kubeconfig: $(KIO_WEB_APP_KUBECONFIG_NAME)${RESET}"
	@mkdir -p ~/.kube
	@rm -f ~/.kube/$(KIO_WEB_APP_KUBECONFIG_NAME)
	@$(KONFIG) export $(addprefix kind-, $(KIND_SITE_CLUSTER_NAMES)) >> ~/.kube/$(KIO_WEB_APP_KUBECONFIG_NAME)
	@for cluster in $(KIND_SITE_CLUSTER_NAMES); do \
		KUBECONFIG=~/.kube/$(KIO_WEB_APP_KUBECONFIG_NAME) $(KUBECTL) config rename-context kind-$${cluster} $${cluster}; \
		KUBECONFIG=~/.kube/$(KIO_WEB_APP_KUBECONFIG_NAME) $(KUBECTL) config use-context $${cluster}; \
	done

.PHONY: image-pull-secret
image-pull-secret: vault ## Download and store image pull secret
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@echo -e "${YELLOW}++ VAULT_ADDR=$(VAULT_ADDR)${RESET}"
	@$(VAULT) kv get -field kio-web-app-dev-pull-secret kio_secrets/kio-web-app | $(KUBECTL) apply -f -

.PHONY: operator-env-secret
operator-env-secret: vault ## Store operator secret to add as environment variables
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@AUTH_JWT_USERS_KEY=$$($(VAULT) kv get -field kio-api-env kio_secrets/kio-web-app | sed -n 's/^AUTH_JWT_OPERATORS_KEY=//p'); \
	$(KUBECTL) -n m4e-operator-system create secret generic operator-env-secret \
		--dry-run=client --save-config -o yaml \
		--from-literal=JWT_TOKEN_SECRET=$${AUTH_JWT_USERS_KEY} \
		| kubectl apply -f -

.PHONY: deploy-kio-operators
deploy-kio-operators: ## Deploy kio operator and dependant operators to the K8s cluster specified in current cluster
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@kustomize build .config/local/kio/operators | $(KUBECTL) apply -f -
	@sleep 1
	@kustomize build .config/local/kio/flavor | $(KUBECTL) apply -f -

.PHONY: undeploy-kio-operators
undeploy-kio-operators: ## Undeploy kio operator and dependant operators from the K8s cluster specified in current cluster
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@$(KUBECTL) delete --ignore-not-found=true --timeout=600s Site --all
	@$(KUBECTL) delete --ignore-not-found=true --timeout=600s Flavor --all
	@kustomize build .config/local/kio/operators/ | $(KUBECTL) delete --ignore-not-found=true --timeout=600s -f -

.PHONY: api-endpoint-dns
api-endpoint-dns: KIND_HOST_IP = $(shell docker network inspect kind --format '{{ (index .IPAM.Config 0).Gateway }}')
api-endpoint-dns:
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@$(KUBECTL) -n kube-system get cm coredns -o json |  sed -e 's@.:53 {\\n    errors\\n    health@.:53 {\\n    errors\\n    hosts {\\n       $(KIND_HOST_IP) api-local.krestomat.io\\n       fallthrough\\n    }\\n    health@' | $(KUBECTL) replace -f -
	@$(KUBECTL) -n kube-system rollout restart deployment/coredns
