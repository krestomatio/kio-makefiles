# Repository guidance

## Repository scope

- This repository is the shared Make/CI contract vendored as `hack/mk` by Node,
  Go, Go-operator, Ansible-operator, collection, documentation, and static-site
  repositories. Its scope is broader than the historical README title.
- `main.mk`, `vars/`, `targets/`, and `pipelines/` are public includes. Preserve
  target names, variables, defaults, and override behavior or update every pinned
  consumer in a coordinated change.
- Separate pure validation/build targets from commands that fetch credentials,
  mutate clusters, publish images/packages, create PRs, tag, or push.

## Validation

- Parse and exercise changed includes with representative `PROJECT_TYPE` and
  `PROJECT_SHORTNAME` values, then validate them in at least one affected consumer
  at its pinned submodule revision.
- Use consumer CI as the compatibility test. Never invoke release, promotion,
  updatebot, Vault, cluster, or destructive preview-cleanup targets casually.
