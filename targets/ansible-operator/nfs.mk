##@ Nfs


deploy-csi-nfs: ## Deploy CSI NFS to the K8s cluster specified in ~/.kube/config.
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	$(info installing CSI NFS)
	kubectl apply -f $(CSI_NFS_BASE_URL_INSTALL)/rbac-csi-nfs-controller.yaml
	kubectl apply -f $(CSI_NFS_BASE_URL_INSTALL)/csi-nfs-driverinfo.yaml
	kubectl apply -f $(CSI_NFS_BASE_URL_INSTALL)/csi-nfs-controller.yaml
	kubectl apply -f $(CSI_NFS_BASE_URL_INSTALL)/csi-nfs-node.yaml

undeploy-csi-nfs: ## Undeploy CSI NFS from the K8s cluster specified in ~/.kube/config.
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	kubectl delete --ignore-not-found=true -f $(CSI_NFS_BASE_URL_INSTALL)/rbac-csi-nfs-controller.yaml
	kubectl delete --ignore-not-found=true -f $(CSI_NFS_BASE_URL_INSTALL)/csi-nfs-driverinfo.yaml
	kubectl delete --ignore-not-found=true -f $(CSI_NFS_BASE_URL_INSTALL)/csi-nfs-controller.yaml
	kubectl delete --ignore-not-found=true -f $(CSI_NFS_BASE_URL_INSTALL)/csi-nfs-node.yaml
