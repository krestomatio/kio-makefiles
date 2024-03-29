# node
NVM_VERSION ?= 0.39.1

# npx commitlint
ifeq ($(PULL_BASE_SHA),HEAD)
COMMITLINT_FROM ?= HEAD~1
else
COMMITLINT_FROM ?= $(shell echo "HEAD~$$(git rev-list --count $(PULL_BASE_SHA)...HEAD)")
endif
COMMITLINT_TO ?= $(PULL_PULL_SHA)

# Release
GIT_ADD_FILES ?= Makefile package.json

# frp
export FRP_PROXY_NAME_SUFFIX ?= _$(shell echo $${FRP_SUBDOMAIN:-$$HOSTNAME} | md5sum | cut -c -5)
FRPC_INI_SUBDOMAIN_INFO ?= <subdomain>
FRPC_INI_DEST ?= $(FRPC_INI_VAULT_KEY)
