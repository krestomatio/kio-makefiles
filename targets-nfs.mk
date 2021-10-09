##@ Nfs
deploy-rook: kustomize ## Deploy rook nfs operator to the K8s cluster specified in ~/.kube/config.
	@echo "+ $@"
	cd config/manager && $(KUSTOMIZE) edit set image controller=${IMG}
	$(KUSTOMIZE) build config/rook | kubectl apply -f -

undeploy-rook: ## Undeploy rook nfs operator from the K8s cluster specified in ~/.kube/config.
	@echo "+ $@"
	$(KUSTOMIZE) build config/rook | kubectl delete --ignore-not-found=true -f -
