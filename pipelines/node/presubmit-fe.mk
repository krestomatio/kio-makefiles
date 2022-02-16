pr-npm: npm-install npm-build ## NPM tasks during pr pipeline

pr-image: testing-buildah-image ## Image build, push during pr pipeline

lint: npm-install npx-commitlint npm-lint npm-pretty ## Project linting pipeline
