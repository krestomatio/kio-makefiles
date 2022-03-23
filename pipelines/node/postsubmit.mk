changelog: jx-changelog ## Generate changelog

deploy: helmfile-preview ## Deploy preview chart using helmfile

release: testing-buildah-image skopeo-copy ## Run release tasks

promote: git ## Promote release
