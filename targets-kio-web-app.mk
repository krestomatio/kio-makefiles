##@ Kio Web App

buildah-build: ## Build the container image using buildah
	@echo "+ $@"
	@echo -e "\nBuilding container image..."
	buildah --storage-driver vfs bud -t $(IMG) .


buildah-push: ## Push the container image using buildah
	@echo "+ $@"
	@echo -e "\nPushing container image..."
	buildah --storage-driver vfs push $(IMG)
