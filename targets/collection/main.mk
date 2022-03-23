##@ Collection

GALAXY_COLLECTION_NAME ?= krestomatio-k8s-$(VERSION)
GALAXY_COLLECTION_FILE ?= $(GALAXY_COLLECTION_NAME).tar.gz
GALAXY_COLLECTION_DOWNLOAD_URL ?= https://galaxy.ansible.com/download/$(GALAXY_COLLECTION_FILE)
GALAXY_COLLECTION_PUBLISHED := $(shell curl --output /dev/null --silent --head --fail "$(GALAXY_COLLECTION_DOWNLOAD_URL)" && echo true || echo false)

.PHONY: galaxy-version
galaxy-version: ## Bump galaxy version
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	sed -i "s/^version:.*/version: $(VERSION)/" galaxy.yml
	git add galaxy.yml

.PHONY: galaxy-publish
galaxy-publish: ## Publish galaxy collection
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifeq ($(GALAXY_COLLECTION_PUBLISHED),false)
	ansible-galaxy collection build --force
	$(info ansible-galaxy collection publish krestomatio-k8s-$(VERSION).tar.gz)
	@ansible-galaxy collection publish krestomatio-k8s-$(VERSION).tar.gz --api-key $(ANSIBLE_GALAXY_TOKEN)
else
	@echo -e "not publisging $(GALAXY_COLLECTION_FILE), it already already is"
endif

.PHONY: ansible-lint
ansible-lint: ## Ansible linting
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	ansible-lint roles/

##@ Tests


.PHONY: test-sanity
test-sanity: ## Run sanity test with ansible-test
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	ansible-test sanity --docker default
