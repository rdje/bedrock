#!/usr/bin/env bash
# migration 0001 — remove self-reported currency fields (`Last updated:` and kin) from tracked Markdown.
# since: 0.5.0   (LIVE-DOC-CURRENCY was introduced in 0.5.0; trees created from an older template
#                 carry the field the old task template shipped, and it blocks every commit — BK-10)
# SPDX-License-Identifier: LGPL-2.1-or-later
# Idempotent. Prints what it changed. Run by scripts/update_scaffold.sh with cwd = the project root.
set -uo pipefail
n=0
for f in $(git ls-files '*.md'); do
  [ -f "$f" ] || continue
  if grep -qiE '^[[:space:]]*(-[[:space:]]*|\*[[:space:]]*|>[[:space:]]*)?(\*\*)?(last[ -]updated|last[ -]modified|updated[ -]on)(\*\*)?[[:space:]]*:' "$f"; then
    tmp="$f.migration.$$"; cp -p "$f" "$tmp"
    grep -viE '^[[:space:]]*(-[[:space:]]*|\*[[:space:]]*|>[[:space:]]*)?(\*\*)?(last[ -]updated|last[ -]modified|updated[ -]on)(\*\*)?[[:space:]]*:' "$f" > "$tmp"; mv "$tmp" "$f"
    echo "migration 0001: removed the currency field from $f"; n=$((n+1))
  fi
done
echo "migration 0001: $n file(s) changed"
