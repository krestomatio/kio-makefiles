# molecule
MOLECULE_SEQUENCE ?= test
MOLECULE_SCENARIO ?= default
ifeq ($(PULL_NUMBER),)
TEST_SUBINDEX := 0
else ifeq ($(PULL_NUMBER),0)
TEST_SUBINDEX := 0
else
TEST_SUBINDEX := $(shell date +%s | tail -c 3)
endif
export OPERATOR_IMAGE ?= $(IMG)
export TEST_OPERATOR_NAMEPREFIX ?= $(OPERATOR_SHORTNAME)-$(JOB_NAME)-$(PULL_NUMBER)-$(TEST_SUBINDEX)-
export TEST_OPERATOR_NAMESPACE ?= $(OPERATOR_SHORTNAME)-$(JOB_NAME)-$(PULL_NUMBER)-$(TEST_SUBINDEX)-ns
export TEST_OPERATOR_OMIT_CRDS_DELETION ?= true
export TEST_OPERATOR_SHORTNAME ?= $(OPERATOR_SHORTNAME)

# krestomatio ansible collection
COLLECTION_VERSION ?= 0.0.1
export COLLECTION_FILE ?= krestomatio-k8s-$(COLLECTION_VERSION).tar.gz

# Release
GIT_ADD_FILES ?= Makefile config/manager/kustomization.yaml

# NFS
CSI_NFS_VERSION ?= 4.0.0
CSI_NFS_BASE_URL_INSTALL ?= https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/v$(CSI_NFS_VERSION)/deploy
