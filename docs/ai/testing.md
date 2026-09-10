# Testing & Quality Gates

This repository has **no unit-test framework, linters, formatters, pre-commit
hooks, or CI**. Quality is verified through chezmoi's own tooling and direct
observation of the deployed result.

## Gates

| Gate | Command | Checks |
|------|---------|--------|
| Preview | `chezmoi diff` | Template output and deployment targets before applying |
| Idempotency | `chezmoi diff` (after `apply`) | Empty diff -> source and target match |
| Verify | `chezmoi verify` | Target state matches source state |
| Template render | `chezmoi execute-template < file.tmpl` | Go template logic renders correctly |

## Practice

- Always run `chezmoi diff` before `chezmoi apply`.
- Finish a change with a clean (empty) `chezmoi diff` for the affected targets.
- For scripts (`executable_`, `modify_`), observe the real result (`ls -la`,
  running the rendered script) — a passing render is not proof of runtime behavior.
- Test `.tmpl` logic with `chezmoi execute-template` before committing.
- Inspect changes on one machine before applying to others.
