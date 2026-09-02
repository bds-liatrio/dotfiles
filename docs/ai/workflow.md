# Workflow: Branching, Commits, VCS

## Version Control: jj-first

This repo is `jj` (Jujutsu) colocated with git. Prefer `jj` verbs:

- status/log/diff -> `jj status` / `jj log` / `jj diff`
- commit -> `jj describe -m "..."` then `jj new` (or `jj commit -m "..."`)
- sync -> `jj git fetch --all-remotes` then `jj rebase -d 'trunk()'`
- push -> `jj git push`
- undo -> `jj undo`

Fall back to `git` only when `jj` cannot perform an operation, and call out the
fallback explicitly. Do not run `git rebase`/`reset`/`commit --amend`/`cherry-pick`
on the colocated repo — use `jj squash`/`split`/`rebase`/`edit`/`absorb`.

## Branching

- Default branch (trunk): `master`.
- Feature work: `feat/<description>` bookmarks (e.g. `feat/ai-native-overhaul`).
- No formal PR process — personal repo — but PRs are used for larger changes.

## Commits

Follow [Conventional Commits](https://www.conventionalcommits.org/): `type(scope): description`.

- Types: `feat`, `fix`, `docs`, `chore`, `refactor`, `update`.
- Scopes reflect the area: `agents`, `cursor`, `jj`, `git`, `zsh`, `brew`, `chezmoi`.
- Subjects <= 72 characters; add a body for larger or breaking changes.
- All commits are GPG/SSH-signed (enforced via `dot_gitconfig.tmpl`).
- Never add AI attribution or co-authors.

## Sensitive Files

- Never commit secrets (API keys, tokens, credentials).
- `private_dot_ssh/` and `private_dot_gnupg/` hold config templates only, not key material.
- Machine-specific values (email, GPG key ID) are prompted at init time, not hardcoded.

## Documentation Duties

- Update `README.md` when setup steps or prerequisites change materially.
- Update `docs/ai/` when AI-tool configuration changes structure or behavior.
- Update `.chezmoiignore` when adding non-deployable repo files.
- Update `.chezmoiexternal.toml` version pins when bumping external dependencies.
