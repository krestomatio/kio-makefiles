##@ Ansible

.PHONY: molecule
molecule: ## Testing with molecule
	@echo "+ $@"
	molecule $(MOLECULE_SEQUENCE) -s $(MOLECULE_SCENARIO)

collection-build: ## Build krestomatio collection from path or git to file
	@echo "+ $@"
	rm -rf *.tar.gz /tmp/ansible-collection-k8s*
ifeq (0, $(shell test -d  "$${HOME}/.ansible/collections/ansible_collections/krestomatio/k8s"; echo $$?))
	cp -rp ~/.ansible/collections/ansible_collections/krestomatio/k8s /tmp/ansible-collection-k8s-$(COLLECTION_VERSION)
else
	curl -L https://github.com/krestomatio/ansible-collection-k8s/archive/v$(COLLECTION_VERSION).tar.gz | tar xzf - -C /tmp/
endif
	ansible-galaxy collection build --force /tmp/ansible-collection-k8s-$(COLLECTION_VERSION)
	test -f $(COLLECTION_FILE) || mv krestomatio-k8s-*.tar.gz $(COLLECTION_FILE)
ifneq (0, $(shell test -d  "$${HOME}/.ansible/collections/ansible_collections/krestomatio/k8s"; echo $$?))
	mkdir -p $${HOME}/.ansible/collections/ansible_collections/krestomatio/
	cp -rp /tmp/ansible-collection-k8s-$(COLLECTION_VERSION) ~/.ansible/collections/ansible_collections/krestomatio/k8s
endif

ifneq (0, $(shell test -d  "$${HOME}/.ansible/collections/ansible_collections/krestomatio/k8s"; echo $$?))
collection-install: collection-build
collection-install:
	@echo "+ $@"
	mkdir -p $${HOME}/.ansible/collections/ansible_collections/krestomatio/
	cp -rp /tmp/ansible-collection-k8s-$(COLLECTION_VERSION) ~/.ansible/collections/ansible_collections/krestomatio/k8s
else
collection-install: ## Install krestomatio collection from git
	@echo "+ $@"
	$(info krestomatio collection already installed...)
endif
