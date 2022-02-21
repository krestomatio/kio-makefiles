##@ Kio Web App


## Download files
config-js-download-if: vault ## download and overwrite config.js file for kio web app api, but only if it does not exist on disk
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifeq (,$(wildcard .env))
	vault kv get -field kio-api-env kio_secrets/kio-web-app > public/config.js
endif

config-js-download: vault ## download and overwrite config.js file for kio web app api
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	vault kv get -field kio-api-env kio_secrets/kio-web-app > public/config.js
