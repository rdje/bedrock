#!/usr/bin/env bash
# scripts/check_memory_architecture.sh — MEMORY-ARCH invariants (MEMORY_ARCHITECTURE.md).
# SPDX-License-Identifier: LGPL-2.1-or-later
#
# Structural, harness-agnostic checks that the durable-memory layers exist and hold their shape,
# and that every document the spine depends on is present. Judged on the AFTER snapshot (the
# index locally, the commit in CI), never on the worktree. Cheap, deterministic, no network.
#
# ⛔ A LINE CAP ALONE DOES NOT BOUND THE RESUME POINTER, and the failure is measured, not
# hypothetical: on a real project running this spine, MEMORY.md sat at 60 lines — PASSING, exactly
# at its line cap — while carrying 138,403 BYTES (2,306 bytes per line, one line of 18,816 bytes).
# Line and byte caps are COMPLEMENTS. Both come from .doctrine/config (as of the LAST commit, so a
# commit cannot raise the cap that judges it); never raise a cap to fit the content — demote it.
#
# ⛔ THE SPINE'S OWN DOCUMENTS ARE CHECKED (BK-13): before this, deleting MEMORY_ARCHITECTURE.md,
# AGENTS.md, DOCTRINE_ENFORCEMENT.md, TOOLBOX.md and COMMIT.md in one commit left all checks green.
#
# ⭐ AGENTS.md IS THE CANONICAL AGENT ENTRY (NT-08): it is required and must route the reader to
# MEMORY_ARCHITECTURE.md and README.md. A harness file (CLAUDE.md, GEMINI.md, .cursorrules, …) is an
# OPTIONAL adapter: absent is fine; present, it must point at AGENTS.md. No vendor file is mandatory.
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib/spine.sh"; spine_init MEMORY-ARCH
errs=0
fail(){ spine_fail "$1"; errs=$((errs+1)); }
T="$(spine_tmp)"

# Layer A — the bounded resume pointer, by BOTH caps.
CAP="$(spine_config memory_pointer_line_cap 50)"; BYTE_CAP="$(spine_config memory_pointer_byte_cap 7168)"
case "$CAP$BYTE_CAP" in *[!0-9]*|"") spine_refuse ".doctrine/config: memory_pointer_line_cap / memory_pointer_byte_cap must be integers (got '$CAP' / '$BYTE_CAP')";; esac
if spine_read MEMORY.md > "$T/mem"; then
  lines=$(wc -l < "$T/mem" | tr -d ' '); bytes=$(wc -c < "$T/mem" | tr -d ' ')
  [ "$lines" -le "$CAP" ] || fail "MEMORY.md has $lines lines (> cap $CAP) — it is a bounded pointer, not a log; demote content to docs/tasks/ (B) or docs/decisions/ (C)"
  [ "$bytes" -le "$BYTE_CAP" ] || fail "MEMORY.md is $bytes bytes (> cap $BYTE_CAP) — long lines bypass the line cap; demote content, do NOT raise the cap"
else
  fail "MEMORY.md (layer-A resume pointer) is missing"
fi

# Layer C — decision records live one-per-file under docs/decisions/ with an INDEX listing each.
if spine_read docs/decisions/INDEX.md > "$T/index"; then
  for f in $(spine_after_ls 'docs/decisions/*.md'); do
    b="$(basename "$f")"
    case "$b" in INDEX.md|TEMPLATE.md) continue;; esac
    grep -qF "$b" "$T/index" || fail "decision record $b is not listed in docs/decisions/INDEX.md"
  done
else
  fail "docs/decisions/INDEX.md (layer-C index) is missing"
fi

# Layer B — the task-tree system exists.
spine_after_has docs/TASK_TREE.md || fail "docs/TASK_TREE.md (task-tree index) is missing"
[ -n "$(spine_after_ls 'docs/tasks/*.md')" ] || fail "docs/tasks/ (layer-B task-tree leaves) is missing or empty"

# The spine's own documents and entry points (the maintained inventory, MAINTAINING.md).
for f in README.md README_POLICY.md MEMORY_ARCHITECTURE.md AGENTS.md DOCTRINE_ENFORCEMENT.md TOOLBOX.md \
         COMMIT.md VISIBILITY.md DOCTRINE_VERSION LICENSE NOTICE docs/tasks/TEMPLATE.md docs/decisions/TEMPLATE.md \
         .doctrine/README.md scripts/check_doctrines.sh scripts/lib/spine.sh .githooks/pre-commit .githooks/commit-msg \
         .github/workflows/doctrines.yml; do
  spine_after_has "$f" || fail "$f (spine document) is missing"
done

# AGENTS.md is canonical; any harness adapter present must route to it.
if spine_read AGENTS.md > "$T/agents"; then
  grep -q 'MEMORY_ARCHITECTURE.md' "$T/agents" || fail "AGENTS.md does not point at MEMORY_ARCHITECTURE.md"
  grep -q 'README.md' "$T/agents" || fail "AGENTS.md does not point at README.md"
fi
for a in CLAUDE.md GEMINI.md .cursorrules .windsurfrules .github/copilot-instructions.md; do
  spine_after_has "$a" || continue
  spine_read "$a" | grep -q 'AGENTS.md' || fail "$a is a harness adapter and must point at AGENTS.md (the canonical instructions)"
done

[ "$errs" -eq 0 ] || exit 1
spine_ok "OK — MEMORY.md ${lines:-?}/$CAP lines, ${bytes:-?}/$BYTE_CAP bytes; layers B and C present; spine inventory complete"
exit 0
