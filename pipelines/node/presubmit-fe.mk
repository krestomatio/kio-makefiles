build-image: testing-buildah-image ## Image build, push during pr pipeline

preview: jx-preview ## Create preview using JX

lint: npm-ci npx-commitlint npm-lint npm-pretty ## Project linting pipeline
