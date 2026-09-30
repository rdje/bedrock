#!/usr/bin/env bash
# COMMIT-MESSAGE — the subject is a work-unit id, and the message carries no agent attribution.
# SPDX-License-Identifier: LGPL-2.1-or-later
#
#   scripts/check_commit_message.sh [<message-file>]      (or SPINE_COMMIT_MSG set by the driver)
#
# Evaluated wherever a message EXISTS: the commit-msg hook and CI, per commit — so a message that
# bypassed the hook is judged anyway. Without a message it says NOT EVALUATED.
#
# THE SUBJECT starts with a work-unit id: `<PREFIX>-…-<NNNN>` (`DEMO-APP-0002`, `SEED-0001`), the
# scheme COMMIT.md names. The reviewed rule accepted any identifier-shaped word (`hello` passed,
# BR-21). The subject is read after `git stripspace --strip-comments`, exactly as git stores it,
# so a leading blank line (which git removes) is not a defect (BK-11). A merge commit's subject
# is git's own and is exempt; the root commit is never reached with a message.
#
# NO AGENT TRAILERS (COMMIT.md): a commit message ends with its own last line. Trailers are read
# with git's parser (`git interpret-trailers --parse`), never by scanning body text, and an AGENT
# is recognised by DATA, not by a vendor list in this script (NT-09): `.doctrine/agent_identities`
# holds `address <ERE>` lines matched against the e-mail and `name <ERE>` lines matched against the
# whole name. The built-in default is the bot addresses only, so a HUMAN whose first name is
# Claude, Gemini or Cursor is never refused (BK-11: `Co-Authored-By: Claude Martin <…@example.fr>`).
# Any attribution key counts: Co-Authored-By, Co-Developed-By, Assisted-By, Generated-By, …
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib/spine.sh"; spine_init COMMIT-MESSAGE
T="$(spine_tmp)"

f="${1:-${SPINE_COMMIT_MSG:-}}"
[ -n "$f" ] || { spine_ok "NOT EVALUATED — no commit message in this context (the commit-msg hook and CI supply one)"; exit 0; }
[ -r "$f" ] || spine_refuse "message file $f is unreadable"
spine_msg_text "$f" > "$T/msg" || spine_refuse "git stripspace failed"
subject="$(head -1 "$T/msg")"
fail=0

if [ "${SPINE_MERGE:-0}" != 1 ]; then
  if ! printf '%s\n' "$subject" | grep -Eq '^[A-Z][A-Z0-9]*(-[A-Z0-9]+)*-[0-9]{4,}([^0-9A-Za-z]|$)'; then
    spine_fail "the subject must start with a work-unit id such as PROJ-AREA-0007 — got: '$subject'"
    spine_fail "  shape: '<PROJECT>-<AREA>-<NNNN> (leaf <TREE>.<n>): <summary>'  (COMMIT.md)"
    fail=1
  fi
fi

# agent identities: built-in bot addresses, plus the project's data file (as of the last commit)
ADDR_RE='noreply@anthropic\.com$|noreply@openai\.com$|noreply@google\.com$|copilot@users\.noreply\.github\.com$'
NAME_RE=''
ids="$(spine_config_file agent_identities)"
if [ -n "$ids" ]; then
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    kind="${line%% *}"; re="${line#* }"; re="${re#"${re%%[! ]*}"}"
    spine_re_valid "$re" || spine_refuse ".doctrine/agent_identities holds an invalid regular expression: '$re'"
    case "$kind" in
      address) ADDR_RE="$ADDR_RE|$re" ;;
      name)    NAME_RE="${NAME_RE:+$NAME_RE|}$re" ;;
      *) spine_refuse ".doctrine/agent_identities: a line is 'address <ERE>' or 'name <ERE>', not '$line'" ;;
    esac
  done <<IDS
$ids
IDS
fi

spine_msg_trailers "$f" > "$T/trailers.tsv"
while IFS=$'\t' read -r key value; do
  case "$key" in co-authored-by|co-developed-by|assisted-by|generated-by|authored-by|reviewed-by|signed-off-by) ;; *) continue ;; esac
  email="$(printf '%s' "$value" | grep -oE '<[^>]*>' | tr -d '<>' | tr 'A-Z' 'a-z')"
  name="$(printf '%s' "$value" | sed 's/[[:space:]]*<.*$//')"
  hit=0
  [ -n "$email" ] && printf '%s\n' "$email" | grep -qiE "$ADDR_RE" && hit=1
  [ -n "$NAME_RE" ] && printf '%s\n' "$name" | grep -qiE "^($NAME_RE)$" && hit=1
  if [ "$hit" = 1 ]; then
    spine_fail "the message attributes an AGENT in a trailer, which this repository forbids (COMMIT.md): $key: $value"
    spine_fail "  A commit message ends with its own last line. Remove the trailer and commit again."
    fail=1
  fi
done < "$T/trailers.tsv"
# non-trailer attribution shapes some harnesses add as body text
if grep -iEq '^(🤖 )?generated with (\[|[A-Za-z])|^claude-session:' "$T/msg"; then
  spine_fail "the message carries a harness attribution line ('Generated with …' / 'claude-session:'), which this repository forbids (COMMIT.md)"
  fail=1
fi

[ "$fail" -eq 0 ] || exit 1
spine_ok "OK — subject '$(printf '%s' "$subject" | cut -c1-60)'"
exit 0
