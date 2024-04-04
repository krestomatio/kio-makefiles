ifneq (,$(wildcard $(MK_VARS_PROJECT_FILE)))
include $(MK_VARS_PROJECT_FILE)
endif
ifneq (,$(wildcard $(MK_VARS_PROJECT_TYPE_FILE)))
include $(MK_VARS_PROJECT_TYPE_FILE)
endif

VERSION ?= 0.0.1

# Operator
OPERATOR_SHORTNAME ?= $(PROJECT_SHORTNAME)
OPERATOR_NAME ?= $(OPERATOR_SHORTNAME)-operator
OPERATOR_TYPE ?= ansible
export OPERATOR_IMAGE ?= $(BUILD_IMG)

# Repo
REPO_NAME ?= $(OPERATOR_NAME)
REPO_OWNER ?= krestomatio

# Image
REGISTRY ?= quay.io
REGISTRY_PATH ?= $(REGISTRY)/$(REPO_OWNER)
REGISTRY_PROJECT_NAME ?= $(REPO_NAME)
IMAGE_TAG_BASE ?= $(REGISTRY_PATH)/$(REGISTRY_PROJECT_NAME)
IMG ?= $(IMAGE_TAG_BASE):$(VERSION)
IMG_MINOR ?= $(IMAGE_TAG_BASE):$(word 1,$(subst ., ,$(VERSION))).$(word 2,$(subst ., ,$(VERSION)))
IMG_MAJOR ?= $(IMAGE_TAG_BASE):$(word 1,$(subst ., ,$(VERSION)))

# requirements
CONTAINER_BUILDER ?= docker
OPERATOR_VERSION ?= 1.33.0
KUSTOMIZE_VERSION ?= 5.0.1
SKAFFOLD_VERSION ?= 1.35.2
K8S_VERSION ?= 1.26.6
KUBECTL_VERSION ?= $(K8S_VERSION)
KIND_VERSION ?= 0.20.0
export KIND_IMAGE_VERSION ?= $(K8S_VERSION)
G12E_VERSION ?= 2.0.9
FRPC_VERSION ?= 0.50.0
ENVCONSUL_VERSION ?= 0.13.2

# OS
OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH := $(shell uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/')
CWD := $(shell pwd)
LOCAL_BIN ?= ./bin
PATH := $(PATH):$(LOCAL_BIN)

# JX
JOB_NAME ?= pr
PULL_NUMBER ?= 0
BUILD_ID ?= 0
PULL_BASE_REF ?= HEAD
PULL_BASE_SHA ?= HEAD
PULL_PULL_SHA ?= HEAD
UPDATEBOT_CONFIG_FILE ?= updatebot.yaml
UPDATEBOT_COMMIT_MESSAGE ?= chore(update): bump $(REPO_NAME) $(VERSION)

# Build
BUILD_REGISTRY ?= harbor.krestomat.io
BUILD_REGISTRY_ORG ?= kio-builds
BUILD_REGISTRY_PATH ?= $(BUILD_REGISTRY)/$(BUILD_REGISTRY_ORG)
BUILD_REGISTRY_PROJECT_NAME ?= $(REGISTRY_PROJECT_NAME)
BUILD_IMAGE_TAG_BASE ?= $(BUILD_REGISTRY_PATH)/$(BUILD_REGISTRY_PROJECT_NAME)
ifeq ($(JOB_NAME),release)
## if release job, try to get merge commit, otherwise use HEAD
BUILD_VERSION ?= $(shell git rev-parse $${PULL_BASE_SHA:-HEAD}^2 2>/dev/null 1>/dev/null && git rev-parse $${PULL_BASE_SHA:-HEAD}^2 || { git rev-parse HEAD 2>/dev/null || echo build; })
else
BUILD_VERSION ?= $(shell git rev-parse $${PULL_PULL_SHA:-HEAD} 2>/dev/null || echo build)
endif
BUILD_IMG ?= $(BUILD_IMAGE_TAG_BASE):$(BUILD_VERSION)

# CI
SKIP_MSG := skip.ci
RUN_PIPELINE ?= $(shell git log -1 --pretty=%B | cat | grep -q "\[$(SKIP_MSG)\]" && echo || echo 1)
ifeq ($(RUN_PIPELINE),)
SKIP_PIPELINE = true
$(info RUN_PIPELINE not set, skipping...)
endif
ifeq ($(BUILD_VERSION),)
SKIP_PIPELINE = true
$(info BUILD_VERSION not set, skipping...)
endif

# buildx
BUILDX_INSTANE_NAME ?= multiarch-builder
BUILDX_PROGRESS ?= plain

# skopeo
SKOPEO_SRC_TLS ?= True
SKOPEO_DEST_TLS ?= true

# Release
export GIT_AUTHOR_NAME ?= krestomatio-cibot
export GIT_AUTHOR_EMAIL ?= jobcespedes@krestomatio.com
export GIT_COMMITTER_NAME ?= $(GIT_AUTHOR_NAME)
export GIT_COMMITTER_EMAIL ?= $(GIT_AUTHOR_EMAIL)
GIT_REMOTE ?= origin
ifeq ($(PULL_BASE_REF),HEAD)
GIT_BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD 2>/dev/null)
else
GIT_BRANCH ?= $(PULL_BASE_REF)
endif
GIT_LAST_TAG ?= $(shell git describe --tags --abbrev=0 2>/dev/null || echo)
GIT_ADD_FILES ?= Makefile
GIT_RELEASE_BRANCH_NUMBER ?= $(shell echo $(GIT_BRANCH) | grep -qE '^release-([0-9]+)\.([0-9]+)$$' && echo $(GIT_BRANCH:release-%=%) || echo)
CHANGELOG_FILE ?= CHANGELOG.md
ifeq ($(GIT_RELEASE_BRANCH_NUMBER),)
CHANGELOG_PREV_TAG ?= $(GIT_LAST_TAG)
HELMFILE_APP_NAME ?= $(REPO_NAME)
else
ifndef GIT_RELEASE_LAST_TAG
$(error release branch but GIT_RELEASE_LAST_TAG is undefined)
endif
CHANGELOG_PREV_TAG ?= $(GIT_RELEASE_LAST_TAG)
HELMFILE_APP_NAME ?= $(REPO_NAME).$(GIT_RELEASE_BRANCH_NUMBER)
endif
ifeq ($(JOB_NAME),release)
PREVIEW_HELMFILE ?= preview/helmfile.yaml
else
PREVIEW_HELMFILE ?= preview/helmfile-$(JOB_NAME).yaml
endif

