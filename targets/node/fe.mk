##@ Kio Web App


## Download files
PHONY: config-js-download-if
config-js-download-if: vault ## download config.js file for kio web app api, but only if it does not exist on disk
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifeq (,$(wildcard public/config.js))
	@$(MAKE) config-js-download
endif

PHONY: config-js-download
config-js-download: vault ## download and overwrite config.js file for kio web app api
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@echo -e "${YELLOW}++ VAULT_ADDR=$(VAULT_ADDR)${RESET}"
	$(call vault-save-secret-field-in-file,config.js,$(VAULT_LOCAL_MOUNT_POINT)/config/fe/svelte,public/config.js)
