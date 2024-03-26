##@ Collection

GALAXY_COLLECTION_NAME ?= krestomatio-k8s-$(VERSION)
GALAXY_COLLECTION_FILE ?= $(GALAXY_COLLECTION_NAME).tar.gz

.PHONY: build-docs
build-docs: ## Build docs
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	pip install -r .ansible-ci/requirements.txt
	ansible-playbook .ansible-ci/docs.yml -i .ansible-ci/inventory/hosts
	git add docs

.PHONY: galaxy-version
galaxy-version: ## Bump galaxy version
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	sed -i "s/^version:.*/version: $(VERSION)/" galaxy.yml
	git add galaxy.yml

.PHONY: galaxy-publish
galaxy-publish: ## Publish galaxy collection
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	ansible-galaxy collection build --force
	@echo -e "${YELLOW}++ ansible-galaxy collection publish krestomatio-k8s-$(VERSION).tar.gz${RESET}"
	@ansible-galaxy collection publish krestomatio-k8s-$(VERSION).tar.gz --api-key $(ANSIBLE_GALAXY_TOKEN)

.PHONY: ansible-lint
ansible-lint: ## Ansible linting
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	ansible-lint roles/

##@ Tests


.PHONY: test-sanity
test-sanity: ## Run sanity test with ansible-test
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	ansible-test sanity --docker default
