ifneq (,$(wildcard $(MK_TARGETS_PROJECT_FILE)))
include $(MK_TARGETS_PROJECT_FILE)
endif
ifneq (,$(wildcard $(MK_TARGETS_PROJECT_TYPE_FILE)))
include $(MK_TARGETS_PROJECT_TYPE_FILE)
endif

## General functions

# github_latest_release_version will find latest release version of repo $1
define github_latest_release_version
$(shell basename $$(curl -fs -o/dev/null -w %{redirect_url} '$(1)/releases/latest') | sed 's/^v//')
endef

# vault-save-secret-field-in-file will store field $1 from path $2 to file $3
define vault-save-secret-field-in-file
@echo -e "${YELLOW}++ saving field $(1) from path $(2) to file $(3)${RESET}"
@vault_field=$$($(VAULT) kv get -field "$(1)" "$(2)");\
test "$$vault_field" && echo "$$vault_field" > "$(3)"
endef

# vault-save-secret-json-to-env will store json secret in path $1 to dotfile $2
define vault-save-secret-json-to-env
@echo -e "${YELLOW}++ saving json secret from path $(1) to dotfile $(2)${RESET}"
@vault_json=$$($(ENVCONSUL) -pristine -no-prefix -once -vault-retry=0 -secret $(1) env);\
test "$$vault_json" && echo "$$vault_json" | sort > "$(2)"
endef

## General targets
ifneq ($(PROJECT_TYPE),go-operator)
.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: kustomize
KUSTOMIZE = $(LOCAL_BIN)/kustomize
kustomize: ## Download kustomize locally if necessary.
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifeq (,$(wildcard $(KUSTOMIZE)))
ifeq (,$(shell which kustomize 2>/dev/null))
	@echo -e "${YELLOW}++ Downloading kustomize to $(KUSTOMIZE)${RESET}"
	@{ \
	set -e ;\
	mkdir -p $(dir $(KUSTOMIZE)) ;\
	curl -sSLo - https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v$(KUSTOMIZE_VERSION)/kustomize_v$(KUSTOMIZE_VERSION)_$(OS)_$(ARCH).tar.gz | \
	tar xzf - -C $(dir $(KUSTOMIZE))/ ;\
	}
else
KUSTOMIZE = $(shell which kustomize)
endif
endif
endif

##@ Common


.PHONY: start-dockerd
start-dockerd: ## Start docker daemon in background (if not running) (meant to be run in container)
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@pidof dockerd && echo -e "${YELLOW}++ dockerd already running...${RESET}" || \
		{ echo -e "${YELLOW}++ starting dockerd in the backgroud...${RESET}"; \
		  dockerd-entrypoint.sh > /tmp/dockerd.log 2>&1 & \
		  sleep 4; \
		}

.PHONY: image-build
image-build: ## Build container image with the manager.
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifeq ($(PROJECT_TYPE),ansible-operator)
	$(CONTAINER_BUILDER) build . -t $(BUILD_IMG) \
		--build-arg COLLECTION_FILE=$(COLLECTION_FILE)
else
	$(CONTAINER_BUILDER) build . -t $(BUILD_IMG)
endif

.PHONY: image-push
image-push: ## Push container image with the manager.
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	$(CONTAINER_BUILDER) push $(BUILD_IMG)

.PHONY: buildah-build
buildah-build: ## Build the container image using buildah
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifeq ($(PROJECT_TYPE),ansible-operator)
	buildah --storage-driver vfs bud -t $(BUILD_IMG) . \
		--build-arg COLLECTION_FILE=$(COLLECTION_FILE)
else
	buildah --storage-driver vfs bud -t $(BUILD_IMG) .
endif

.PHONY: buildah-push
buildah-push: ## Push the container image using buildah
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	buildah --storage-driver vfs push $(BUILD_IMG)

.PHONY: buildx-image
buildx-image: ## Build container image with docker buildx
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifeq ($(PROJECT_TYPE),ansible-operator)
	docker buildx build . --pull --push --progress=$(BUILDX_PROGRESS) --platform="linux/amd64" --platform="linux/arm64" -t $(BUILD_IMG) \
		--build-arg COLLECTION_FILE=$(COLLECTION_FILE)
