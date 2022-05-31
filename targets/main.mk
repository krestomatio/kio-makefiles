ifneq (,$(wildcard $(MK_TARGETS_PROJECT_FILE)))
include $(MK_TARGETS_PROJECT_FILE)
endif
ifneq (,$(wildcard $(MK_TARGETS_PROJECT_TYPE_FILE)))
include $(MK_TARGETS_PROJECT_TYPE_FILE)
endif

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
ifeq (,$(shell pidof dockerd))
	@echo -e "${YELLOW}++ starting dockerd in the backgroud...${RESET}"
	dockerd-entrypoint.sh &> /tmp/dockerd.log &
	@sleep 4
else
	@echo -e "${YELLOW}++ dockerd already running...${RESET}"
endif

.PHONY: image-build
image-build: ## Build container image with the manager.
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifeq ($(PROJECT_TYPE),ansible-operator)
	$(CONTAINER_BUILDER) build . -t $(IMG) \
		--build-arg COLLECTION_FILE=$(COLLECTION_FILE)
else
	$(CONTAINER_BUILDER) build . -t $(IMG)
endif

.PHONY: image-push
image-push: ## Push container image with the manager.
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	$(CONTAINER_BUILDER) push $(IMG)

.PHONY: buildah-build
buildah-build: ## Build the container image using buildah
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifeq ($(PROJECT_TYPE),ansible-operator)
	buildah --storage-driver vfs bud -t $(IMG) . \
		--build-arg COLLECTION_FILE=$(COLLECTION_FILE)
else
	buildah --storage-driver vfs bud -t $(IMG) .
endif

.PHONY: buildah-push
buildah-push: ## Push the container image using buildah
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	buildah --storage-driver vfs push $(IMG)

.PHONY: testing-image
testing-image: IMG = $(BUILD_IMAGE_TAG_BASE):$(BUILD_VERSION)
testing-image: image-build image-push ## Build and push testing image

.PHONY: testing-buildah-image
testing-buildah-image: IMG = $(BUILD_IMAGE_TAG_BASE):$(BUILD_VERSION)
testing-buildah-image: buildah-build buildah-push ## Build and push testing image using buildah

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

.PHONY: konfig
KONFIG = $(LOCAL_BIN)/konfig
konfig: ## Download konfig locally if necessary.
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifeq (,$(wildcard $(KONFIG)))
ifeq (,$(shell which konfig 2>/dev/null))
	@echo -e "${YELLOW}++ Downloading konfig to $(KONFIG)${RESET}"
	@{ \
	set -e ;\
	mkdir -p $(dir $(KONFIG)) ;\
	curl -sSL https://github.com/corneliusweig/konfig/raw/v$(KONFIG_VERSION)/konfig -o $(KONFIG) ;\
	chmod +x $(KONFIG) ;\
	}
else
KONFIG = $(shell which konfig)
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
	@$(KUBECTL) config use-context kind-$(KIND_CLUSTER_NAME)
	@$(KUBECTL) config set-context --current --namespace=$(KIND_NAMESPACE)

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

.PHONY: deploy-csi-nfs
deploy-csi-nfs: ## Deploy CSI NFS to the K8s cluster specified in ~/.kube/config.
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@echo -e "${YELLOW}++ installing CSI NFS${RESET}"
	@$(KUBECTL) apply -f $(CSI_NFS_BASE_URL_INSTALL)/rbac-csi-nfs-controller.yaml
	@$(KUBECTL) apply -f $(CSI_NFS_BASE_URL_INSTALL)/csi-nfs-driverinfo.yaml
	@$(KUBECTL) patch --dry-run=client -o json -f $(CSI_NFS_BASE_URL_INSTALL)/csi-nfs-controller.yaml -p '{"spec":{"template":{"spec":{"dnsPolicy":"ClusterFirstWithHostNet"}}}}' | kubectl apply -f -
	@$(KUBECTL) patch --dry-run=client -o json -f $(CSI_NFS_BASE_URL_INSTALL)/csi-nfs-node.yaml -p '{"spec":{"template":{"spec":{"dnsPolicy":"ClusterFirstWithHostNet"}}}}' | kubectl apply -f -

