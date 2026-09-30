#!/usr/bin/env bash
# migration 0005 — MEMORY.md's current-state fields take the names the RESUME-POINTER gate reads.
# since: 0.7.0   (0.7.0 made the pointer "upright" with `next_action`, `active_work_unit`,
#                 `latest_commit`, `in_flight_uncommitted`, `blockers`; older seeds used bold labels)
# SPDX-License-Identifier: LGPL-2.1-or-later
# Idempotent: only lines carrying the OLD labels change; their values are kept verbatim.
set -uo pipefail
[ -f MEMORY.md ] || { echo "migration 0005: no MEMORY.md"; exit 0; }
if ! grep -qE '^\s*-\s*\*\*(Active tree|Next action|Latest commit|In-flight uncommitted work|Blockers):\*\*' MEMORY.md; then
  echo "migration 0005: nothing to do"; exit 0
fi
t="MEMORY.md.migration.$$"; cp -p MEMORY.md "$t"
awk '
  { line = $0 }
  /^[[:space:]]*-[[:space:]]*\*\*Active tree:\*\*/               { sub(/\*\*Active tree:\*\*[[:space:]]*/, "active_work_unit: ", line) }
  /^[[:space:]]*-[[:space:]]*\*\*Next action:\*\*/               { sub(/\*\*Next action:\*\*[[:space:]]*/, "next_action: ", line) }
  /^[[:space:]]*-[[:space:]]*\*\*Latest commit:\*\*/             { sub(/\*\*Latest commit:\*\*[[:space:]]*/, "latest_commit: ", line) }
  /^[[:space:]]*-[[:space:]]*\*\*In-flight uncommitted work:\*\*/ { sub(/\*\*In-flight uncommitted work:\*\*[[:space:]]*/, "in_flight_uncommitted: ", line) }
  /^[[:space:]]*-[[:space:]]*\*\*Blockers:\*\*/                  { sub(/\*\*Blockers:\*\*[[:space:]]*/, "blockers: ", line) }
  { print line }' MEMORY.md > "$t" && mv "$t" MEMORY.md
grep -q '^- blockers:' MEMORY.md || printf -- '- blockers: none.\n' >> MEMORY.md
echo "migration 0005: MEMORY.md current-state fields renamed to next_action / active_work_unit / latest_commit / in_flight_uncommitted / blockers"
