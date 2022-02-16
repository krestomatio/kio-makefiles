##@ Kio Web App

config-js: ## Inject config.js in helmfile values
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@echo -e "\nInjecting config.js in helmfile values"
	set -u ; echo -e "\npublic_config_js: |\n  $${PUBLIC_CONFIG_JS//$$'\n'/$$'\n'  }" >> preview/values.yaml.gotmpl
	sed -i 's@http://localhost:5000@https://{{ requiredEnv "APP_NAME" }}-{{ requiredEnv "PREVIEW_NAMESPACE" }}.jx.krestomat.io@' preview/values.yaml.gotmpl
