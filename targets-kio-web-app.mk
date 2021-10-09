##@ Kio Web App


KIND_CLUSTER_NAME ?= kio-web-app
KIND_NAMESPACE ?= local-kio-web-app-system
HASURA_GRAPHQL_ADMIN_SECRET ?= secret

install: kustomize skaffold kubectl kind kind-create kind-context

buildah-build: ## Build the container image using buildah
	@echo "+ $@"
	@echo -e "\nBuilding container image..."
	buildah --storage-driver vfs bud -t $(IMG) .


buildah-push: ## Push the container image using buildah
	@echo "+ $@"
	@echo -e "\nPushing container image..."
	buildah --storage-driver vfs push $(IMG)

deploy: ## Deploy to the K8s cluster specified in ~/.kube/config.
	@echo "+ $@"
	$(KUSTOMIZE) build config/$(KIO_WEB_APP_ENV) | kubectl apply -f -

undeploy: ## Undeploy  from the K8s cluster specified in ~/.kube/config.
	@echo "+ $@"
	$(KUSTOMIZE) build config/$(KIO_WEB_APP_ENV) | kubectl delete --ignore-not-found=true -f -

kind-create: ## Create kind clusters
	@echo "+ $@"
ifeq (0, $(shell $(KIND) get nodes --name $(KIND_CLUSTER_NAME) 2>/dev/null; echo $$?))
	$(KIND) create cluster --name $(KIND_CLUSTER_NAME) --image=kindest/node:v$(KIND_IMAGE_VERSION)
endif

kind-delete: ## Delete kind clusters
	@echo "+ $@"
	$(KIND) delete cluster --name $(KIND_CLUSTER_NAME)

kind-context: ## Use kind cluster by setting its context
	@echo "+ $@"
	$(KUBECTL) config use-context kind-$(KIND_CLUSTER_NAME)
	$(KUBECTL) config set-context --current --namespace=$(KIND_NAMESPACE)

local-deploy-db: ## Deploy database manifests for local env
	@echo "+ $@"
	$(KUSTOMIZE) build config/local/db | kubectl apply -f -
	$(info waiting for postres to be available)
	$(KUBECTL) wait --for=condition=Available --timeout=90s deploy postgres-deploy

local-undeploy-db: ## Delete database manifests for local env
	@echo "+ $@"
	$(KUSTOMIZE) build config/local/db | kubectl delete --ignore-not-found=true -f -

local-cleanup: skaffold-cleanup local-undeploy-db ## Cleanup G12e and DB objects

skaffold-dev: ## Run skaffold dev
	@echo "+ $@"
	$(SKAFFOLD) dev

skaffold-delete: ## Delete G12e
	@echo "+ $@"
	$(SKAFFOLD) delete

.PHONY: hasura
HASURA = $(LOCAL_BIN)/bin/hasura
hasura: ## Download hasura locally if necessary.
	@echo "+ $@"
ifeq (,$(wildcard $(HASURA)))
ifeq (,$(shell which hasura 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p $(dir $(HASURA)) ;\
	curl -sSL https://github.com/hasura/graphql-engine/releases/download/v$(G12E_VERSION)/cli-hasura-$(OS)-$(ARCH) -o $(HASURA) ;\
	chmod +x $(HASURA) ;\
	}
else
HASURA = $(shell which hasura)
endif
endif

g12e-boostrap: ## Bootstrap a new g12e deployment
	@echo "+ $@"
	pushd graphql-engine; $(HASURA) migrate apply --database-name default; $(HASURA) metadata apply; popd
