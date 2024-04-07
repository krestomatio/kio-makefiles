.PHONY: multiarch-image
multiarch-image: buildx-use buildx-image

.PHONY: bundling
bundling: bundle bundle-build bundle-push

.PHONY: changelog
changelog: jx-changelog ## Generate changelog

.PHONY: release
release: set-manager-image build-docs skopeo-copy ## Run release tasks

.PHONY: promote
promote: git ## Promote release
