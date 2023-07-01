##@ Node


PHONY: nvm-install
nvm-install: ## Install NVM
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifneq (0, $(shell bash -l -c 'type -t nvm >/dev/null; echo $$?'))
	@{ \
	set -e ;\
	test -f ~/.bash_profile || touch ~/.bash_profile ;\
	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v$(NVM_VERSION)/install.sh | bash ;\
	}
endif
	@echo -e "\nRunning 'nvm install':"
	@bash -l -c 'pushd /tmp/ && source "$(HOME)/.nvm/nvm.sh" && popd && nvm install'
	@[ -f $(HOME)/.bash_profile ] && [ ! -s $(HOME)/.bash_profile ] && rm $(HOME)/.bash_profile || true

PHONY: npm-install
npm-install: ## Install NPM
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@echo -e "\nRunning 'npm install':"
	@bash -l -c 'npm install'

PHONY: npm-ci
npm-ci: ## Install NPM for Continous Integration (CI)
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@echo -e "\nRunning 'npm ci':"
	@bash -l -c 'npm ci'

PHONY: npm-start
npm-start: ## NPM start
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@echo -e "\nRunning 'npm run start':"
	@bash -l -c 'npm run start'

PHONY: npm-build
npm-build: ## NPM build
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@echo -e "\nRunning 'npm run build':"
	@bash -l -c 'npm run build'

PHONY: npx-commitlint
npx-commitlint: ## NPX commit linting
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@echo -e "\nRunning 'npx commitlint':"
	@bash -l -c 'npx commitlint --from $(COMMITLINT_FROM) --to $(COMMITLINT_TO) --verbose'

PHONY: npm-lint
npm-lint: ## NPM linting
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@echo -e "\nRunning 'npm run lint':"
	@bash -l -c 'npm run lint'

PHONY: npm-pretty
npm-pretty: ## NPM pretty
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@echo -e "\nRunning 'npm run pretty':"
	@bash -l -c 'npm run pretty'


##@ FRP
PHONY: frpc-ini-download-if
frpc-ini-download-if: vault ## download frpc.ini file, but only if it does not exist on disk
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifeq (,$(wildcard $(FRPC_INI_DEST)))
	@$(MAKE) frpc-ini-download
endif

PHONY: frpc-ini-download
frpc-ini-download: vault ## download and overwrite frpc.ini file
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@echo -e "${YELLOW}++ VAULT_ADDR=$(VAULT_ADDR)${RESET}"
	$(call vault-save-secret-field-in-file,$(FRPC_INI_VAULT_KEY),$(FRPC_INI_VAULT_PATH),$(FRPC_INI_DEST))

.PHONY: frpc-tunnel-subdomain-env
frpc-tunnel-subdomain-env: ## Update frpc tunnel subdomain var in .env
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifeq (,$(wildcard .env))
	sed -i "s@^FRP_SUBDOMAIN=.*@FRP_SUBDOMAIN=$(FRP_SUBDOMAIN)@" .env
endif

.PHONY: frpc-tunnel
frpc-tunnel: frpc frpc-ini-download-if ## Connect to create a tunnel using frp client
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	@echo -e "${GREEN}+ public url: https://$(FRPC_INI_SUBDOMAIN_INFO).tunnel.jx.krestomat.io${RESET}"
	$(FRPC) -c $(FRPC_INI_DEST)
