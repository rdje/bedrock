#!/usr/bin/env bash
# BOOK-COVERAGE — the user guide names everything a user can meet: every doctrine, every entry point,
# every `.doctrine/` seam, every pack and every migration.
# SPDX-License-Identifier: LGPL-2.1-or-later
#
# A guide that restates the spine goes stale the day a check is added. This gate makes the omission a
# breach instead of a discovery: a new doctrine, script, seam, pack or migration cannot land in bedrock
# without the book (`docs/book/src/`) mentioning it by name. It verifies PRESENCE, not quality — the
# honest limit — but presence is what rots silently. Evaluated in bedrock itself only (the book is
# bedrock's; a project's own book is its own business).
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib/spine.sh"; spine_init BOOK-COVERAGE
T="$(spine_tmp)"
spine_after_has MAINTAINING.md || { spine_ok "OK — not the template itself"; exit 0; }
spine_after_ls 'docs/book/src/*.md' > "$T/chapters"
[ -s "$T/chapters" ] || { spine_fail "docs/book/src/ holds no chapter — the user guide is missing"; exit 1; }
: > "$T/book.txt"
while IFS= read -r c; do spine_read "$c" >> "$T/book.txt"; done < "$T/chapters"
fail=0
need() { # $1 = kind, $2 = the literal name the book must contain
  grep -qF -- "$2" "$T/book.txt" || { spine_fail "the user guide (docs/book/src/) never names the $1 \`$2\`"; fail=1; }
}
# every registered doctrine
spine_read scripts/check_doctrines.sh > "$T/driver" || spine_refuse "cannot read the driver"
for id in $(grep -E '^[[:space:]]*(DOCTRINES\+=\()?"[A-Z-]+\|' "$T/driver" | sed 's/.*"\([A-Z-]*\)|.*/\1/' | sort -u); do need doctrine "$id"; done
# every entry point, seam, pack and migration in the snapshot
for f in $(spine_after_ls 'scripts/*' | grep -E '^scripts/[^/]+$' | grep -vE '^scripts/check_'); do need "entry point" "$f"; done
for f in $(spine_after_ls '.doctrine/*' | grep -vE 'README\.md$'); do need "project seam" "$f"; done
for d in $(spine_after_ls 'packs/*' | grep -E '^packs/[a-z]+/[a-z0-9_-]+/pack$' | sed 's|/pack$||'); do need pack "$d"; done
for m in $(spine_after_ls 'migrations/*' | sed 's|^migrations/||; s|\.sh$||'); do need migration "$m"; done
[ "$fail" -eq 0 ] || { spine_fail "  Document it in the chapter it belongs to (docs/book/src/), in the same commit."; exit 1; }
spine_ok "OK — $(wc -l < "$T/chapters" | tr -d ' ') chapters name every doctrine, entry point, seam, pack and migration"
exit 0
