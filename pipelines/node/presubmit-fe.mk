build-image: testing-buildah-image ## Image build, push

pr-preview: jx-preview ## Create preview using JX

lint: npm-ci npx-commitlint npm-lint npm-pretty ## Project linting pipeline
