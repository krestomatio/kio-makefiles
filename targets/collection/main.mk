##@ Collection


.PHONY: galaxy-version
galaxy-version: ## Bump galaxy version
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	sed -i "s/^version:.*/version: $(VERSION)/" galaxy.yml
	git add galaxy.yml

.PHONY: galaxy-publish
galaxy-publish: ## Publish galaxy collection
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	ansible-galaxy collection build --force
	$(info ansible-galaxy collection publish krestomatio-k8s-$(VERSION).tar.gz)
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
