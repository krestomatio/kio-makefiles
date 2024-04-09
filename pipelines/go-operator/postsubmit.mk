.PHONY: multiarch-image
multiarch-image: buildx-use buildx-image

.PHONY: changelog
changelog: jx-changelog ## Generate changelog

.PHONY: release
release: set-manager-image skopeo-copy gen-operators-kustomization bundle-update gen-bundle-dependencies bundle-catalog gen-api-docs gen-docs ## Run release tasks

.PHONY: bundle-catalog
bundle-catalog: bundle-build bundle-push catalog-build catalog-push ## Release bundle and catalog

.PHONY: promote
promote: git ## Promote release
