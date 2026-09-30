#!/usr/bin/env bash
# migration 0007 — clear a contract epoch this repository cannot resolve (REVIEW-2026-09.9.1).
# since: 1.0.1
# SPDX-License-Identifier: LGPL-2.1-or-later
# `.doctrine/config` is seeded from bedrock, whose `ci_range_since` names one of BEDROCK's commits. In a
# project that commit does not exist, and CI's `--range` rightly refuses an epoch it cannot resolve. A
# project's whole history is under the contract it received, so its epoch is empty.
set -uo pipefail
f=".doctrine/config"
[ -f "$f" ] || { echo "migration 0007: no $f"; exit 0; }
v="$(sed -n 's/^ci_range_since = *//p' "$f" | head -1)"
if [ -n "$v" ] && ! git rev-parse --verify -q "$v^{commit}" >/dev/null 2>&1; then
  t="$f.migration.$$"; cp -p "$f" "$t"
  awk '/^ci_range_since = / { print "ci_range_since ="; next } { print }' "$f" > "$t" && mv "$t" "$f"
  echo "migration 0007: cleared ci_range_since ($v is not a commit of this repository)"
else
  echo "migration 0007: nothing to do"
fi
