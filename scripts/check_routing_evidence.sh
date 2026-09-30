#!/usr/bin/env bash
# ROUTING-EVIDENCE — a task leaf that routes a finding OUT to a DIFFERENT task tree must record
# what it measured before deciding the finding belongs to that family.
#
# Provenance: an incident in the originating project (ported by BEDROCK-MAINTENANCE.2.6): a leaf
# routed a target-accounting mismatch to another family as "that family's model, not the shared
# gate". It was neither — the defect sat in the SHARED gate, the same run got a second family wrong
# the same way, and the evidence that settled it (cross-family arithmetic over the run's own
# summary) was already on disk at routing time. The misroute cost a session.
#
# THE RULE
#   If a staged `docs/tasks/A.md` adds a line that routes a finding to a DIFFERENT tree, that file
#   must contain a `ROUTING EVIDENCE` section. Otherwise: block, and quote the line.
#
#   The discriminator is routing OUT OF THE TREE, deliberately. `routed to .4` (a leaf of the same
#   tree) is ordinary intra-tree bookkeeping and is the common case (measured upstream: 17 such
#   lines, 0 flagged). Flagging those would be noise, and a check that cries wolf gets bypassed.
#
# ⚠️ THE FIRST CUT UPSTREAM WOULD NOT HAVE CAUGHT ITS OWN FOUNDING INCIDENT: it was keyed on the
#   destination being spelled as a tree ID. The predicate is keyed on the SEMANTICS of leaving the
#   tree instead, and `--self-test` pins the founding phrasing.
#
# ⚠️ KNOWN FALSE-POSITIVE CLASS: a leaf that merely DISCUSSES routing — quoting the trigger phrases,
#   as the leaf documenting this doctrine must — fires it. Accepted: the discharge is one section, it
#   errs toward asking rather than staying silent, and narrowing around quotation would re-introduce
#   the phrasing-guessing that made the first cut miss.
#
# ARCHETYPE: evidence. HONEST LIMIT — this verifies the reasoning was RECORDED, not that the
#   reproduction was attempted or that its conclusion was right.
# CONTRACT: exit code is the verdict (0 holds · 1 breach · 2 REFUSED); explains on stderr;
#   deterministic; read-only; judged on the change through scripts/lib/spine.sh.
# SPDX-License-Identifier: LGPL-2.1-or-later
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib/spine.sh"; spine_init ROUTING-EVIDENCE
T="$(spine_tmp)"

ROUTE_OUT_RE='routed out|routing out|route(d)? it to (that|another)|routed to (another|that) (family|tree)|belongs to another (family|tree)|filed against the [a-z0-9_-]+ (family|tree)|(that|another) (family|tree)'"'"'s (model|problem|defect|business)'

if [ "${1:-}" = "--self-test" ]; then
  fails=0
  while IFS= read -r line; do
    printf '%s\n' "$line" | grep -iEq "$ROUTE_OUT_RE" || { echo "ROUTING-EVIDENCE self-test: MUST fire: $line" >&2; fails=1; }
  done <<'EOT'
routed out to the accounting family: the mismatch is that family's model, not gate wiring
this belongs to another tree; routing out
we routed it to that family for the fix
EOT
  while IFS= read -r line; do
    printf '%s\n' "$line" | grep -iEq "$ROUTE_OUT_RE" && printf '%s\n' "$line" | grep -viEq 'routed[- ]in' && { echo "ROUTING-EVIDENCE self-test: must NOT fire: $line" >&2; fails=1; }
  done <<'EOT'
routed to `.4` (a leaf of this tree) for the follow-up
the finding was routed in from the engine tree
EOT
  [ "$fails" = 0 ] && echo "ROUTING-EVIDENCE --self-test: 5/5 arms" || exit 1
  exit 0
fi

staged="$(spine_changed_paths | grep -E '^docs/tasks/[^/]+\.md$' || true)"
[ -n "$staged" ] || { spine_ok "ok (no task leaf in this change)"; exit 0; }

fail=0
for file in $staged; do
  case "$file" in docs/tasks/TEMPLATE.md) continue ;; esac
  spine_read "$file" > "$T/leaf.md" || continue
  # ADDED lines that assert routing a finding OUT of this tree. `routed in` is the RECEIVING side.
  offending="$(spine_added_text "$file" \
               | grep -iE "$ROUTE_OUT_RE" \
               | grep -viE 'routed[- ]in' \
               | cut -c1-160 | sed 's/^/    /' || true)"
  [ -n "$offending" ] || continue
  if grep -qE '^[^[:alnum:]]*ROUTING EVIDENCE|## .*[Rr]outing [Ee]vidence' "$T/leaf.md"; then
    continue
  fi
  fail=1
  {
    echo "ROUTING-EVIDENCE: $file routes a finding to ANOTHER task tree with no recorded routing evidence."
    echo "  routing statement(s):$offending"
    echo
    echo "  Add a 'ROUTING EVIDENCE' section to $file answering the question a misroute never asks:"
    echo "    1. does the finding REPRODUCE OUTSIDE the family you are routing it to?"
    echo "       (a defect that also fires for another component is not that component's defect)"
    echo "    2. what did you MEASURE to place it there — not what makes it plausible?"
    echo "    3. what would have to be true for the routing to be WRONG, and did you check it?"
    echo
    echo "  If you routed it on reasoning alone, say so in that section. An honest"
    echo "  'not checked outside this family' is a legal answer and a useful signal; a silent routing is not."
  } >&2
done

[ "$fail" -eq 0 ] && spine_ok "ok"
[ "$fail" -eq 0 ] || exit 1
exit 0
