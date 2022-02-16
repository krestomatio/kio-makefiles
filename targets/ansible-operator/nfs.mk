##@ Nfs
deploy-rook: kustomize ## Deploy rook nfs operator to the K8s cluster specified in ~/.kube/config.
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	cd config/manager && $(KUSTOMIZE) edit set image controller=${IMG}
	$(KUSTOMIZE) build config/rook | kubectl apply -f -

undeploy-rook: ## Undeploy rook nfs operator from the K8s cluster specified in ~/.kube/config.
	@echo -e "${LIGHTPURPLE}+ make target: $@${RESET}"
	$(KUSTOMIZE) build config/rook | kubectl delete --ignore-not-found=true -f -
