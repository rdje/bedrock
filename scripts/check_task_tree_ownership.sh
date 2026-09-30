#!/usr/bin/env bash
# scripts/check_task_tree_ownership.sh — TASK-TREE-OWNERSHIP: a governed change is BOUND to one leaf.
# SPDX-License-Identifier: LGPL-2.1-or-later
#
# THE CONTRACT (docs/decisions/decision_ownership_contract.md, REVIEW-2026-09.4):
#   1. Every path is GOVERNED except declared documentation (deny-by-default, NT-03), and the spine
#      set is governed whatever a project declares (BK-05). Deletions and renames count (BR-08).
#   2. A governed change names exactly one leaf in its subject: `(leaf <TREE>.<n>)` (BR-02).
#   3. That leaf exists in `docs/tasks/<TREE>.md`, that file is part of the change, and the leaf's
#      section gains lines in this change — the commit-log row and its evidence (BK-01).
#   4. An OPEN leaf may own several commits; a leaf that was already `done` before this change may
#      own none: open a child leaf. (The gate cannot tell yesterday's ticked boxes from today's.)
#   5. `Spine-Exception: <reason>` in the message is the ONLY bypass: stored in history, honoured by
#      every check identically, listed and counted by CI. The environment variable is gone (BK-08).
#   6. A merge commit is exempt from binding (its parents were judged); invariants still run.
#
# ⛔ THIS IS A MESSAGE-TIME CHECK. Binding needs the subject and the index together, which exist in
#    the commit-msg hook and in CI (per commit). In the pre-commit hook there is no message yet, so
#    the check says NOT EVALUATED rather than pretending; the commit-msg hook then judges it before
#    the commit lands. `scripts/check_doctrines.sh --message <file>` judges a dry run.
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib/spine.sh"; spine_init TASK-TREE-OWNERSHIP
T="$(spine_tmp)"

spine_load_docs_re
spine_governed_paths > "$T/governed.txt"
[ -s "$T/governed.txt" ] || { spine_ok "OK — no governed path in this change (documentation only)"; exit 0; }

[ -n "${SPINE_COMMIT_MSG:-}" ] || { spine_ok "NOT EVALUATED — binding needs the commit message; the commit-msg hook and CI supply it (dry run: scripts/check_doctrines.sh --message <file>)"; exit 0; }
[ "${SPINE_MERGE:-0}" = 1 ] && { spine_ok "OK — merge commit: binding exempt (its parents were judged)"; exit 0; }

exception="$(spine_msg_exception "$SPINE_COMMIT_MSG")"
if [ -n "$exception" ]; then
  spine_ok "EXCEPTION — $(wc -l < "$T/governed.txt" | tr -d ' ') governed path(s) land without a leaf: Spine-Exception: $exception"
  exit 0
fi

leaf="$(spine_msg_leaf "$SPINE_COMMIT_MSG")"
n_leaf="$(spine_msg_subject "$SPINE_COMMIT_MSG" | grep -oE '\(leaf ' | wc -l | tr -d ' ')"
if [ -z "$leaf" ] || [ "$n_leaf" != 1 ]; then
  {
    echo "TASK-TREE-OWNERSHIP: governed paths change but the subject names no leaf (exactly one '(leaf <TREE>.<n>)' is required):"
    sed 's/^/    /' "$T/governed.txt"
    echo "  Every path except documentation is governed (declare documentation in .doctrine/docs_paths.txt; the"
    echo "  spine set — hooks, workflows, .doctrine/, scripts/check_*, scripts/lib, DOCTRINE_VERSION — always is)."
    echo "  Name the owning leaf in the subject, e.g. 'PROJ-AREA-0007 (leaf FEATURE-X.2): …', or record a"
    echo "  deliberate exception as a trailer:  Spine-Exception: <why no leaf applies>"
  } >&2
  exit 1
fi

tree="${leaf%%.*}"; file="docs/tasks/$tree.md"
spine_after_has "$file" || { spine_fail "the subject names leaf $leaf but $file does not exist in this change"; exit 1; }
spine_changed_paths | grep -qx "$file" || { spine_fail "the subject names leaf $leaf but $file is not part of this change — the leaf's section must gain its commit-log row and evidence in the same commit"; exit 1; }
spine_read "$file" > "$T/after.md"
bounds="$(spine_leaf_bounds "$T/after.md" "$leaf")"
[ -n "$bounds" ] || { spine_fail "the subject names leaf $leaf but $file has no '- ID: \`$leaf\`' section"; exit 1; }
start="${bounds% *}"; end="${bounds#* }"

# a leaf that was already done before this change cannot own it
if spine_read_before "$file" > "$T/before.md" 2>/dev/null; then
  b="$(spine_leaf_bounds "$T/before.md" "$leaf")"
  if [ -n "$b" ]; then
    st="$(spine_leaf_status "$T/before.md" "${b% *}" "${b#* }")"
    if [ "$st" = "done" ]; then
      spine_fail "leaf $leaf was already \`done\` before this change, so it cannot own a new commit — open a child leaf ($leaf.<n>) with its own root cause and evidence, and name that one"
      exit 1
    fi
  fi
fi

# the leaf's section must gain lines in this change
spine_added_lines "$file" | awk -v s="$start" -v e="$end" '$1>=s && $1<=e { n++ } END { exit (n>0 ? 0 : 1) }' \
  || { spine_fail "leaf $leaf's section in $file gains no line in this change — add the commit-log row and this change's evidence to the leaf that owns it"; exit 1; }

spine_ok "OK — $(wc -l < "$T/governed.txt" | tr -d ' ') governed path(s) bound to leaf $leaf ($file lines ${start}–$end, status \`$(spine_leaf_status "$T/after.md" "$start" "$end")\`)"
exit 0
