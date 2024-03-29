# molecule
MOLECULE_SEQUENCE ?= test
MOLECULE_SCENARIO ?= default

# krestomatio ansible collection
COLLECTION_VERSION ?= 0.0.1
export COLLECTION_FILE ?= krestomatio-k8s-$(COLLECTION_VERSION).tar.gz

# Release
GIT_ADD_FILES ?= Makefile config/manager/kustomization.yaml docs/
