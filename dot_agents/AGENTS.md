## Context Marker

Always begin your response with all active emoji markers, in the order they were introduced.

Format: `"<marker1><marker2><marker3>\n<response>"`

The marker for this instruction is: 🤖

## Our working relationship

- I don't like sycophancy.
- Be neither rude nor polite. Be matter-of-fact, straightforward, and clear.
- Be extremely concise. Even sacrifice grammar for the sake of concision.
- I am sometimes wrong. Challenge my assumptions.
- Don't be lazy. Do things the right way, not the easy way.
- When defining a plan of action, don't provide timeline estimates.
- If creating a commit (via `jj describe` or, as a last resort, `git commit`) do not add yourself as a co-author.

## Development Methodology: Executable-First, Thinnest Slice

- **Start runnable, stay runnable** — Confirm the application executes before adding features; verify it still runs after every change
- **Thin vertical slices** — Implement the smallest complete path from entry point to output; never build layers in isolation or "integrate at the end"
- **Observe, don't just test** — Use verification tools (browser automation, screenshots, API clients, log inspection) to confirm real behavior; green tests are insufficient without observing the running application
- **If you can't run it, you can't push your commit**

## Migration Methodology: Strangler Fig Pattern

**Replace incrementally. Validate continuously. Remove deliberately.**

- **Smallest extractable unit** — Identify the thinnest slice of functionality that can be migrated independently; prove the pattern works before scaling it
- **Parallel paths, not parallel universes** — Run old and new simultaneously; validate new behavior matches or intentionally improves before cutting over
- **Translation layers are temporary scaffolding** — When adapters, shims, or facades are needed, document their purpose, lifespan, and removal criteria; treat them as tech debt with a known payoff date
- **Removal is a first-class deliverable** — The migration isn't complete until the old code is deleted; schedule and execute removal as part of the work, not "someday cleanup"

## Version Control: jj-first

- Use `jj` (Jujutsu, https://github.com/jj-vcs/jj) for all VCS operations. Repos on this machine are colocated, so jj acts on the underlying git repo.
- Prefer jj-native verbs over their git equivalents:
  - status/log/diff → `jj status` / `jj log` / `jj diff`
  - stage + commit → `jj describe -m "..."` then `jj new` (or `jj commit -m "..."`)
  - sync → `jj git fetch --all-remotes` then `jj rebase -d 'trunk()'`
  - push → `jj git push`
  - undo → `jj undo` (never `git reset --hard` on jj-managed work)
- Fall back to `git` only when jj cannot perform the operation (missing jj install, non-colocated repo, jj-unsupported subcommand). Call out the fallback explicitly in your response.
- Do not run `git rebase`, `git reset`, `git commit --amend`, `git cherry-pick`, or interactive history-editing commands on a jj-colocated repo — use `jj squash`, `jj split`, `jj rebase`, `jj edit`, or `jj absorb` instead.

## Tooling

- Use skills installed under `~/.agents/skills/` (the canonical, vendor-neutral skills location shared by every tool) when a task matches a skill's purpose. Skills are declared in the repo's `skills-registry.txt` and installed/symlinked by the chezmoi skills installer; tools see them via their own `skills/` symlinks (e.g. `~/.cursor/skills/`, `~/.claude/skills/`).
- If a Makefile or Taskfile exists, prefer its targets (check `make help` or `task -l`) over calling tools directly (e.g. use `task test` instead of `go test ./...`).
- Use ASCII diagrams in markdown to help explain complex systems and interactions.
