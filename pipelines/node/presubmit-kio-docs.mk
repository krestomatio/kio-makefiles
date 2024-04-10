.PHONY: multiarch-image
multiarch-image: buildx-use buildx-image ## Multiarch image build with buildx

.PHONY: pr
pr: sync-docs multiarch-image ## Run pr tasks
