#!/usr/bin/env bash
# LIVE-DOC-CURRENCY — a live document carries no SELF-REPORTED currency field. Exits NONZERO on
# breach. Called by scripts/check_doctrines.sh via .githooks/pre-commit (E3) and CI (E4).
#
# THE RULE: no tracked Markdown file states `Last updated: <date>` (or `Last-updated`,
# `Last modified`, `Updated on`) about itself. Git already records when every line changed, and it
# cannot be wrong; a hand-maintained date is right on the day it is typed and false the day after,
# and a reader who trusts it is misled precisely when it matters. Measured in the originating
# project (LIVE-MEANS-LIVE.4a, 2026-07-31): the field was DELETED repo-wide after it was found
# stale on the very documents whose currency it claimed; the template inherits the deletion, not
# the field. Ported by BEDROCK-MAINTENANCE.2.5 as the principle; the upstream instrument that
# additionally scores distinct dates per live surface against a declared charter stays a backlog
# item (it needs a per-project charter).
#
# ARCHETYPE: structural — re-derived on every run over the CLOSED population of every .md in the
# AFTER snapshot (the index locally, the commit in CI — never the worktree, BR-03); nothing is
# assumed about which files are "live". A date inside prose ("released 2026-07-30") is not a currency field and is not matched;
# only a field-shaped line — the label at the start of the line, followed by a colon — is.
#
# CONTRACT: exit code is the verdict (0 holds · 1 breach · 2 REFUSED); explains on stderr;
# deterministic; read-only; path-agnostic; fast.  `--self-test` proves both arms fire.
# SPDX-License-Identifier: LGPL-2.1-or-later
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib/spine.sh"; spine_init LIVE-DOC-CURRENCY
T="$(spine_tmp)"

FIELD_RE='^[[:space:]]*(-[[:space:]]*|\*[[:space:]]*|>[[:space:]]*)?(\*\*)?(last[ -]updated|last[ -]modified|updated[ -]on)(\*\*)?[[:space:]]*:'

scan() { # $1 = file; prints offending lines as file:line:text
  grep -inE "$FIELD_RE" "$1" 2>/dev/null | sed "s|^|$1:|"
}
scan_as() { # $1 = file to read, $2 = name to report
  grep -inE "$FIELD_RE" "$1" 2>/dev/null | sed "s|^|$2:|"
}

if [ "${1:-}" = "--self-test" ]; then
  d="$T/live_doc_currency"; rm -rf "$d"; mkdir -p "$d"   # scratch OUTSIDE the worktree (NT-07)
  printf -- '- Last updated: `2026-07-30`\n' > "$d/red.md"
  printf 'Released on 2026-07-30; see the changelog.\nlast updated the index by hand, then committed.\n' > "$d/green.md"
  printf '**Last Modified:** 2026-01-01\n' > "$d/red2.md"
  fails=0
  [ -n "$(scan "$d/red.md")" ]   || { echo "LIVE-DOC-CURRENCY self-test: the field form must fire" >&2; fails=1; }
  [ -n "$(scan "$d/red2.md")" ]  || { echo "LIVE-DOC-CURRENCY self-test: the bold Last Modified form must fire" >&2; fails=1; }
  [ -z "$(scan "$d/green.md")" ] || { echo "LIVE-DOC-CURRENCY self-test: a date in prose must NOT fire" >&2; fails=1; }
  rm -rf "$d"
  [ "$fails" = 0 ] && echo "LIVE-DOC-CURRENCY --self-test: 3/3 arms" || exit 1
  exit 0
fi

offending=""; n=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  n=$((n+1))
  spine_read "$f" > "$T/doc.md" || continue
  hit="$(scan_as "$T/doc.md" "$f")"; [ -n "$hit" ] && offending="${offending}${hit}"$'\n'
done < <(spine_after_ls '*.md')
offending="$(printf '%s' "$offending" | sed '/^$/d')"
if [ -n "$offending" ]; then
  {
    echo "LIVE-DOC-CURRENCY: a tracked document reports its own currency — a field git already carries, and one that is false the day after it is typed:"
    printf '%s\n' "$offending" | sed 's/^/    /'
    echo "  Delete the field. \`git log -1 --format=%ad -- <file>\` is the currency, and it cannot go stale."
  } >&2
  exit 1
fi
spine_ok "ok ($n .md files in the snapshot, none self-reports a currency date)"
exit 0
