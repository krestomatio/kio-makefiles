.PHONY: changelog
changelog: jx-changelog ## Generate changelog

.PHONY: release
release: galaxy-version galaxy-publish ## Run release tasks

.PHONY: promote
promote: git jx-updatebot ## Promote release
