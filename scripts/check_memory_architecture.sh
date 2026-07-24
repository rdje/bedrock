#!/usr/bin/env bash
# scripts/check_memory_architecture.sh — MEMORY-ARCH invariants (MEMORY_ARCHITECTURE.md).
#
# Structural, harness-agnostic checks that the durable-memory layers exist and hold
# their shape. Cheap, deterministic, no network.
set -uo pipefail
ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
errs=0
fail(){ echo "MEMORY-ARCH: $1" >&2; errs=$((errs+1)); }

# Layer A — the bounded resume pointer must exist and stay bounded.
[ -f MEMORY.md ] || fail "MEMORY.md (layer-A resume pointer) is missing"
if [ -f MEMORY.md ]; then
  lines=$(wc -l < MEMORY.md)
  # Soft cap: the resume pointer is overwrite-only and must not grow into a log.
  [ "$lines" -le 120 ] || fail "MEMORY.md has $lines lines (> 120) — it is a bounded pointer, not a log"
fi

# Layer C — decision records live one-per-file under docs/decisions/ with an INDEX.
[ -d docs/decisions ] || fail "docs/decisions/ (layer-C decision records) is missing"
[ -f docs/decisions/INDEX.md ] || fail "docs/decisions/INDEX.md is missing"
# Every decision record (excluding INDEX/TEMPLATE) must be listed in the index.
if [ -d docs/decisions ]; then
  for f in docs/decisions/*.md; do
    b="$(basename "$f")"
    case "$b" in INDEX.md|TEMPLATE.md) continue;; esac
    grep -q "$b" docs/decisions/INDEX.md || fail "decision record $b is not listed in docs/decisions/INDEX.md"
  done
fi

# Layer B — the task-tree system exists.
[ -f docs/TASK_TREE.md ] || fail "docs/TASK_TREE.md (task-tree index) is missing"
[ -d docs/tasks ] || fail "docs/tasks/ (task-tree leaves) is missing"

# Tool-neutral bootstrap entrypoints exist.
[ -f README.md ] || fail "README.md (tool-neutral entrypoint) is missing"
[ -f CLAUDE.md ] || fail "CLAUDE.md (agent bootstrap) is missing"

[ "$errs" -eq 0 ] || exit 1
exit 0
