#!/usr/bin/env bash
# TASK-ACCEPTANCE — a CODE change must be owned by a task-tree leaf that carries a ticked
# acceptance checklist, and each hard-gated box must be backed by EVIDENCE INSIDE ITS OWN BULLET.
# SPDX-License-Identifier: LGPL-2.1-or-later
#
# ⭐ THE DISCIPLINE, stated with no project's nouns: a change lands with (a) the CAUSE located,
# (b) the EFFECT measured, and (c) a statement that nothing regressed — each backed by output
# from a tool that was actually run, not by prose. "I fixed it" is a claim; a pasted verdict is
# an artifact someone else can re-run.
#
# ⭐⭐ WHY BOX-SCOPING IS THE SOUNDNESS PROPERTY: two leakage holes were MEASURED upstream —
#   (1) cross-FILE leakage (a co-staged unrelated tree file supplied the signature) and
#   (2) incidental-PROSE leakage (a token anywhere in the leaf counted as evidence).
#   ⇒ the signature must sit in the SAME BULLET as the box it backs.
#
# ⚠️ HONEST LIMIT: this verifies a box was TICKED and that tool-shaped output sits inside it. It
# cannot verify the output is true. The un-fakeable leg is re-running the cited command in CI.
#
# ⚠️ STILL OPEN HERE, closed by REVIEW-2026-09.4: the leaf is not yet bound to the commit subject,
# evidence is not yet required to be NEW in this change, and labels are matched by keyword. What
# this revision fixes: the change is read from the index/commit (not the worktree), deletions and
# renames are governed, `.doctrine/` is read from the LAST commit so a commit cannot loosen its own
# gate (BK-06), an invalid pattern is REFUSED (BR-05), and a tree file is top-level only (BK-15).
#
# ── PROJECT SEAMS ──────────────────────────────────────────────────────────────────────────────
#   .doctrine/code_paths.txt       one EXTENDED REGULAR EXPRESSION per line (not a glob) — what
#                                  counts as a CODE change here. Absent → the built-in default.
#   .doctrine/evidence_tokens.txt  one ERE per line — your tools' output signatures, ADDED to the
#                                  universal defaults. Absent → defaults only.
#   Both are validated at load and read as of the LAST commit.
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib/spine.sh"; spine_init TASK-ACCEPTANCE
T="$(spine_tmp)"

# ── what counts as a code change (from BEFORE; a repair of an invalid file is allowed when the
#    change touches nothing but .doctrine/ and documentation) ─────────────────────────────────
default_code_re='(^|/)(crates|src|scripts)/|\.(rs|sh)$|(^|/)Makefile$'
load_re() { # $1 = file under .doctrine/, $2 = default → sets LOADED_RE (never in a subshell: a refusal must end the CHECK)
  local lines
  lines="$(spine_config_file "$1")"
  [ -n "$lines" ] || { LOADED_RE="$2"; return 0; }
  if ! spine_re_from_lines "$lines"; then
    # only .doctrine/ and .md touched → judge with the AFTER file (the repair itself), else refuse
    if [ -z "$(spine_touched_paths | grep -vE '^\.doctrine/|\.md$' || true)" ]; then
      lines="$(spine_read ".doctrine/$1" | grep -vE '^[[:space:]]*(#|$)' || true)"
      spine_re_from_lines "$lines" || spine_refuse ".doctrine/$1 still holds an invalid regular expression ('$SPINE_BAD_RE')"
    else
      spine_refuse ".doctrine/$1 as of the last commit holds an invalid regular expression ('$SPINE_BAD_RE'); repair it in a change that touches only .doctrine/ and documentation"
    fi
  fi
  LOADED_RE="${SPINE_RE:-$2}"
}
load_re code_paths.txt "$default_code_re"; code_re="$LOADED_RE"

spine_touched_paths > "$T/touched.txt"
[ -s "$T/touched.txt" ] || { spine_ok "NOT EVALUATED — no change"; exit 0; }
# grep a FILE, never `printf | grep -q` (under pipefail the producer takes SIGPIPE and the pipeline
# reports FAILURE ON SUCCESS once the input is large — a silent fail-open).
grep -E "$code_re" "$T/touched.txt" > "$T/code.txt" 2>/dev/null || true
[ -s "$T/code.txt" ] || { spine_ok "OK — no code path in this change"; exit 0; }

