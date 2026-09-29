# Repository guidance

Before working, read these optional instruction files in order,
resolving these paths from this repository's root:

1. `.agents/organization/AGENTS.md`
2. `.agents/workspace/AGENTS.md`

Read each file if it resolves to a readable regular file.
Skip absent files; report broken or unreadable links.
Read each resolved file only once to avoid duplicate loading and cycles.

Resolve references inside imported files relative to their real target
directory after following symlinks.

Apply organization guidance, then workspace guidance, then the repository
instructions below. More specific applicable instructions take precedence.

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
