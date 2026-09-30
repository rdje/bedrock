#!/usr/bin/env bash
# COMMIT-MESSAGE — the subject is id-shaped and the message carries no agent attribution trailer.
# SPDX-License-Identifier: LGPL-2.1-or-later
#
#   scripts/check_commit_message.sh [<message-file>]      (or SPINE_COMMIT_MSG set by the driver)
#
# Evaluated wherever a message EXISTS: the commit-msg hook (locally) and CI (per commit, so a
# --no-verify'd message is judged too — MEMORY_ARCHITECTURE.md §9 promised that and nothing did
# it, BK-13/BR-21). In the pre-commit hook there is no message yet, and the check says so instead
# of pretending: NOT EVALUATED is printed, not a verdict.
#
# The subject is read after `git stripspace --strip-comments`, exactly as git will store it, so a
# message whose first line is blank (which git removes) is judged on its real subject (BK-11).
#
# NO AGENT TRAILERS (COMMIT.md): a commit message ends with its own last line. The shapes refused
# here are the known agent-attribution ones; a human co-author's `Co-Authored-By:` is not matched.
# (REVIEW-2026-09.4 replaces the pattern with trailer parsing and `.doctrine/agent_identities`.)
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib/spine.sh"; spine_init COMMIT-MESSAGE

f="${1:-${SPINE_COMMIT_MSG:-}}"
[ -n "$f" ] || { spine_ok "NOT EVALUATED — no commit message in this context (the commit-msg hook and CI supply one)"; exit 0; }
[ -r "$f" ] || spine_refuse "message file $f is unreadable"
msg="$(git stripspace --strip-comments < "$f" 2>/dev/null)" || spine_refuse "git stripspace failed"
subject="$(printf '%s\n' "$msg" | head -1)"
fail=0
if ! printf '%s' "$subject" | grep -Eq '^[A-Za-z][A-Za-z0-9._-]+'; then
  spine_fail "subject must begin with an identifier-shaped work-unit id — got: '$subject'"
  spine_fail "  e.g. '<PROJECT>-<AREA>-<NNNN> (leaf <TREE>.<n>): <summary>'"
  fail=1
fi
AGENT_TRAILER_RE='^(co-authored-by|co-developed-by|assisted-by|generated-by):.*(claude|codex|gemini|copilot|chatgpt|openai|cursor|aider|noreply@anthropic|noreply@openai|noreply@google)|^claude-session:|^(generated with|🤖 generated with) |^[[:space:]]*🤖 '
if printf '%s\n' "$msg" | grep -iEq "$AGENT_TRAILER_RE"; then
  spine_fail "the message carries an agent/tool attribution trailer, which this repository forbids (COMMIT.md):"
  printf '%s\n' "$msg" | grep -iE "$AGENT_TRAILER_RE" | sed 's/^/    /' >&2
  spine_fail "  A commit message ends with its own last line. Remove the trailer and commit again."
  fail=1
fi
[ "$fail" -eq 0 ] || exit 1
spine_ok "OK — subject '$(printf '%s' "$subject" | cut -c1-60)'"
exit 0