# Molecule
ifeq ($(PULL_NUMBER),)
TEST_SUBINDEX := 0
else ifeq ($(PULL_NUMBER),0)
TEST_SUBINDEX := 0
else
TEST_SUBINDEX := $(shell date +%s | tail -c 3)
endif
export TEST_OPERATOR_NAMEPREFIX ?= $(OPERATOR_SHORTNAME)-$(JOB_NAME)-$(PULL_NUMBER)-$(TEST_SUBINDEX)-
export TEST_OPERATOR_NAMESPACE ?= $(OPERATOR_SHORTNAME)-$(JOB_NAME)-$(PULL_NUMBER)-$(TEST_SUBINDEX)-ns
export TEST_OPERATOR_OMIT_KIND_DELETION_LIST ?= CustomResourceDefinition
export TEST_OPERATOR_SHORTNAME ?= $(OPERATOR_SHORTNAME)

# CSI NFS
ifeq ($(PROJECT_SHORTNAME),nfs)
CSI_NFS_BASE_URL_INSTALL ?= config/csi-driver-nfs
else
CSI_NFS_BASE_URL_INSTALL ?= github.com/krestomatio/nfs-operator/config/csi-driver-nfs?ref=master
endif

## VAULT
export VAULT_ADDR ?= https://vault.krestomat.io
VAULT_VERSION ?= 1.9.3
VAULT_INTERNAL_MOUNT_POINT ?= kio-internal
VAULT_LOCAL_MOUNT_POINT ?= kio-web-app-local

## Makejinja
MAKEJINJA_DOCS_DATA ?= -D operator_version=$(VERSION)

# colors
## from https://gist.github.com/rsperl/d2dfe88a520968fbc1f49db0a29345b9
## define standard colors
ifneq (,$(findstring xterm,${TERM}))
	BLACK        := $(shell tput -Txterm setaf 0)
	RED          := $(shell tput -Txterm setaf 1)
	GREEN        := $(shell tput -Txterm setaf 2)
	YELLOW       := $(shell tput -Txterm setaf 3)
	LIGHTPURPLE  := $(shell tput -Txterm setaf 4)
	PURPLE       := $(shell tput -Txterm setaf 5)
	BLUE         := $(shell tput -Txterm setaf 6)
	WHITE        := $(shell tput -Txterm setaf 7)
	RESET := $(shell tput -Txterm sgr0)
else
	BLACK        := ""
	RED          := ""
	GREEN        := ""
	YELLOW       := ""
	LIGHTPURPLE  := ""
	PURPLE       := ""
	BLUE         := ""
	WHITE        := ""
	RESET        := ""
endif
