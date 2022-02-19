pr-npm: npm-ci npm-build ## NPM tasks during pr pipeline

pr-image: testing-buildah-image ## Image build, push push during pr pipeline

lint: npm-ci npm-lint ## Project linting pipeline
