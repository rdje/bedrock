#!/usr/bin/env bash
# knowledge-map/scripts/check_knowledge_map.sh — KNOWLEDGE-MAP doctrine.
# SPDX-License-Identifier: LGPL-2.1-or-later
# Verify the KNOWLEDGE_MAP.md in the AFTER snapshot equals a fresh render of its sources in that
# same snapshot. The pre-commit hook regenerates+stages the map, so this passes locally; it catches
# drift where the hook did not run (CI, a hand edit, a --no-verify commit).
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib/spine.sh"; spine_init KNOWLEDGE-MAP
T="$(spine_tmp)"
gen="$ROOT/knowledge-map/scripts/gen_knowledge_map.sh"

spine_read KNOWLEDGE_MAP.md > "$T/committed.md" || { spine_fail "KNOWLEDGE_MAP.md is missing — run knowledge-map/scripts/gen_knowledge_map.sh > KNOWLEDGE_MAP.md and stage it"; exit 1; }
bash "$gen" > "$T/fresh.md" || spine_refuse "the generator failed"
if ! diff -q "$T/fresh.md" "$T/committed.md" >/dev/null 2>&1; then
  spine_fail "KNOWLEDGE_MAP.md is out of sync with its sources — regenerate it:"
  echo "  knowledge-map/scripts/gen_knowledge_map.sh > KNOWLEDGE_MAP.md && git add KNOWLEDGE_MAP.md" >&2
  diff "$T/committed.md" "$T/fresh.md" | head -10 | sed 's/^/    /' >&2
  exit 1
fi
spine_ok "OK"
exit 0