else
	docker buildx build . --pull --push --progress=$(BUILDX_PROGRESS) --platform="linux/amd64" --platform="linux/arm64" -t $(BUILD_IMG)
endif

.PHONY: skaffold
SKAFFOLD = $(LOCAL_BIN)/skaffold
skaffold: ## Download kustomize locally if necessary.
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifeq (,$(wildcard $(SKAFFOLD)))
ifeq (,$(shell which skaffold 2>/dev/null))
	@echo -e "${YELLOW}++ Downloading skaffold to $(SKAFFOLD)${RESET}"
	@{ \
	set -e ;\
	mkdir -p $(dir $(SKAFFOLD)) ;\
	curl -sSL https://github.com/GoogleContainerTools/skaffold/releases/download/v$(SKAFFOLD_VERSION)/skaffold-$(OS)-$(ARCH) -o $(SKAFFOLD) ;\
	chmod +x $(SKAFFOLD) ;\
	}
else
SKAFFOLD = $(shell which skaffold)
endif
endif

.PHONY: kubectl
KUBECTL = $(LOCAL_BIN)/kubectl
kubectl: ## Download kubectl locally if necessary.
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifeq (,$(wildcard $(KUBECTL)))
ifeq (,$(shell which kubectl 2>/dev/null))
	@echo -e "${YELLOW}++ Downloading kubectl to $(KUBECTL)${RESET}"
	@{ \
	set -e ;\
	mkdir -p $(dir $(KUBECTL)) ;\
	curl -sSL https://storage.googleapis.com/kubernetes-release/release/v$(KUBECTL_VERSION)/bin/$(OS)/$(ARCH)/kubectl -o $(KUBECTL) ;\
	chmod +x $(KUBECTL) ;\
	}
else
KUBECTL = $(shell which kubectl)
endif
endif

.PHONY: kind
KIND = $(LOCAL_BIN)/kind
kind: ## Download kind locally if necessary.
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifeq (,$(wildcard $(KIND)))
ifeq (,$(shell which kind 2>/dev/null))
	@echo -e "${YELLOW}++ Downloading kind to $(KIND)${RESET}"
	@{ \
	set -e ;\
	mkdir -p $(dir $(KIND)) ;\
	curl -sSL https://kind.sigs.k8s.io/dl/v$(KIND_VERSION)/kind-$(OS)-$(ARCH) -o $(KIND) ;\
	chmod +x $(KIND) ;\
	}
else
KIND = $(shell which kind)
endif
endif

