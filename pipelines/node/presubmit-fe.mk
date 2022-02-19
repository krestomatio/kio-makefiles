pr-npm: npm-ci npm-build ## NPM tasks during pr pipeline

pr-image: testing-buildah-image ## Image build, push during pr pipeline

lint: npm-ci npx-commitlint npm-lint npm-pretty ## Project linting pipeline
