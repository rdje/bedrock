#!/usr/bin/env bash
# scripts/check_task_tree_ownership.sh — TASK-TREE-OWNERSHIP doctrine.
# SPDX-License-Identifier: LGPL-2.1-or-later
#
# Binding rule: no code change lands unless a task-tree leaf owns it. When a change touches
# source/build files — ADDED, MODIFIED, DELETED or RENAMED (BR-08: `--diff-filter=ACM` used to let
# a deletion or a rename through unowned) — the SAME change must also touch a task-tree file under
# docs/tasks/. This is the structural half; TASK-ACCEPTANCE judges the leaf's evidence.
#
# ⚠️ The code classification below is still an allow-list of paths. REVIEW-2026-09.4 replaces it
# with deny-by-default governance (everything but declared documentation) shared by every check.
# SPINE_ALLOW_UNOWNED is honoured until the same leaf replaces it with the Spine-Exception trailer.
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib/spine.sh"; spine_init TASK-TREE-OWNERSHIP

[ "${SPINE_ALLOW_UNOWNED:-0}" = "1" ] && { spine_ok "bypassed by SPINE_ALLOW_UNOWNED=1 (deprecated; removed in REVIEW-2026-09.4)"; exit 0; }

code_changed=""; tree_touched=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  case "$f" in
    docs/tasks/*) tree_touched=1 ;;
    *.rs|crates/*|src/*|build.rs|Cargo.toml|Cargo.lock|*/Cargo.toml) code_changed="${code_changed}    $f"$'\n' ;;
  esac
done <<PATHS
$(spine_touched_paths)
PATHS

if [ -n "$code_changed" ] && [ "$tree_touched" = "0" ]; then
  spine_fail "code files changed (added, modified, deleted or renamed) but no docs/tasks/ leaf was updated in this change:"
  printf '%s' "$code_changed" >&2
  spine_fail "  Create/extend a task-tree leaf that owns this change."
  exit 1
fi
spine_ok "OK"
exit 0
