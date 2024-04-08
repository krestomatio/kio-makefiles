.PHONY: multiarch-image
multiarch-image: buildx-use buildx-image

.PHONY: changelog
changelog: jx-changelog ## Generate changelog

.PHONY: release
release: set-manager-image skopeo-copy bundle-update gen-operators-kustomization gen-docs ## Run release tasks

.PHONY: bundle-catalog
bundle-catalog: bundle-build bundle-push catalog-build catalog-push ## Release bundle and catalog

.PHONY: promote
promote: git ## Promote release
