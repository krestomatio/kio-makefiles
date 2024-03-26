.PHONY: multiarch-image
multiarch-image: buildx-use buildx-image

.PHONY: changelog
changelog: jx-changelog ## Generate changelog

.PHONY: release
release: set-manager-image skopeo-copy build-docs ## Run release tasks

.PHONY: promote
promote: git ## Promote release