# A tree file is TOP-LEVEL docs/tasks/<TREE>.md only (BK-15); TEMPLATE.md is the blank form.
spine_changed_paths | grep -E '^docs/tasks/[^/]+\.md$' | grep -vE '(^|/)TEMPLATE\.md$' > "$T/leaves.txt" || true
if [ ! -s "$T/leaves.txt" ]; then
  {
    echo "TASK-ACCEPTANCE: a CODE change is present but NO owning task-tree leaf (docs/tasks/<TREE>.md) is."
    echo "  code paths:"; sed 's/^/    /' "$T/code.txt"
    echo "  Stage the docs/tasks/<TREE>.md that owns this change, carrying the acceptance checklist."
  } >&2
  exit 1
fi

# ── evidence signatures ──────────────────────────────────────────────────────────────────────
# Universal defaults: standard build-flow forensics any project has, plus generic result shapes
# (`exit=N`, `rc=N`, `N pass / N fail`) because that is what tools actually print.
DEFAULT_SIG='error\[E[0-9]{4}\]|could not compile|clippy::[a-z_]{3,}|panicked at|assertion (failed|`)|test result: (ok|FAILED)|running [0-9]+ tests?|cargo (test|build|bench|flamegraph)|flamegraph|self-time|call-graph|/usr/bin/sample|\bspindump\b|\bperf (record|stat)\b|\bvalgrind\b|git (ls-files|log -S|log --all -S|rev-list|fsck|reflog|diff-tree|merge-base|cat-file|show )|\bshellcheck\b|bash -n |sh -n |make -n |make --dry-run|\bE2BIG\b|\bENOSPC\b|\bEACCES\b|\bARG_MAX\b|exit(ed)?[ =:](code )?[0-9]+|\brc=[0-9]+|PIPESTATUS|[0-9]+ (pass|passed|ok)[ ,/]+[0-9]+ (fail|failed)|version [0-9]{4,}|[0-9]+\.[0-9]+\.[0-9]+'
SIG="$DEFAULT_SIG"
load_re evidence_tokens.txt ""; extra="$LOADED_RE"
[ -n "$extra" ] && SIG="$SIG|$extra"

fail=0
while IFS= read -r leaf; do
  [ -n "$leaf" ] || continue
  spine_read "$leaf" > "$T/leaf.md" || continue
  for spec in 'ROOT CAUSE:root.?cause' 'ADDRESSED:addressed' 'NO REGRESSION:no.?regress'; do
    label="${spec%%:*}"; kw="${spec#*:}"
    # A box's BULLET = the "- [x] ..." line plus its indented continuation lines. POSIX awk only:
    # no IGNORECASE (a gawk extension BSD awk silently ignores); tolower() is POSIX.
    awk -v kw="$kw" '
      BEGIN{ inbox=0 }
      {
        line = $0
        isbox = (line ~ /^[[:space:]]*-[[:space:]]*\[[xX ]\]/)
        if (isbox) {
          if (inbox) exit
          if (match(tolower(line), kw)) { inbox=1; print; next }
          next
        }
        if (inbox) {
          if (line ~ /^[[:space:]]+/ || line ~ /^[[:space:]]*$/) { print; next }
          exit
        }
      }
    ' "$T/leaf.md" > "$T/box.txt"
    if [ ! -s "$T/box.txt" ]; then
      spine_fail "$leaf has no '$label' box in its acceptance checklist."; fail=1; continue
    fi
    if ! head -1 "$T/box.txt" | grep -qE '\[[xX]\]'; then
      spine_fail "$leaf — the '$label' box is present but NOT ticked."; fail=1; continue
    fi
    if ! grep -qE "$SIG" "$T/box.txt"; then
      {
        echo "TASK-ACCEPTANCE: $leaf — the '$label' box is ticked but carries no tool-output evidence"
        echo "  INSIDE ITS OWN BULLET. A tick is a claim; the box asks for output from a command you ran."
        echo "  Add the invocation and its real output to that bullet, or declare your project's own"
        echo "  signatures in .doctrine/evidence_tokens.txt (one extended regular expression per line)."
      } >&2
      fail=1
    fi
  done
done < "$T/leaves.txt"

[ "$fail" -eq 0 ] || exit 1
spine_ok "OK (every code-change leaf carries a ticked, evidence-backed checklist)"
exit 0
