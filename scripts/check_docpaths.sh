#!/usr/bin/env bash
# scripts/check_docpaths.sh — DOCPATH doctrine.
# SPDX-License-Identifier: LGPL-2.1-or-later
#
# Tracked .md files must not embed checkout-specific absolute paths (they break for every other
# clone and leak local usernames). Repo-internal references must be repo-root-relative. Only the
# .md files this change touches are checked (fast), read from the AFTER snapshot.
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib/spine.sh"; spine_init DOCPATH

pattern='(/Users/[^ ]+|/home/[^ ]+)'
errs=0; n=0
for f in $(spine_changed_paths | grep -E '\.md$' || true); do
  n=$((n+1))
  if hits="$(spine_read "$f" | grep -nE "$pattern")"; then
    spine_fail "$f contains checkout-specific absolute path(s):"
    printf '%s\n' "$hits" | sed 's/^/    /' >&2
    errs=$((errs+1))
  fi
done
[ "$errs" -eq 0 ] || exit 1
spine_ok "OK — $n changed .md file(s), none carries a checkout-specific path"
exit 0
