# AI-Tool Configuration

This repo is **AI-native and vendor-neutral**: one canonical persona at
`~/.agents/AGENTS.md`, plus a set of vendored subagents under
`~/.agents/agents/`. There is no duplicated per-tool rule/agent/command
content.

## Architecture

```
                ┌───────────────────────────┐
                │  dot_agents/AGENTS.md      │  (chezmoi source, canonical persona)
                └─────────────┬─────────────┘
                              │ chezmoi apply
                              ▼
                     ~/.agents/AGENTS.md        ◄── single source of truth

        ~/.cursor : no global rules file → set manually in Settings → User Rules
```

## Canonical Persona

- **Source:** `dot_agents/AGENTS.md` → **target:** `~/.agents/AGENTS.md`.
- Edit the persona **once** here; Cursor picks it up from User Rules (or a
  per-project `AGENTS.md`) after the next `chezmoi apply`.

### Cursor caveat

Cursor has **no supported global rules file** and does not read a user-level
`~/.cursor/AGENTS.md`. Set the persona once per machine via
**Cursor → Settings → User Rules** (paste the contents of `~/.agents/AGENTS.md`),
or rely on a per-project `AGENTS.md`. A Cursor persona symlink would be inert, so
none is created.

## Skills

This repo does **not** install or reconcile AI skills. The catalog and install
path live in [SystemFiles/skills](https://github.com/SystemFiles/skills)
(`bunx skills add SystemFiles/skills …`). chezmoi ignores `~/.agents/skills/**`
and vendor `*/skills/**` so it never conflicts with those installs.

## Subagents

Six vendored [humanlayer](https://github.com/humanlayer/humanlayer/tree/main/.claude/agents)
subagents live canonically under `dot_agents/agents/`. They are **not**
symlinked into any tool directory.

```
dot_agents/agents/*.md
   │  chezmoi apply
   ▼
~/.agents/agents/*.md            ◄── canonical, vendor-neutral (chezmoi-managed)
```

- **Agents:** `codebase-analyzer`, `codebase-locator`, `codebase-pattern-finder`,
  `thoughts-analyzer`, `thoughts-locator`, `web-search-researcher` — each a markdown
  file with YAML frontmatter (`name`, `description`, `tools`, `model`, optional `color`).
- **No tool mount:** Cursor does not read `~/.agents/` directly. There is no
  `~/.cursor/agents` shim. Retired shims are listed in `.chezmoiremove` so
  `chezmoi apply` deletes them.
- **Frontmatter normalization:** upstream ships `model: sonnet`; the vendored copies
  use `model: inherit` so the field is valid in Cursor (which expects `inherit` or a
  Cursor model ID). Everything else is verbatim.
- **Add a subagent:** drop a `*.md` file in `dot_agents/agents/`, then `chezmoi apply`.
- **Verify:** the six files appear under `~/.agents/agents/`.

## Cursor CLI Configuration

The Cursor CLI keeps **both** portable preferences and account/runtime state in a
single file, `~/.cursor/cli-config.json`. chezmoi therefore manages it through a
`modify_` script (not as a whole file), so secrets never enter the repo and auth
is never wiped on apply.

```
dot_cursor/executable_statusline.sh ──► ~/.cursor/statusline.sh        (full file)

dot_cursor/modify_cli-config.json.tmpl
   │  stdin: live ~/.cursor/cli-config.json
   ▼
   jq '. * $desired'                 $desired = portable prefs only
   │   enforced  → statusLine, editor.vimMode, display, model selection,
   │               permissions, notifications/hints/rewind, approvalMode, sandbox
   │   preserved → authInfo, serverConfigCache, privacyCache,
   │               runEverythingSettingsPromptStreak  ◄── account/secret/ephemeral
   ▼
   ~/.cursor/cli-config.json         (merged; auth + caches untouched)
```

- **Why `modify_`:** Cursor co-writes `authInfo` (email/userId/teamId), server +
  privacy caches, and counters into the same file. A plain managed file would
  commit that identity to the repo **and** reset auth on every `chezmoi apply`.
  The script merges in only the keys in its `$desired` block; all other (live)
  keys pass through verbatim.
- **Status line:** `~/.cursor/statusline.sh` shows model + params, cwd, jj
  change/bookmarks (git-branch fallback), vim mode, and a context-usage bar.
  `statusLine.command` is `/bin/bash $HOME/.cursor/statusline.sh` (absolute,
  no `~`) because the CLI `spawn`s it with no shell on Unix — a `~` path and
  `#!/usr/bin/env bash` both fail under the CLI's minimal PATH. The script
  also prepends Homebrew + `/usr/bin:/bin` and no-ops when `jq` is missing.
- **jq dependency:** both pieces need `jq` (declared in `dot_Brewfile.tmpl`).
  Before `brew bundle` installs it, the `modify_` script passes the live file
  through unchanged — re-apply once `jq` is present.
- **Model-pin caveat:** `$desired` pins the default model + params, so an apply
  reverts an interactive model switch. Drop the `model` / `modelParameters` /
  `selectedModel` keys from the script to make the model machine-local.
- **Verify:** `chezmoi diff ~/.cursor/cli-config.json` is empty once applied;
  the status line previews via `echo '<sample-json>' | ~/.cursor/statusline.sh`.
- **Hooks:** `~/.cursor/hooks.json` + `hooks/run-shellcheck.sh` are managed as
  plain files (shellcheck `afterFileEdit` only). Machine-injected hooks (e.g.
  Adrafinil) are not in the repo and will be replaced on apply until re-injected.
- **MCP:** `~/.cursor/mcp.json` is **not** managed — MCP endpoints are
  machine/context-specific.

## Cursor IDE User Preferences

Portable Cursor IDE prefs live under macOS Application Support and are managed:

```
Library/Application Support/Cursor/User/settings.json   → theme, composer, update track
Library/Application Support/Cursor/User/keybindings.json → cmd+i → composerMode.agent
```

Caches, History, globalStorage, and extension VSIX trees under that User folder
are not managed.

## Zed

- **Source:** `dot_config/zed/settings.json` → **target:** `~/.config/zed/settings.json`
  (vim mode, fonts, theme, cursor agent_servers).
- **Cask:** `zed` (and `cursor`) are declared in `dot_Brewfile.tmpl` for non-headless
  machines.

## Ownership Boundary

`~/.agents/skills/**` and vendor `*/skills/**` (`~/.cursor/skills`,
`~/.codex/skills`) are owned by the `skills` CLI via
[SystemFiles/skills](https://github.com/SystemFiles/skills). chezmoi **ignores**
those paths (`.chezmoiignore`) so the two never conflict. `.chezmoiremove`
cannot delete ignored paths.

Canonical subagent files under `~/.agents/agents/` are chezmoi-managed.
Retired shims are listed in `.chezmoiremove`.

## What Is Not Managed

- **IDE settings** (themes, keybindings) live outside the home dotfiles
  (e.g. macOS `~/Library/Application Support/Cursor/User/`) and are configured per machine.
- **Per-tool settings** (Codex `config.toml`/`rules`) are not restored here.
  The **Cursor CLI** status line and portable prefs *are* managed — see
  [Cursor CLI Configuration](#cursor-cli-configuration).
- **Ephemeral/sensitive runtime state** under `~/.cursor` (auth, caches,
  history, project state) is not in the repo — the Cursor `modify_` script
  preserves it on the machine but never commits it.

## After Apply

Run `chezmoi apply` as usual. Restart the tool if it does not pick up the new
persona until it next reads those directories.
