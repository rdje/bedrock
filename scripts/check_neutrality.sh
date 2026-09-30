#!/usr/bin/env bash
# NEUTRALITY — no spine logic names a language, a build or docs tool, or a harness (NT-09, NT-14).
# SPDX-License-Identifier: LGPL-2.1-or-later
#
# The spine is project-, harness- and language-neutral by contract (docs/decisions/
# decision_neutral_spine_and_packs.md). This is the contract as a gate, not a memory: every
# spine-class LOGIC file (scripts, hooks, workflows, migrations; comments stripped) is scanned for the
# terms in .doctrine/neutrality_terms; a hit is a breach unless .doctrine/neutrality_allow names the
# path with a reason. Evaluated in bedrock itself only (MAINTAINING.md present): a project may name
# its own language wherever it likes.
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib/spine.sh"; spine_init NEUTRALITY
T="$(spine_tmp)"
spine_after_has MAINTAINING.md || { spine_ok "OK — not the template itself; a project names its language freely"; exit 0; }
spine_read .doctrine/neutrality_terms > "$T/terms" || spine_refuse ".doctrine/neutrality_terms is missing"
terms="$(grep -vE '^[[:space:]]*(#|$)' "$T/terms" | paste -sd'|' -)"
[ -n "$terms" ] || spine_refuse ".doctrine/neutrality_terms has no term"
spine_re_valid "$terms" || spine_refuse ".doctrine/neutrality_terms holds an invalid pattern"
spine_read .doctrine/neutrality_allow 2>/dev/null | grep -vE '^[[:space:]]*(#|$)' > "$T/allow" || true
spine_read .bedrock/manifest > "$T/manifest" || { spine_fail ".bedrock/manifest is missing"; exit 1; }
# logic files: spine-class scripts, hooks, workflows, migrations (directory entries expanded)
grep -vE '^[[:space:]]*(#|$)' "$T/manifest" | awk '$2=="spine" { print $1 }' | while IFS= read -r p; do
  case "$p" in */) spine_after_ls | grep "^$p" ;; *) printf '%s\n' "$p" ;; esac
done | grep -E '\.(sh|yml|yaml)$|^\.githooks/|^scripts/[a-z_]+$' | sort -u > "$T/files"
fail=0; n=0; allowed=0
while IFS= read -r f; do
  n=$((n+1))
  hits="$(spine_read "$f" | sed 's/#.*//' | grep -niE "$terms" || true)"
  [ -n "$hits" ] || continue
  reason="$(awk -F'\t' -v f="$f" '$1!="" && f ~ "^" $1 "$" { print $2; exit }' "$T/allow")"
  if [ -n "$reason" ]; then allowed=$((allowed+1)); continue; fi
  spine_fail "$f names a language, tool or harness in logic (belongs in a pack or in .doctrine/ data; or add the path to .doctrine/neutrality_allow with a reason):"
  printf '%s\n' "$hits" | head -3 | cut -c1-140 | sed 's/^/    /' >&2
  fail=1
done < "$T/files"
[ "$fail" -eq 0 ] || exit 1
spine_ok "OK — $n spine logic files scanned, no language, tool or harness named ($allowed allowed with a recorded reason)"
exit 0
