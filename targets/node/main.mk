##@ Node


PHONY: nvm-install
nvm-install: NVM_VERSION ?= $(shell curl -s "https://github.com/nvm-sh/nvm/releases/latest/download" 2>&1 | sed "s/^.*download\/\([^\"]*\).*/\1/")
nvm-install: ## Install NVM
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
ifneq (0, $(shell bash -l -c 'type -t nvm >/dev/null; echo $$?'))
	@{ \
	set -e ;\
	test -f ~/.bash_profile || touch ~/.bash_profile ;\
	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/$(NVM_VERSION)/install.sh | bash ;\
	}
endif
	@echo -e "\nRunning 'nvm install':"
	@bash -l -c 'nvm install'

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
