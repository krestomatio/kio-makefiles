.PHONY: changelog
changelog: jx-changelog ## Generate changelog

.PHONY: preview
preview: helmfile-preview ## Preview chart using helmfile

.PHONY: release
release: skopeo-copy ## Run release tasks

.PHONY: promote
promote: git ## Promote release
