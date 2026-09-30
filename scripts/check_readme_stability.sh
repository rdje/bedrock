#!/usr/bin/env bash
# scripts/check_readme_stability.sh — README-STABILITY (README_POLICY.md).
# SPDX-License-Identifier: LGPL-2.1-or-later
#
# Keeps README.md a stable LANDING PAGE instead of letting it grow into a changelog, roadmap,
# catalogue or documentation inventory. Structural, deterministic, NON-MUTATING, no network.
# Judged on the AFTER snapshot. Exits nonzero on any breach, with a routing hint.
#
# ⭐ WHY BOTH A LINE CAP AND A BYTE CAP — measured on a real project running this spine: its
# layer-A MEMORY.md sat at 60 lines, PASSING, while carrying 138,403 BYTES; the same class appeared
# in that project's README, where ONE bullet measured 4,369 bytes. Line and byte checks are
# COMPLEMENTS. The caps come from .doctrine/config as of the LAST commit (a commit cannot raise
# the cap that judges it); README_POLICY.md tells the adopting project to TIGHTEN them after its
# own review-and-trim. ⛔ NEVER raise a cap to land new content.
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib/spine.sh"; spine_init README-STABILITY
T="$(spine_tmp)"

LINE_CAP="$(spine_config readme_line_cap 300)"; BYTE_CAP="$(spine_config readme_byte_cap 16384)"
case "$LINE_CAP$BYTE_CAP" in *[!0-9]*|"") spine_refuse ".doctrine/config: readme_line_cap / readme_byte_cap must be integers (got '$LINE_CAP' / '$BYTE_CAP')";; esac
TARGET="README.md"; POLICY="README_POLICY.md"

# A skip is never a pass: with the landing page or its policy absent this check cannot judge.
spine_read "$TARGET" > "$T/readme" || spine_refuse "$TARGET is missing; it is the thing this doctrine governs."
spine_after_has "$POLICY" || spine_refuse "$POLICY is missing; the caps above would be unreviewable numbers."

fail=0
note(){ spine_fail "$1"; fail=1; }
lines=$(wc -l < "$T/readme" | tr -d ' '); bytes=$(wc -c < "$T/readme" | tr -d ' ')
routing_hint() {
  cat >&2 <<'HINT'
                 Route the new detail to its canonical home instead of growing the landing page:
                   user-facing feature detail ....... the user guide / the declared docs surface
                   current work and priorities ...... docs/tasks/, docs/TASK_TREE.md, ROADMAP.md
                   release history .................. CHANGELOG.md, git history
                   design rationale ................. docs/decisions/
                   exhaustive inventories ........... a generated index or a dedicated reference
                   diagnostics and procedure ........ TOOLBOX.md, contributor docs
                 Full policy: README_POLICY.md
HINT
}
[ "$lines" -le "$LINE_CAP" ] || { note "$TARGET is $lines lines (> cap $LINE_CAP)."; routing_hint; }
[ "$bytes" -le "$BYTE_CAP" ] || { note "$TARGET is $bytes bytes (> cap $BYTE_CAP)."; routing_hint; }
# Changelog leakage — exactly ONE class: a dated historical annotation is release history on a landing page.
dated=$(grep -cE '20[0-9]{2}-[0-9]{2}-[0-9]{2}' "$T/readme" || true)
if [ "${dated:-0}" -gt 0 ]; then
  note "$TARGET carries $dated date-stamped line(s) — release history belongs in CHANGELOG.md."
  grep -nE '20[0-9]{2}-[0-9]{2}-[0-9]{2}' "$T/readme" | head -5 | sed 's/^/                   /' >&2
fi
grep -q "$POLICY" "$T/readme" || note "$TARGET no longer links $POLICY — the caps must stay traceable to the decision that set them."

[ "$fail" -eq 0 ] || exit 1
spine_ok "OK — $TARGET is $lines/$LINE_CAP lines, $bytes/$BYTE_CAP bytes."
exit 0
