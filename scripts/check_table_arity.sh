#!/usr/bin/env bash
# TABLE-ARITY-RATCHET — a changed markdown file may not RAISE the number of table rows whose cell
# count disagrees with their own header. Exits NONZERO on a rise. Called by check_doctrines.sh.
# SPDX-License-Identifier: LGPL-2.1-or-later
#
# WHY THIS EXISTS: GFM's table rule is per TABLE and it is two-sided and SILENT: a row with MORE cells
#   than its own header has the excess DISCARDED — not rendered, not warned about — and a row with FEWER
#   is silently PADDED. A dropped cell leaves no gap, so a reader cannot tell. Measured upstream on a
#   clean tree where every enforcer was green: 26 of 197 rows of a SHIPPED contract were losing their
#   rightmost cells. The class breaks no build, fails no test, and leaves the page looking fine.
#
# THE RATCHET: per changed .md file, count = rows whose cell count != their table's header count.
#   The BEFORE snapshot's count is the ceiling. A rise blocks and names the rows; a fall is promoted
#   silently. `--all` reports the backlog, advisory.
#
# CELL COUNTING — GFM's rules, not a guess (REVIEW-2026-09.7, BR-15; the first cut protected a pipe
#   inside a code span, which GFM does NOT do: "include a pipe in a cell's content by escaping it,
#   including inside other inline spans"):
#   • a table is a header row, then a DELIMITER row (`---`, `:--`, `--:`, `:-:` per cell) with the SAME
#     number of cells as the header — otherwise it is not a table and is not judged;
#   • rows continue until a blank line or the start of another block (a heading, a fence, a quote);
#     a plain prose line right after a table IS a one-cell row, as GFM renders it;
#   • cells split on every `|` not preceded by a backslash; a leading and a trailing pipe are
#     delimiters, not cells; outer pipes are optional; a pipe inside a code span still splits.
#   • fenced code blocks are skipped.
# POSIX awk only: no python, no GNU extensions (NT-12; before this, a missing python3 was REFUSED).
# CONTRACT: exit code is the verdict (0 holds · 1 breach · 2 REFUSED); explains on stderr;
#   deterministic; read-only; judged on the change through scripts/lib/spine.sh.
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib/spine.sh"; spine_init TABLE-ARITY-RATCHET

ARITY_AWK='
function ncells(line,   s, n, i, c, l) {
  s = line; sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s)
  if (substr(s, 1, 1) == "|") s = substr(s, 2)
  l = length(s)
  if (l > 0 && substr(s, l, 1) == "|" && substr(s, l - 1, 1) != "\\") s = substr(s, 1, l - 1)
  n = 0
  for (i = 1; i <= length(s); i++) {
    c = substr(s, i, 1)
    if (c == "\\" && substr(s, i + 1, 1) == "|") { i++; continue }
    if (c == "|") n++
  }
  return n + 1
}
function is_delim(line,   s, k, parts, n, i) {
  s = line; sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s)
  if (s !~ /-/) return 0
  if (substr(s, 1, 1) == "|") s = substr(s, 2)
  if (length(s) > 0 && substr(s, length(s), 1) == "|") s = substr(s, 1, length(s) - 1)
  n = split(s, parts, "|")
  for (i = 1; i <= n; i++) if (parts[i] !~ /^[ \t]*:?-+:?[ \t]*$/) return 0
  return 1
}
/^[ \t]*(```|~~~)/ { fence = !fence; intable = 0; prev = ""; next }
fence { next }
{
  if (intable) {
    if ($0 ~ /^[ \t]*$/ || $0 ~ /^[ \t]*(#|>|```|~~~)/) { intable = 0 }
    else { have = ncells($0); if (have != want) printf "%d\t%d\t%d\t%s\n", NR, have, want, substr($0, 1, 120); next }
  }
  if (!intable && prev != "" && is_delim($0) && ncells(prev) == ncells($0)) { intable = 1; want = ncells(prev); prev = ""; next }
  prev = ($0 ~ /^[ \t]*$/) ? "" : $0
}'
arity_defects() { awk "$ARITY_AWK"; }         # stdin = markdown; stdout = "lineno<TAB>have<TAB>want<TAB>text" per defective row
count_defects() { arity_defects | grep -c . || true; }

