##@ Kio Web App


## Download files
PHONY: config-js-download-if
config-js-download-if: vault ## download and overwrite config.js file for kio web app api, but only if it does not exist on disk
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifeq (,$(wildcard .env))
	@echo -e "${YELLOW}++ VAULT_ADDR=$(VAULT_ADDR)${RESET}"
	@$(VAULT) kv get -field config.js kio_secrets/kio-web-app > public/config.js
endif

PHONY: config-js-download
config-js-download: vault ## download and overwrite config.js file for kio web app api
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@echo -e "${YELLOW}++ VAULT_ADDR=$(VAULT_ADDR)${RESET}"
	@$(VAULT) kv get -field config.js kio_secrets/kio-web-app > public/config.js