.PHONY: buildx
BUILDX =  $(HOME)/.docker/cli-plugins/docker-buildx
buildx: buildx_version = $(call github_latest_release_version,https://github.com/docker/buildx)
buildx: ## Download buildx locally if necessary.
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifeq (,$(wildcard $(BUILDX)))
ifeq (,$(shell which buildx 2>/dev/null))
	@echo -e "${YELLOW}++ Downloading buildx to $(BUILDX)${RESET}"
	@{ \
	set -e ;\
	mkdir -p $(dir $(BUILDX)) ;\
	curl -sSL "https://github.com/docker/buildx/releases/download/v$(buildx_version)/buildx-v$(buildx_version).$(OS)-$(ARCH)" -o $(BUILDX) ;\
	chmod +x $(BUILDX) ;\
	}
else
BUILDX = $(shell which buildx)
endif
endif

.PHONY: frpc
FRPC = $(LOCAL_BIN)/frpc
frpc: ## Download frpc locally if necessary.
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifeq (,$(wildcard $(FRPC)))
ifeq (,$(shell which frpc 2>/dev/null))
	@echo -e "${YELLOW}++ Downloading frpc to $(FRPC)${RESET}"
	@{ \
	set -e ;\
	mkdir -p $(dir $(FRPC)) ;\
	curl -sSLo - https://github.com/fatedier/frp/releases/download/v$(FRPC_VERSION)/frp_$(FRPC_VERSION)_$(OS)_$(ARCH).tar.gz | \
	tar xzf - -C /tmp/ ;\
	mv /tmp/frp_$(FRPC_VERSION)_$(OS)_$(ARCH)/frpc $(dir $(FRPC))/frpc ;\
	}
else
FRPC = $(shell which frpc)
endif
endif

.PHONY: kind-create
kind-create: kind ## Create kind clusters
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@$(KIND) get clusters 2>/dev/null | grep -q $(KIND_CLUSTER_NAME) || \
	{ $(KIND) create cluster --name $(KIND_CLUSTER_NAME) --image=kindest/node:v$(KIND_IMAGE_VERSION); }

.PHONY: kind-delete
kind-delete: ## Delete kind clusters
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@$(KIND) delete cluster --name $(KIND_CLUSTER_NAME)

.PHONY: kind-context
kind-context: ## Use kind cluster by setting its context
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifeq ($(KIND_CONTEXT_NO_PREFIX),true)
	@$(KUBECTL) config use-context $(KIND_CLUSTER_NAME)
else
	@$(KUBECTL) config use-context kind-$(KIND_CLUSTER_NAME)
endif
ifneq ($(KIND_NAMESPACE),)
	@$(KUBECTL) config set-context --current --namespace=$(KIND_NAMESPACE)
endif

.PHONY: kind-start
kind-start: ## Start kind cluster container
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@$(KIND) get nodes --name $(KIND_CLUSTER_NAME) | xargs docker start

.PHONY: kind-stop
kind-stop: ## Stop kind cluster container
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@$(KIND) get nodes --name $(KIND_CLUSTER_NAME) | xargs docker stop

.PHONY: kind-pause
kind-pause: ## Pause kind cluster container
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@$(KIND) get nodes --name $(KIND_CLUSTER_NAME) | xargs docker pause

.PHONY: kind-unpause
kind-unpause: ## Unpause kind cluster container
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@$(KIND) get nodes --name $(KIND_CLUSTER_NAME) | xargs docker unpause

.PHONY: deploy-csi-driver-nfs
deploy-csi-driver-nfs: ## Deploy CSI NFS to the K8s cluster specified in ~/.kube/config.
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@echo -e "${YELLOW}++ installing CSI NFS${RESET}"
	@$(KUSTOMIZE) build $(CSI_NFS_BASE_URL_INSTALL) | $(KUBECTL) apply -f -

.PHONY: undeploy-csi-driver-nfs
undeploy-csi-driver-nfs: ## Undeploy CSI NFS from the K8s cluster specified in ~/.kube/config.
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@$(KUSTOMIZE) build $(CSI_NFS_BASE_URL_INSTALL) | $(KUBECTL) delete -f -

.PHONY: vault
VAULT = $(LOCAL_BIN)/vault
vault: ## Download vault CLI locally if necessary.
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifeq (,$(wildcard $(VAULT)))
ifeq (,$(shell which vault 2>/dev/null))
	@echo -e "${YELLOW}++ Downloading vault to $(VAULT)${RESET}"
	@{ \
	set -e ;\
	mkdir -p $(dir $(VAULT)) ;\
	curl -sSL https://releases.hashicorp.com/vault/$(VAULT_VERSION)/vault_$(VAULT_VERSION)_$(OS)_$(ARCH).zip -o /tmp/vault_$(VAULT_VERSION)_$(OS)_$(ARCH).zip ;\
	unzip -d $(dir $(KUSTOMIZE))/ /tmp/vault_$(VAULT_VERSION)_$(OS)_$(ARCH).zip ;\
	chmod +x $(VAULT) ;\
	}
else
VAULT = $(shell which vault)
endif
endif

.PHONY: envconsul
ENVCONSUL = $(LOCAL_BIN)/envconsul
envconsul: ## Download envconsul CLI locally if necessary.
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifeq (,$(wildcard $(ENVCONSUL)))
ifeq (,$(shell which envconsul 2>/dev/null))
	@echo -e "${YELLOW}++ Downloading envconsul to $(ENVCONSUL)${RESET}"
	@{ \
	set -e ;\
	mkdir -p $(dir $(ENVCONSUL)) ;\
	curl -sSL https://releases.hashicorp.com/envconsul/$(ENVCONSUL_VERSION)/envconsul_$(ENVCONSUL_VERSION)_$(OS)_$(ARCH).zip -o /tmp/envconsul_$(ENVCONSUL_VERSION)_$(OS)_$(ARCH).zip ;\
	unzip -d $(dir $(KUSTOMIZE))/ /tmp/envconsul_$(ENVCONSUL_VERSION)_$(OS)_$(ARCH).zip ;\
	chmod +x $(ENVCONSUL) ;\
	}
else
ENVCONSUL = $(shell which envconsul)
endif
endif

.PHONY: vault-login
vault-login: VAULT_LOGIN_METHOD = oidc
vault-login: VAULT_LOGIN_PATH = google
vault-login: vault ## Login with Vault using method set by 'VAULT_LOGIN_METHOD'. Default is oidc
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@echo -e "${YELLOW}++ VAULT_ADDR=$(VAULT_ADDR)${RESET}"
	@$(VAULT) login -method=$(VAULT_LOGIN_METHOD) -path=$(VAULT_LOGIN_PATH) -no-print

.PHONY: git
git: chart-values ## Git add, commit, tag and push
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifneq (,$(wildcard charts/))
	git add charts/
endif
	git add $(GIT_ADD_FILES)
	git commit -m "chore(release): $(VERSION)" -m "[$(SKIP_MSG)]"
ifeq (0, $(shell git show-ref --tags v$(VERSION) --quiet || echo 0))
	git tag v$(VERSION)
	git push $(GIT_REMOTE) $(GIT_BRANCH) --tags
else
	git push $(GIT_REMOTE) $(GIT_BRANCH)
endif

.PHONY: set-manager-image
set-manager-image: ## Set manager image using kustomize
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	cd config/manager && kustomize edit set image controller=$(IMG)

.PHONY: skopeo-copy
skopeo-copy: ## Copy images using skopeo
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	# full version
	skopeo copy --retry-times 3 --all --src-tls-verify=$(SKOPEO_SRC_TLS) --dest-tls-verify=$(SKOPEO_DEST_TLS) docker://$(BUILD_IMG) docker://$(IMG)
	# major + minor
	skopeo copy --retry-times 3 --all --src-tls-verify=$(SKOPEO_SRC_TLS) --dest-tls-verify=$(SKOPEO_DEST_TLS) docker://$(BUILD_IMG) docker://$(IMG_MINOR)
	# major
	skopeo copy --retry-times 3 --all --src-tls-verify=$(SKOPEO_SRC_TLS) --dest-tls-verify=$(SKOPEO_DEST_TLS) docker://$(BUILD_IMG) docker://$(IMG_MAJOR)

.PHONY: helmfile-preview
helmfile-preview: chart-values ## Create preview environment using helmfile
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@echo -e "\nCreating preview environment with helmfile..."
	sed -i "s@    - jx-values.yaml@  # - jx-values.yaml@" $(PREVIEW_HELMFILE)
	APP_NAME=$(HELMFILE_APP_NAME) \
	SUBDOMAIN=${HELMFILE_APP_NAME} \
	PREVIEW_NAMESPACE=${HELMFILE_APP_NAME} \
	DOCKER_REGISTRY=$(BUILD_REGISTRY) \
	DOCKER_REGISTRY_ORG=$(BUILD_REGISTRY_ORG) \
	VERSION=$(BUILD_VERSION) \
	helmfile -f $(PREVIEW_HELMFILE) sync
	sed -i "s@  # - jx-values.yaml@    - jx-values.yaml@" $(PREVIEW_HELMFILE)

.PHONY: helmfile-preview-destroy
helmfile-preview-destroy: ## Destroy preview environment using helmfile
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@echo -e "\Destroying preview environment with helmfile..."
	sed -i "s@    - jx-values.yaml@  # - jx-values.yaml@" $(PREVIEW_HELMFILE)
	APP_NAME=$(HELMFILE_APP_NAME) \
	SUBDOMAIN=${HELMFILE_APP_NAME} \
	PREVIEW_NAMESPACE=${HELMFILE_APP_NAME} \
	DOCKER_REGISTRY=$(BUILD_REGISTRY) \
	DOCKER_REGISTRY_ORG=$(BUILD_REGISTRY_ORG) \
	VERSION=$(BUILD_VERSION) \
	helmfile -f $(PREVIEW_HELMFILE) delete
	kubectl delete --ignore-not-found=true --wait=true --timeout=600s ns ${HELMFILE_APP_NAME}
	sed -i "s@  # - jx-values.yaml@    - jx-values.yaml@" $(PREVIEW_HELMFILE)

.PHONY: chart-values
chart-values: ## handle chart values like version, tag and respository
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifeq (0, $(shell test -d  "charts/$(REPO_NAME)"; echo $$?))
	sed -i "s/^version:.*/version: $(VERSION)/" charts/$(REPO_NAME)/Chart.yaml
	sed -i "0,/tag:.*/s@tag:.*@tag: $(VERSION)@" charts/$(REPO_NAME)/values.yaml
	sed -i "0,/repository:.*/s@repository:.*@repository: $(IMAGE_TAG_BASE)@" charts/$(REPO_NAME)/values.yaml
else
	@echo -e "${YELLOW}++ no charts dir to modify${RESET}"
endif

##@ JX


.PHONY: jx-updatebot
jx-updatebot: ## Create PRs in downstream repos with new version using jx
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifeq ($(GIT_RELEASE_BRANCH_NUMBER),)
	jx updatebot pr -c .lighthouse/$(UPDATEBOT_CONFIG_FILE) \
		--commit-title "$(UPDATEBOT_COMMIT_MESSAGE)" \
		--labels test_group \
		--version $(VERSION)
else
	@echo -e "Release branch '$(GIT_BRANCH)', not running updatebot"
endif

.PHONY: jx-changelog
jx-changelog: ## Generate changelog file using jx
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifneq ($(CHANGELOG_PREV_TAG),)
	jx changelog create --verbose --version=$(VERSION) --previous-rev=$(CHANGELOG_PREV_TAG) --rev=$(PULL_BASE_SHA) --output-markdown=$(CHANGELOG_FILE) --update-release=false
else
	jx changelog create --verbose --version=$(VERSION) --rev=$(PULL_BASE_SHA) --output-markdown=$(CHANGELOG_FILE) --update-release=false
endif
	git add $(CHANGELOG_FILE)

.PHONY: jx-preview
jx-preview: chart-values ## Create preview environment using jx
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@echo -e "\nCreating preview environment..."
	VERSION=$(BUILD_VERSION) \
	DOCKER_REGISTRY=$(BUILD_REGISTRY) \
	DOCKER_REGISTRY_ORG=$(BUILD_REGISTRY_ORG) \
	jx preview create -f $(PREVIEW_HELMFILE)

.PHONY: buildx-use
buildx-use: buildx ## Set buildx instance to use
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifneq ($(BUILDX_INSTANE_NAME),)
	docker buildx use $(BUILDX_INSTANE_NAME)
else
	@echo -e "${YELLOW}++ no buildx instance name set${RESET}"
endif

.PHONY: buildx-k8s-multiarch
buildx-k8s-multiarch: buildx ## Create buildx k8s multiarch instance builder
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	docker buildx create --use --bootstrap --append --name=multiarch-builder --platform=linux/amd64 --node=multiarch-builder-amd64-k8s --driver=kubernetes --driver-opt="qemu.install=true,namespace=jx,requests.cpu=100m,requests.memory=500Mi" multiarch-builder-amd64-k8s
	docker buildx create --bootstrap --append --name=multiarch-builder --platform=linux/arm64 --node=multiarch-builder-arm64-k8s --driver=kubernetes --driver-opt="qemu.install=true,namespace=jx,requests.cpu=100m,requests.memory=500Mi" multiarch-builder-arm64-k8s

ifneq (,$(wildcard $(MK_TARGET_CUSTOM_FILE)))
include $(MK_TARGET_CUSTOM_FILE)
endif

include $(MK_TARGET_EXTRA_FILE)
