#!/usr/bin/env bash
# MANIFEST — the ownership manifest (.bedrock/manifest) is complete and every spine path it names exists.
# SPDX-License-Identifier: LGPL-2.1-or-later
#
# In bedrock itself (MAINTAINING.md present): every path in the snapshot is classified, so a new file
# cannot ship unclassified — the updater would otherwise not know whether it may touch it (BR-01).
# In every project: every `spine`-class path the manifest names exists, so a half-installed spine
# (a registered check missing after an upgrade, BK-09) is a breach, not a surprise.
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib/spine.sh"; spine_init MANIFEST
T="$(spine_tmp)"
spine_read .bedrock/manifest > "$T/manifest" || { spine_fail ".bedrock/manifest is missing"; exit 1; }
grep -vE '^[[:space:]]*(#|$)' "$T/manifest" | awk 'NF>=2 { print $1 "\t" $2 }' > "$T/entries"
[ -s "$T/entries" ] || spine_refuse ".bedrock/manifest has no entries"
awk -F'\t' '$2 !~ /^(spine|seed|project|maintainer)$/ { print $1 " " $2 }' "$T/entries" > "$T/badclass"
[ ! -s "$T/badclass" ] || { spine_fail "unknown class in .bedrock/manifest: $(head -1 "$T/badclass")"; exit 1; }
fail=0
# 1. every spine path exists (directory entries: at least one path beneath)
spine_after_ls > "$T/all"
while IFS=$'\t' read -r p c; do
  [ "$c" = spine ] || continue
  case "$p" in
    */) grep -q "^$p" "$T/all" || { spine_fail "spine directory $p is empty or missing"; fail=1; } ;;
    *)  grep -qx "$p" "$T/all" || { spine_fail "spine path $p is missing (a half-installed spine)"; fail=1; } ;;
  esac
done < "$T/entries"
# 2. in bedrock itself: every path is classified
if grep -qx 'MAINTAINING.md' "$T/all"; then
  while IFS= read -r path; do
    grep -qx "$path" <(cut -f1 "$T/entries") && continue
    hit=0
    while IFS=$'\t' read -r p c; do case "$p" in */) case "$path" in "$p"*) hit=1; break ;; esac ;; esac; done < "$T/entries"
    [ "$hit" = 1 ] || { spine_fail "unclassified path (add it to .bedrock/manifest): $path"; fail=1; }
  done < "$T/all"
fi
[ "$fail" -eq 0 ] || exit 1
spine_ok "OK — $(wc -l < "$T/entries" | tr -d ' ') entries; every spine path present$(grep -qx 'MAINTAINING.md' "$T/all" && echo '; every path classified')"
exit 0
