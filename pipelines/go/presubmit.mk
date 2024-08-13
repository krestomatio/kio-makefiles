.PHONY: multiarch-image
multiarch-image: buildx-use buildx-image ## Multiarch image build with buildx

.PHONY: lint
lint: go-lint ## Run linting tasks

.PHONY: pr
pr: ## Run pr tasks
