.PHONY: multiarch-image
multiarch-image: buildx-image

.PHONY: changelog
changelog: jx-changelog ## Generate changelog

.PHONY: release
release: set-manager-image skopeo-copy ## Run release tasks

.PHONY: promote
promote: git ## Promote release
