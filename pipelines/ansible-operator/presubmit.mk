.PHONY: lint
lint: MOLECULE_SEQUENCE = lint
lint: molecule ## Run linting tasks

.PHONY: k8s
k8s: pr ## Run k8s tasks

.PHONY: pr
pr: collection-build buildx-image molecule ## Run pr tasks
