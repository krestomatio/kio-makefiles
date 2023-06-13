.PHONY: multiarch-image
multiarch-image: buildx-image ## Multiarch image build with buildx

.PHONY: pr-preview
pr-preview: jx-preview ## Create preview using JX

.PHONY: lint
lint: npm-ci npx-commitlint npm-lint ## Project linting pipeline