if [ "${1:-}" = "--self-test" ]; then
  fails=0; arms=0
  t() { local want="$1" name="$2"; local got; arms=$((arms+1)); got="$(printf '%b' "$3" | count_defects)"; [ "$got" = "$want" ] && echo "  arm ok  $name ($got)" || { echo "TABLE-ARITY self-test: MISS $name want=$want got=$got" >&2; fails=1; }; }
  t 0 "a well-formed 3-column table" '| a | b | c |\n|---|---|---|\n| 1 | 2 | 3 |\n| x | y | z |\n'
  t 1 "a row with one cell too many" '| a | b |\n|---|---|\n| 1 | 2 | 3 |\n'
  t 1 "a row with one cell too few" '| a | b | c |\n|---|---|---|\n| 1 | 2 |\n'
  t 1 "an unescaped pipe inside a code span SPLITS the cell (GFM)" '| a | b |\n|---|---|\n| `x | y` | 2 |\n'
  t 0 "an escaped pipe is not a separator" '| a | b |\n|---|---|\n| x \\| y | 2 |\n'
  t 0 "an escaped pipe inside a code span is not a separator" '| a | b |\n|---|---|\n| `x \\| y` | 2 |\n'
  t 0 "a table inside a code fence is not judged" '```\n| a | b |\n|---|---|\n| 1 |\n```\n'
  t 0 "a table without outer pipes, well-formed" 'a | b\n--|--\n1 | 2\n'
  t 1 "a table without outer pipes, a short row" 'a | b | c\n--|--|--\n1 | 2\n'
  t 0 "header/delimiter mismatch is not a table at all" '| a | b | c |\n|---|---|\n| 1 |\n'
  t 1 "a prose line right after a table is a one-cell row" '| a | b |\n|---|---|\n| 1 | 2 |\nsome prose\n'
  t 0 "a blank line ends the table" '| a | b |\n|---|---|\n| 1 | 2 |\n\nsome prose\n'
  t 0 "alignment markers in the delimiter row" '| a | b |\n|:--|--:|\n| 1 | 2 |\n'
  [ "$fails" = 0 ] && echo "TABLE-ARITY-RATCHET --self-test: $arms/$arms arms" || exit 1
  exit 0
fi

if [ "${1:-}" = "--all" ]; then
  total=0
  for f in $(spine_after_ls '*.md'); do n="$(spine_read "$f" | count_defects)"; [ "$n" -gt 0 ] && { printf '  %-60s %s\n' "$f" "$n"; total=$((total + n)); }; done
  echo "TABLE-ARITY-RATCHET --all (ADVISORY): $total arity-defective row(s) in tracked markdown"
  exit 0
fi

staged="$(spine_changed_paths | grep -E '\.md$' || true)"
[ -n "$staged" ] || { spine_ok "ok (no markdown in this change)"; exit 0; }
fail=0
for f in $staged; do
  now="$(spine_read "$f" | count_defects)"
  before="$(spine_read_before "$f" 2>/dev/null | count_defects)"
  if [ "${now:-0}" -gt "${before:-0}" ]; then
    fail=1
    { echo "TABLE-ARITY-RATCHET: RISE — $f has $now row(s) whose cell count disagrees with their header (before: $before):"
      spine_read "$f" | arity_defects | while IFS=$'\t' read -r ln have want text; do echo "    line $ln: $have cell(s), header has $want: $text"; done
      echo "  GFM silently DROPS the extra cells or PADS the missing ones. Fix the row: escape a literal pipe as \\| (also inside code spans),"
      echo "  and put a blank line after a table so the next prose line is not absorbed as a row."; } >&2
  fi
done
[ "$fail" = 0 ] && spine_ok "ok ($(printf '%s\n' "$staged" | wc -l | tr -d ' ') markdown file(s) in this change, no rise)"
[ "$fail" = 0 ] || exit 1
exit 0
