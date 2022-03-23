changelog: jx-changelog ## Generate changelog

build-image: testing-buildah-image ## Image build, push

preview: jx-preview ## Create preview using JX

release: testing-buildah-image skopeo-copy ## Run release tasks

promote: git ## Promote release
