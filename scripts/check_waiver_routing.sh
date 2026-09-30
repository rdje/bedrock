#!/usr/bin/env bash
# WAIVER-ROUTING — a task leaf that says a gate DOES NOT APPLY to it must name the leaf that owns
# fixing the gate. A waiver is a bug report about the gate; it must be routed, never inert.
#
# ⭐ THE DURABLE LAW THIS MECHANIZES: an author writing a waiver IS the gate reporting a missing
# capability. It is the single highest-signal defect report a gate can receive — it comes from
# someone who did the work, hit the boundary, and wrote down exactly where it was.
#
# Provenance (kept because the evidence is the argument, with the project's nouns removed): on a
# real project running this spine, an author wrote, by hand, INSIDE a ticked acceptance box, that
# the gate's diagnosis-signature families did not fit their defect class. They were RIGHT and
# precise — the gate modelled four families and none covered a build-flow defect — and NOTHING
# HAPPENED. The note sat unread for months until a later task re-derived the identical gap from
# scratch. A second leaf even wrote out its evidence under a "Diagnosis tool signatures:" heading
# and got no credit for it. The capability gap was reported, in writing, by the person best placed
# to see it, and the process had nowhere to put it.
#
# THE RULE
#   If a staged `docs/tasks/*.md` ADDS a line asserting a check/signature/gate does not apply,
#   cannot be satisfied, or is being waived, that file must ALSO cite an owning leaf id
#   (`TREE-NAME.4`, `TREE.4.2`, …) or a work-unit/slice id (`PREFIX-FAMILY-0001`). Otherwise:
#   block, and quote the line.
#
# ⛔ DESIGN CONSTRAINT, deliberate and load-bearing:
#   THIS MUST NOT PUNISH HONESTY. Forbidding waiver language outright would simply delete the
#   signal — authors would stop writing the note and the gap would become invisible again, which
#   is strictly worse than an unread note. So a waiver stays entirely LEGAL; it just has to name
#   an owner. One token, and the inert note becomes tracked work.
#
# ARCHETYPE: evidence (DOCTRINE_ENFORCEMENT.md §3).
#   HONEST LIMIT — this verifies an owner was NAMED, not that the owner is real or that the work
#   happens. Stated rather than hidden.
#
# CONTRACT: exit code is the verdict (0 holds · 1 breach · 2 REFUSED); explains on stderr;
# deterministic; read-only; judged on the AFTER snapshot through scripts/lib/spine.sh.
# SPDX-License-Identifier: LGPL-2.1-or-later
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib/spine.sh"; spine_init WAIVER-ROUTING
T="$(spine_tmp)"

# Top-level task-tree files this change touches. Nothing touched => nothing to judge.
staged="$(spine_changed_paths | grep -E '^docs/tasks/[^/]+\.md$' || true)"
[ -n "$staged" ] || { spine_ok "OK (no task leaf in this change)"; exit 0; }

# Waiver / inapplicability language. Kept tight and phrase-anchored so it fires on a real claim
# ("the signatures do not apply") and not on incidental prose containing the words separately.
# ⚠️ SCOPE-vs-CAPABILITY, and the sweep is what forced the distinction. The first draft triggered
# on any "the gate does not apply", which fired on a dozen HONEST SCOPE statements — "this slice is
# pure-docs, so the code-change gate does not apply". Those are correct and are NOT bug reports:
# the gate is behaving exactly as designed. The signal worth routing is narrower and sharper — a
# claim that the gate DOES apply but its SIGNATURE SURFACE cannot express the author's evidence.
# That narrower claim is the only thing this doctrine binds.
WAIVER_RE='(^|[^-[:alnum:]])[Ww]aiver note|[A-Z][A-Z0-9_]*_WAIVER|(signature|signatures|diagnosis.toolbox|diagnosis tool|diagnosis-tool)s? (do|does) not apply|no (signature|diagnosis) (family|group) (fits|matches|models|exists)|cannot be (satisfied|expressed) by (the|any) (gate|check|signature)|exempt from (the|this) (gate|check)'

# An owning leaf id (TREE.4 / TREE.4.2, or `.4` relative to this tree) or a work-unit id
# (PREFIX-FAMILY-0001). ⛔ AN OWNER MUST EXIST (REVIEW-2026-09.7, BK-16: "this V1.2 migration" used
# to discharge a waiver): a leaf id resolves to a `- ID:` section of an existing top-level tree file
# in this snapshot; a work-unit id is cited by some tree file. "An owner was named" became "an owner
# exists" — still not "the work happens", which stays the honest limit.
OWNER_RE='[A-Z][A-Z0-9-]+\.[0-9]+(\.[0-9]+)*[a-z]?|[A-Z][A-Z0-9]+(-[A-Z0-9]+)+-[0-9]{4,}|(^|[^A-Za-z0-9.])\.[0-9]+(\.[0-9]+)*[a-z]?'
owner_resolves() { # $1 = window text, $2 = this tree file (AFTER content path), $3 = this tree's id
  local id tree f b
  for id in $(printf '%s\n' "$1" | grep -oE "$OWNER_RE" | sed 's/^[^A-Za-z0-9.]//' | sort -u); do
    case "$id" in
      .*) b="$(spine_leaf_bounds "$2" "$3$id")"; [ -n "$b" ] && return 0 ;;
      *-[0-9][0-9][0-9][0-9]*) for f in $(spine_after_ls 'docs/tasks/*.md' | grep -E '^docs/tasks/[^/]+\.md$'); do spine_read "$f" | grep -qF "$id" && return 0; done ;;
      *) tree="${id%%.*}"; spine_read "docs/tasks/$tree.md" > "$T/owner_tree.md" 2>/dev/null || continue
         b="$(spine_leaf_bounds "$T/owner_tree.md" "$id")"; [ -n "$b" ] && return 0 ;;
    esac
  done
  return 1
}

