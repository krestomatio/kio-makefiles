.PHONY: changelog
changelog: jx-changelog ## Generate changelog

.PHONY: release
release: galaxy-version galaxy-publish ## Run release tasks

.PHONY: promote
promote: jx-updatebot git ## Promote release
