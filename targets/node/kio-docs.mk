##@ Kio Docs


define fetch-repo-docs-folder
@echo -e "${YELLOW}++ fetching repo $(1) with ref $(2) and path $(3) to $(4)${RESET}"
rm -rf '.temp-docs'
fetch --repo=$(1) --ref=$(2) --source-path=$(3) '.temp-docs'
rsync -a --delete --exclude="_category_.json" --exclude="_category_.yml" '.temp-docs/' $(4)
rm -rf '.temp-docs'
endef

PHONY: sync-docs
sync-docs: fetch ## Sync docs from remotes
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	$(call fetch-repo-docs-folder,'https://github.com/krestomatio/container_builder','v$(CONTAINER_BUILDER_VERSION)','/docs','docs/container_builder')
	$(call fetch-repo-docs-folder,'https://github.com/krestomatio/moodle-operator','v$(MOODLE_OPERATOR_VERSION)','/docs','docs/moodle-operator')
	$(call fetch-repo-docs-folder,'https://github.com/krestomatio/postgres-operator','v$(POSTGRES_OPERATOR_VERSION)','/docs','docs/postgres-operator')
	$(call fetch-repo-docs-folder,'https://github.com/krestomatio/keydb-operator','v$(KEYDB_OPERATOR_VERSION)','/docs','docs/keydb-operator')
	$(call fetch-repo-docs-folder,'https://github.com/krestomatio/nfs-operator','v$(NFS_OPERATOR_VERSION)','/docs','docs/nfs-operator')
	$(call fetch-repo-docs-folder,'https://github.com/krestomatio/lms-moodle-operator','v$(LMS_MOODLE_OPERATOR_VERSION)','/docs','docs/lms-moodle-operator')
	$(call fetch-repo-docs-folder,'https://github.com/krestomatio/ansible-collection-k8s','v$(ANSIBLE_COLLECTION_K8S_VERSION)','/docs','docs/ansible-collection-k8s')
