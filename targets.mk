MK_TARGET_EXTRA_FILE ?= $(MK_INCLUDE_DIR)/targets-$(PROJECT_TYPE).mk
MK_TARGET_CUSTOM_FILE ?= $(MK_INCLUDE_DIR)/targets-$(PROJECT_SHORTNAME).mk

ifeq ($(origin OPERATOR_TYPE),undefined)
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: kustomize
KUSTOMIZE = $(LOCAL_BIN)/bin/kustomize
kustomize: ## Download kustomize locally if necessary.
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifeq (,$(wildcard $(KUSTOMIZE)))
ifeq (,$(shell which kustomize 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p $(dir $(KUSTOMIZE)) ;\
	curl -sSLo - https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v$(KUSTOMIZE_VERSION)/kustomize_v$(KUSTOMIZE_VERSION)_$(OS)_$(ARCH).tar.gz | \
	tar xzf - -C bin/ ;\
	}
else
KUSTOMIZE = $(shell which kustomize)
endif
endif

endif

##@ Common

image-build: ## Build container image with the manager.
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifeq ($(OPERATOR_TYPE),ansible)
	$(CONTAINER_BUILDER) build . -t $(IMG) \
		--build-arg COLLECTION_FILE=$(COLLECTION_FILE)
else
	$(CONTAINER_BUILDER) build . -t $(IMG)
endif

image-push: ## Push container image with the manager.
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	$(CONTAINER_BUILDER) push $(IMG)

testing-image: IMG = $(BUILD_IMAGE_TAG_BASE):$(BUILD_VERSION)
testing-image: image-build image-push ## Build and push testing image

.PHONY: skaffold
SKAFFOLD = $(LOCAL_BIN)/bin/skaffold
skaffold: ## Download kustomize locally if necessary.
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifeq (,$(wildcard $(SKAFFOLD)))
ifeq (,$(shell which skaffold 2>/dev/null))
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
KUBECTL = $(LOCAL_BIN)/bin/kubectl
kubectl: ## Download kubectl locally if necessary.
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifeq (,$(wildcard $(KUBECTL)))
ifeq (,$(shell which kubectl 2>/dev/null))
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
KIND = $(LOCAL_BIN)/bin/kind
kind: ## Download kind locally if necessary.
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifeq (,$(wildcard $(KIND)))
ifeq (,$(shell which kind 2>/dev/null))
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

.PHONY: git
git: ## Git add, commit, tag and push
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	git add $(GIT_ADD_FILES)
	git commit -m "chore(release): $(VERSION)" -m "[$(SKIP_MSG)]"
	git tag v$(VERSION)
	git push $(GIT_REMOTE) $(GIT_BRANCH) --tags

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

##@ JX

.PHONY: jx-changelog
jx-changelog: ## Generate changelog file using jx
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifeq (0, $(shell test -d  "charts/$(REPO_NAME)"; echo $$?))
	sed -i "s/^version:.*/version: $(VERSION)/" charts/$(REPO_NAME)/Chart.yaml
	sed -i "s/tag:.*/tag: $(VERSION)/" charts/$(REPO_NAME)/values.yaml
	sed -i "s@repository:.*@repository: $(IMAGE_TAG_BASE)@" charts/$(REPO_NAME)/values.yaml
	git add charts/
else
	echo no charts
endif
ifneq ($(LAST_TAG),)
	jx changelog create --verbose --version=$(VERSION) --previous-rev=$(LAST_TAG) --rev=$${PULL_BASE_SHA:-HEAD} --output-markdown=$(CHANGELOG_FILE) --update-release=false
else
	jx changelog create --verbose --version=$(VERSION) --rev=$${PULL_BASE_SHA:-HEAD} --output-markdown=$(CHANGELOG_FILE) --update-release=false
endif
	git add $(CHANGELOG_FILE)

ifneq (,$(wildcard $(MK_TARGET_CUSTOM_FILE)))
include $(MK_TARGET_CUSTOM_FILE)
endif

include $(MK_TARGET_EXTRA_FILE)