.PHONY: undeploy-csi-nfs
undeploy-csi-nfs: ## Undeploy CSI NFS from the K8s cluster specified in ~/.kube/config.
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@$(KUBECTL) delete --ignore-not-found=true -f $(CSI_NFS_BASE_URL_INSTALL)/rbac-csi-nfs-controller.yaml
	@$(KUBECTL) delete --ignore-not-found=true -f $(CSI_NFS_BASE_URL_INSTALL)/csi-nfs-driverinfo.yaml
	@$(KUBECTL) delete --ignore-not-found=true -f $(CSI_NFS_BASE_URL_INSTALL)/csi-nfs-controller.yaml
	@$(KUBECTL) delete --ignore-not-found=true -f $(CSI_NFS_BASE_URL_INSTALL)/csi-nfs-node.yaml

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
	cd config/manager && kustomize edit set image controller=$(IMAGE_TAG_BASE):$(VERSION)

.PHONY: skopeo-copy
skopeo-copy: ## Copy images using skopeo
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	# full version
	skopeo copy --src-tls-verify=$(SKOPEO_SRC_TLS) --dest-tls-verify=$(SKOPEO_DEST_TLS) docker://$(BUILD_IMAGE_TAG_BASE):$(BUILD_VERSION) docker://$(IMAGE_TAG_BASE):$(VERSION)
	# major + minor
	skopeo copy --src-tls-verify=$(SKOPEO_SRC_TLS) --dest-tls-verify=$(SKOPEO_DEST_TLS) docker://$(BUILD_IMAGE_TAG_BASE):$(BUILD_VERSION) docker://$(IMAGE_TAG_BASE):$(word 1,$(subst ., ,$(VERSION))).$(word 2,$(subst ., ,$(VERSION)))
	# major
	skopeo copy --src-tls-verify=$(SKOPEO_SRC_TLS) --dest-tls-verify=$(SKOPEO_DEST_TLS) docker://$(BUILD_IMAGE_TAG_BASE):$(BUILD_VERSION) docker://$(IMAGE_TAG_BASE):$(word 1,$(subst ., ,$(VERSION)))

.PHONY: helmfile-preview
helmfile-preview: chart-values ## Create preview environment using helmfile
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@echo -e "\nCreating preview environment with helmfile..."
	sed -i "s@    - jx-values.yaml@  # - jx-values.yaml@" preview/helmfile.yaml
	APP_NAME=$(HELMFILE_APP_NAME) \
	SUBDOMAIN=${HELMFILE_APP_NAME} \
	PREVIEW_NAMESPACE=${HELMFILE_APP_NAME} \
	DOCKER_REGISTRY=$(BUILD_REGISTRY) \
	DOCKER_REGISTRY_ORG=$(REPO_OWNER) \
	VERSION=$(BUILD_VERSION) \
	helmfile -f preview sync
	sed -i "s@  # - jx-values.yaml@    - jx-values.yaml@" preview/helmfile.yaml

.PHONY: helmfile-preview-destroy
helmfile-preview-destroy: ## Destroy preview environment using helmfile
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@echo -e "\Destroying preview environment with helmfile..."
	sed -i "s@    - jx-values.yaml@  # - jx-values.yaml@" preview/helmfile.yaml
	APP_NAME=$(HELMFILE_APP_NAME) \
	SUBDOMAIN=${HELMFILE_APP_NAME} \
	PREVIEW_NAMESPACE=${HELMFILE_APP_NAME} \
	DOCKER_REGISTRY=$(BUILD_REGISTRY) \
	DOCKER_REGISTRY_ORG=$(REPO_OWNER) \
	VERSION=$(BUILD_VERSION) \
	helmfile -f preview delete
	kubectl delete --ignore-not-found=true --wait=true --timeout=600s ns ${HELMFILE_APP_NAME}
	sed -i "s@  # - jx-values.yaml@    - jx-values.yaml@" preview/helmfile.yaml

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
	jx preview create

ifneq (,$(wildcard $(MK_TARGET_CUSTOM_FILE)))
include $(MK_TARGET_CUSTOM_FILE)
endif

include $(MK_TARGET_EXTRA_FILE)
