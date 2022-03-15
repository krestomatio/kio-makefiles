.PHONY: lint
lint: MOLECULE_SEQUENCE = lint
lint: molecule ## Run linting tasks

.PHONY: k8s
k8s: pr ## Run k8s tasks

.PHONY: pr
pr: IMG = $(BUILD_IMAGE_TAG_BASE):$(BUILD_VERSION)
pr: collection-build testing-image testing-deploy-postgres molecule testing-undeploy-postgres ## Run pr tasks