fail=0
for file in $staged; do
  spine_read "$file" > "$T/file.md" || continue

  # ADDED lines only — this binds NEW claims, never the historical record.
  added="$(spine_added_text "$file" || true)"
  [ -n "$added" ] || continue

  # Bind only when this commit ADDS a waiver claim; the historical record is never retro-bound —
  # and only the ADDED waiver lines are judged (BR-17: adding one properly owned waiver used to
  # re-judge every old waiver in the file).
  # ⛔ Written to a FILE, not piped. `printf "$var" | grep -q` returns failure ON SUCCESS once the
  # producer exceeds the pipe buffer (~64 KiB) and the match is early: grep exits at the first
  # match, printf takes SIGPIPE (141), and `pipefail` promotes 141 to the pipeline status. This
  # site would then `continue` — i.e. SKIP the file and let an unrouted waiver through. It fails
  # OPEN, which is the worst direction. Measured on the originating project: PIPESTATUS=(141 0).
  added_file="$T/added.txt"; printf '%s\n' "$added" > "$added_file"
  if ! grep -qE "$WAIVER_RE" "$added_file"; then continue; fi
  spine_added_lines "$file" | sort -un > "$T/added.nums"
  tree_id="$(basename "$file" .md)"

  # A waiver is discharged when an owner is named in its immediate NEIGHBOURHOOD in the file
  # (the trigger line +/- WINDOW lines).
  #
  # ⚠️ WHY A WINDOW AND NOT THE SAME LINE — caught by USING this doctrine on its own first
  # customers. Markdown prose WRAPS, so "the diagnosis-toolbox signatures do not apply" and the
  # "(owned by TREE.4)" that discharges it routinely land on different physical lines. A strict
  # same-line rule is unsatisfiable for any wrapped paragraph and would push authors toward
  # deleting the waiver instead of owning it — the exact outcome this doctrine exists to prevent.
  # The window is kept SMALL so a leaf id elsewhere in the file cannot vacuously discharge a
  # waiver: the citation has to be in the same paragraph a human would read as one thought.
  WINDOW=6
  undischarged=""
  while IFS= read -r ln; do
    [ -n "$ln" ] || continue
    lo=$(( ln > WINDOW ? ln - WINDOW : 1 )); hi=$(( ln + WINDOW ))
    grep -qx "$ln" "$T/added.nums" || continue      # an old waiver line is history, not this change's claim
    win="$(sed -n "${lo},${hi}p" "$T/file.md" 2>/dev/null)"
    if ! owner_resolves "$win" "$T/file.md" "$tree_id"; then
      undischarged="${undischarged}${file}:${ln}: $(sed -n "${ln}p" "$T/file.md")"$'\n'
    fi
  done < <(grep -nE "$WAIVER_RE" "$T/file.md" 2>/dev/null | cut -d: -f1)
  [ -n "$undischarged" ] || continue

  fail=1
  {
    echo "WAIVER-ROUTING: $file states a gate does not apply, without naming the leaf that owns fixing it."
    printf '%s' "$undischarged" | sed 's/^/  offending: /'
    cat <<'MSG'
  A waiver is a BUG REPORT ABOUT THE GATE — the highest-signal one it can get, because it comes
  from someone who did the work and hit the boundary. It must be routed, not left inert.
  (A real waiver note of exactly this shape was correct and sat unread for months, until a later
  task re-derived the identical gap from scratch.)

  Discharge it by naming an owner that EXISTS, in the same paragraph — either is fine:
    - a leaf of an existing tree:  "... signatures do not apply (gate gap owned by TREE-NAME.5)"  (or `.5` of this tree)
    - a work-unit id some tree file cites, e.g. PREFIX-<FAMILY>-<NNNN>.
  A leaf or id that resolves to nothing is not an owner.
  ⛔ Do NOT delete the waiver to pass this check. Saying it is correct; owning it is the point.
MSG
  } >&2
done

if [ "$fail" -ne 0 ]; then
  exit 1
fi
echo "waiver-routing: OK (no unrouted gate-waiver claim added in the staged task leaves)"
exit 0
