.PHONY: lint
lint: go-lint ## Run linting tasks

.PHONY: k8s
k8s: pr ## Run k8s tasks

.PHONY: pr
pr: testing-deploy testing-undeploy ## Run pr tasks
