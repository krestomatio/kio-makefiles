.PHONY: multiarch-image
multiarch-image: buildx-use buildx-image ## Multiarch image build with buildx

.PHONY: lint
lint: ansible-lint ## Run linting tasks
