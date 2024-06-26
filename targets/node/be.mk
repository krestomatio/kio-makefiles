##@ Kio Web App API


KUSTOMIZE_DIR ?= .config/
KIND_CLUSTER_NAME ?= kio-web-app
KIND_SITE_CLUSTER_NAMES ?= dev-eks-us-west-1-lms-01 dev-eks-us-east-1-lms-01
KIO_WEB_APP_KUBECONFIG_NAME ?= local-kubeconfig-kio-web-app
KIO_WEB_APP_KUBECONFIG ?= $(shell echo "$${HOME}/.kube/$(KIO_WEB_APP_KUBECONFIG_NAME)")
KIO_WEB_APP_VAULT_ENVVARS_PATH ?= $(VAULT_LOCAL_MOUNT_POINT)/config/be/envvars
IMAGE_PULL_SECRET_NS ?= lms-moodle-operator-system
export KUBECONFIG := $(KIO_WEB_APP_KUBECONFIG)

.PHONY: install
install: kustomize kubectl dot-env-download-if ## install the environment

.PHONY: install-remote-sites
install-remote-sites: install kubeconfig-remote ## install the local environment using remote cluster for sites

.PHONY: install-local-sites
install-local-sites: install kind-create-site-clusters ## install the local environment along with two local cluster for sites

.PHONY: local-purge
local-purge: kind-delete-site-clusters kubeconfig-remove dot-env-remove delete-project-bin ## Purge local env: base (ns, db, pvc), k8s objects and local cluster

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
		$(MAKE) deploy-csi-driver-nfs deploy-lms-moodle-operators image-pull-secret api-endpoint-dns; \
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

.PHONY: deploy-lms-moodle-operators
deploy-lms-moodle-operators: ## Deploy kio operator and dependant operators to the K8s cluster specified in current cluster
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@$(KUSTOMIZE) build .config/local/kio/operators | $(KUBECTL) apply -f -
	@sleep 1
	@$(KUSTOMIZE) build .config/local/kio/templates | $(KUBECTL) apply -f -

.PHONY: undeploy-lms-moodle-operators
undeploy-lms-moodle-operators: ## Undeploy kio operator and dependant operators from the K8s cluster specified in current cluster
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@$(KUBECTL) delete --ignore-not-found=true --timeout=600s LMSMoodle --all
	@$(KUBECTL) delete --ignore-not-found=true --timeout=600s LMSMoodleTemplate --all
	@$(KUSTOMIZE) build .config/local/kio/operators/ | $(KUBECTL) delete --ignore-not-found=true --timeout=600s -f -

.PHONY: api-endpoint-dns
api-endpoint-dns: KIND_HOST_IP = $(shell docker network inspect kind --format '{{ (index .IPAM.Config 0).Gateway }}')
api-endpoint-dns:
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@$(KUBECTL) -n kube-system get cm coredns -o json |  sed -e 's@.:53 {\\n    errors\\n    health@.:53 {\\n    errors\\n    hosts {\\n       $(KIND_HOST_IP) api-local.krestomat.io\\n       fallthrough\\n    }\\n    health@' | $(KUBECTL) replace -f -
	@$(KUBECTL) -n kube-system rollout restart deployment/coredns
