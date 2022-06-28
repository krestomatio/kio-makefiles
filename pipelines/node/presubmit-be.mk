.PHONY: multiarch-image
multiarch-image: buildx-k8s-multiarch buildx-image ## Multiarch image build with buildx

.PHONY: pr-preview
pr-preview: jx-preview ## Create preview using JX

.PHONY: lint
lint: npm-ci npm-lint ## Project linting pipeline
