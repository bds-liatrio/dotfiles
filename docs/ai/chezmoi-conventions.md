# chezmoi Conventions & Common Tasks

How this repository maps source files to the home directory, the day-to-day
commands, and how to add or change managed dotfiles.

## Naming Rules

chezmoi maps source names to target paths by prefix/suffix:

| Prefix/Suffix | Meaning |
|---------------|---------|
| `dot_` | Replaced with `.` in the target path (e.g. `dot_zshrc` -> `~/.zshrc`) |
| `private_` | Deployed with `0600`/`0700` permissions |
| `symlink_` | Source body is the symlink target; deploys a managed symlink |
| `.tmpl` | Rendered through Go `text/template` before deployment |
| `run_` | Script in `.chezmoiscripts/`, executed on every `chezmoi apply` |
| `run_once_` | Script executed once per machine (keyed by content hash) |

When adding source files:

- Prefix dotfiles with `dot_`, restricted-permission files with `private_`.
- Suffix templated files with `.tmpl` (Go template syntax).
- Put scripts in `.chezmoiscripts/` with `run_`/`run_once_`.
- Non-deployable repo files (e.g. `README.md`, `AGENTS.md`) go in `.chezmoiignore`.
- Targets chezmoi should actively delete from existing machines go in `.chezmoiremove`.
  Note: `.chezmoiremove` cannot remove paths matched by `.chezmoiignore`; use a
  `run_once_` cleanup script for one-time removal of ignored paths.

## Common Tasks

| Task | Command |
|------|---------|
| Apply all dotfiles | `chezmoi apply` |
| Preview changes before applying | `chezmoi diff` |
| Apply/preview a single target | `chezmoi apply ~/.zshrc` / `chezmoi diff ~/.zshrc` |
| Edit a managed file | `chezmoi edit <target>` |
| Add a new file | `chezmoi add <file>` (`--template` for a templated file) |
| Re-run init prompts / regenerate config | `chezmoi init` |
| Update external deps | `chezmoi update` |
| Check status | `chezmoi status` |
| View a target's source | `chezmoi source-path <target>` |

## Adding or Modifying Dotfiles

1. Edit the **source state** in `~/.local/share/chezmoi/`, not the targets in `~/`.
2. Preview with `chezmoi diff`.
3. Deploy with `chezmoi apply`.
4. For `.tmpl` files, test rendering with `chezmoi execute-template < file.tmpl`.

## External Dependencies

Managed in `.chezmoiexternal.toml` and refreshed periodically: oh-my-zsh,
zsh-syntax-highlighting, Powerlevel10k, vim-plug, tpm. Bump version
pins there when upgrading.

## Homebrew Bundle

After `chezmoi apply`, install system packages:

```bash
brew bundle --global
```

`dot_Brewfile.tmpl` is templated — headless machines skip GUI casks.

## First-Time Setup

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply SystemFiles
```

`init` prompts for `email`, `git_user`, `git_username`, `headless`, and
`default_gpg_key`; values are stored in `~/.config/chezmoi/chezmoi.toml` and
drive `.tmpl` rendering.
