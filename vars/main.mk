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

# Repo
REPO_NAME ?= $(OPERATOR_NAME)
REPO_OWNER ?= krestomatio

# Image
REGISTRY ?= quay.io
REGISTRY_PATH ?= $(REGISTRY)/$(REPO_OWNER)
REGISTRY_PROJECT_NAME ?= $(REPO_NAME)
IMAGE_TAG_BASE ?= $(REGISTRY_PATH)/$(REGISTRY_PROJECT_NAME)
IMG ?= $(IMAGE_TAG_BASE):$(VERSION)

# requirements
CONTAINER_BUILDER ?= docker
OPERATOR_VERSION ?= 1.15.0
KUSTOMIZE_VERSION ?= 4.1.3
OPM_VERSION ?= 1.15.1
SKAFFOLD_VERSION ?= 1.35.2
K8S_VERSION ?= 1.20.7
KUBECTL_VERSION ?= $(K8S_VERSION)
KIND_VERSION ?= 0.11.1
KIND_IMAGE_VERSION ?= $(K8S_VERSION)
G12E_VERSION ?= 2.0.9

# OS
OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH := $(shell uname -m | sed 's/x86_64/amd64/')
CWD := $(shell pwd)
LOCAL_BIN ?= ./bin
PATH := $(PATH):$(LOCAL_BIN)

# JX
JOB_NAME ?= pr
PULL_NUMBER ?= 0
BUILD_ID ?= 0
PULL_BASE_SHA ?= HEAD
PULL_PULL_SHA ?= HEAD
UPDATEBOT_CONFIG_FILE ?= updatebot.yaml
UPDATEBOT_COMMIT_MESSAGE ?= chore(update): bump $(REPO_NAME) $(VERSION)

# Build
BUILD_REGISTRY ?= docker-registry.jx.krestomat.io
BUILD_REGISTRY_PATH ?= $(BUILD_REGISTRY)/krestomatio
BUILD_REGISTRY_PROJECT_NAME ?= $(REGISTRY_PROJECT_NAME)
BUILD_IMAGE_TAG_BASE ?= $(BUILD_REGISTRY_PATH)/$(BUILD_REGISTRY_PROJECT_NAME)
ifeq ($(JOB_NAME),release)
BUILD_VERSION ?= $(shell git rev-parse HEAD^2 2>\&1 >/dev/null && git rev-parse HEAD^2 || echo)
else
BUILD_VERSION ?= $(shell git rev-parse $(PULL_PULL_SHA) 2> /dev/null  || echo)
endif

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
LAST_TAG ?= $(shell git describe --tags --abbrev=0 2> /dev/null || echo)

# molecule
MOLECULE_SEQUENCE ?= test
MOLECULE_SCENARIO ?= default
ifeq ($(PULL_NUMBER),0)
TEST_SUBINDEX := 0
else
TEST_SUBINDEX := $(shell date +%s | tail -c 3)
endif
export OPERATOR_IMAGE ?= $(IMG)
export TEST_OPERATOR_NAMEPREFIX ?= $(OPERATOR_SHORTNAME)-$(JOB_NAME)-$(PULL_NUMBER)-$(TEST_SUBINDEX)-
export TEST_OPERATOR_NAMESPACE ?= $(OPERATOR_SHORTNAME)-$(JOB_NAME)-$(PULL_NUMBER)-$(TEST_SUBINDEX)-ns
export TEST_OPERATOR_OMIT_CRDS_DELETION ?= true
export TEST_OPERATOR_SHORTNAME ?= $(OPERATOR_SHORTNAME)

# skopeo
SKOPEO_SRC_TLS ?= True
SKOPEO_DEST_TLS ?= true

# Release
GIT_REMOTE ?= origin
ifneq ($(origin PULL_BASE_REF),undefined)
GIT_BRANCH ?= $(PULL_BASE_REF)
else
GIT_BRANCH ?= $(shell git branch 2>/dev/null | grep -q '\bmain\b' && echo main || echo master)
endif
GIT_ADD_FILES ?= Makefile config/manager/kustomization.yaml
CHANGELOG_FILE ?= CHANGELOG.md
RELEASE_BRANCH_REGEX ?= ^release-([0-9]+)\.([0-9]+)$$

# krestomatio ansible collection
COLLECTION_VERSION ?= 0.0.1
export COLLECTION_FILE ?= krestomatio-k8s-$(COLLECTION_VERSION).tar.gz

## npx commitlint
ifeq ($(PULL_BASE_SHA),HEAD)
COMMITLINT_FROM ?= HEAD~1
else
COMMITLINT_FROM ?= $(shell echo "HEAD~$$(git rev-list --count $(PULL_BASE_SHA)...HEAD)")
endif
COMMITLINT_TO ?= $(PULL_PULL_SHA)

## VAULT
export VAULT_ADDR ?= https://vault.jx.krestomat.io
VAULT_VERSION ?= 1.9.3

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
