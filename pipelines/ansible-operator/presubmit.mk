.PHONY: multiarch-image
multiarch-image: buildx-k8s-multiarch buildx-image ## Multiarch image build with buildx

.PHONY: lint
lint: MOLECULE_SEQUENCE = lint
lint: molecule ## Run linting tasks
