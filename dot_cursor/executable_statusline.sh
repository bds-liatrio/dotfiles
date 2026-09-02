#!/bin/bash
# Cursor CLI status line. Receives session JSON on stdin, prints status rows to
# stdout (rendered above the prompt). Tuned for a jj-first, vim-enabled workflow:
# shows the selected model + params, the working directory, jj change/bookmarks
# (git branch fallback), vim mode, and a context-window usage bar.
#
# Cursor CLI statusline JSON contract: stdin session JSON, stdout status rows.
#
# `-e` is intentionally omitted so a hiccup never blanks the status line; the CLI
# keeps the previous text when the script exits non-zero with empty stdout.
#
# Shebang is /bin/bash (not `env bash`): the CLI spawns this with no shell and an
# often-minimal PATH, so `/usr/bin/env bash` cannot find bash.
set -uo pipefail

# The CLI may spawn this with a minimal PATH; make jq/jj discoverable on macOS
# (Homebrew, Apple Silicon + Intel) and Linux (Homebrew/linuxbrew + system).
export PATH="/opt/homebrew/bin:/usr/local/bin:/home/linuxbrew/.linuxbrew/bin:/usr/bin:/bin:${PATH:-}"

payload=$(cat)

# jq is required to parse the payload. Without it, emit nothing and exit 0 so the
# CLI retains the prior status line rather than showing a broken row.
command -v jq >/dev/null 2>&1 || exit 0

# Defaults so `set -u` never blanks a first paint when jq/read fail (empty or
# non-JSON stdin).
MODEL="?" PARAMS="" MAXMODE="" CWD="" VIM="" PCT="0" TOKENS="0"

# Parse all needed fields in one jq pass, joined by the unit-separator (0x1f) so
# empty fields are preserved (a whitespace IFS would collapse adjacent empties).
sep=$'\037'
IFS="$sep" read -r MODEL PARAMS MAXMODE CWD VIM PCT TOKENS < <(
  printf '%s' "$payload" | jq -j --arg s "$sep" '
    [ (.model.display_name // "?")
    , (.model.param_summary // "")
    , (if .model.max_mode then "max" else "" end)
    , (.workspace.current_dir // .cwd // "")
    , (.vim.mode // "")
    , (.context_window.used_percentage // 0 | floor | tostring)
    , (.context_window.total_input_tokens // 0 | floor | tostring)
    ] | join($s)' 2>/dev/null
) || true
MODEL=${MODEL:-?}
PCT=${PCT:-0}
TOKENS=${TOKENS:-0}

# Colors
R=$'\033[0m'; DIM=$'\033[90m'
CYAN=$'\033[36m'; BLUE=$'\033[34m'; GREEN=$'\033[32m'
MAGENTA=$'\033[35m'; YELLOW=$'\033[33m'; RED=$'\033[31m'

# --- VCS: jj change + bookmarks, fall back to git branch ---
# --ignore-working-copy so the status line never triggers a working-copy snapshot.
VCS=""
if [ -n "$CWD" ]; then
  VCS=$(cd "$CWD" 2>/dev/null && command -v jj >/dev/null 2>&1 && jj log -r @ \
    --no-graph --ignore-working-copy \
    -T 'change_id.shortest(6) ++ if(bookmarks, " " ++ bookmarks.join(","), "")' \
    2>/dev/null)
  if [ -z "$VCS" ]; then
    branch=$(cd "$CWD" 2>/dev/null && git branch --show-current 2>/dev/null)
    [ -n "$branch" ] && VCS="git:$branch"
  fi
fi

# --- Directory: cwd basename ---
LOC="${CWD##*/}"
[ -z "$LOC" ] && LOC="~"

# --- Tokens, formatted as k ---
TOK_STR=""
if [ "${TOKENS:-0}" -ge 1000 ] 2>/dev/null; then
  TOK_STR=$(awk -v t="$TOKENS" 'BEGIN{printf "%.1fk", t/1000}')
elif [ "${TOKENS:-0}" -gt 0 ] 2>/dev/null; then
  TOK_STR="$TOKENS"
fi

# --- Line 1: model · directory · vcs · vim ---
line1="${CYAN}${MODEL}${R}"
[ -n "$PARAMS" ] && line1="${line1} ${DIM}${PARAMS}${R}"
[ -n "$MAXMODE" ] && line1="${line1} ${YELLOW}max${R}"
line1="${line1}  ${BLUE}${LOC}${R}"
[ -n "$VCS" ] && line1="${line1}  ${GREEN}${VCS}${R}"
[ -n "$VIM" ] && line1="${line1}  ${MAGENTA}[${VIM}]${R}"

# --- Line 2: context usage bar ---
PCT=${PCT:-0}
BAR_WIDTH=12
FILLED=$(( PCT * BAR_WIDTH / 100 ))
[ "$FILLED" -gt "$BAR_WIDTH" ] && FILLED=$BAR_WIDTH
[ "$FILLED" -lt 0 ] && FILLED=0
EMPTY=$(( BAR_WIDTH - FILLED ))

if [ "$PCT" -lt 50 ]; then BARC="$GREEN"
elif [ "$PCT" -lt 80 ]; then BARC="$YELLOW"
else BARC="$RED"; fi

bar=""
[ "$FILLED" -gt 0 ] && { printf -v f "%${FILLED}s" ""; bar="${f// /█}"; }
[ "$EMPTY" -gt 0 ] && { printf -v e "%${EMPTY}s" ""; bar="${bar}${e// /░}"; }

line2="${DIM}ctx${R} ${BARC}${bar}${R} ${DIM}${PCT}%${R}"
[ -n "$TOK_STR" ] && line2="${line2} ${DIM}· ${TOK_STR} tok${R}"

printf '%s\n%s' "$line1" "$line2"
