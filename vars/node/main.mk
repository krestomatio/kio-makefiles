## npx commitlint
ifeq ($(PULL_BASE_SHA),HEAD)
COMMITLINT_FROM ?= HEAD~1
else
COMMITLINT_FROM ?= $(shell echo "HEAD~$$(git rev-list --count $(PULL_BASE_SHA)...HEAD)")
endif
COMMITLINT_TO ?= $(PULL_PULL_SHA)

# Release
GIT_ADD_FILES ?= Makefile package.json
