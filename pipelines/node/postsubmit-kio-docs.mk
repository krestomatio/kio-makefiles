.PHONY: multiarch-image
multiarch-image: buildx-use buildx-image

.PHONY: changelog
changelog: jx-changelog ## Generate changelog

.PHONY: release
release: sync-docs multiarch-image skopeo-copy ## Run release tasks

.PHONY: promote
promote: git ## Promote release
