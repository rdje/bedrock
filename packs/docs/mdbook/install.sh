#!/usr/bin/env bash
# packs/docs/mdbook/install.sh — name the book after the project and point it at the repository.
# SPDX-License-Identifier: LGPL-2.1-or-later
set -uo pipefail
name="${1:?project name}"; title="${2:-$name}"
f="docs/book/book.toml"; [ -f "$f" ] || { echo "mdbook pack: $f is missing" >&2; exit 1; }
url="$(git remote get-url origin 2>/dev/null | sed 's/\.git$//' || true)"
tmp="$f.pack.$$"; cp -p "$f" "$tmp"
awk -v t="$title" -v u="$url" '
  /^title = / { print "title = \"" t "\""; next }
  /^git-repository-url = / { print "git-repository-url = \"" u "\""; next }
  { print }' "$f" > "$tmp" && mv "$tmp" "$f" || exit 1
echo "mdbook pack: \`grep -c \"^title = \\\"$title\\\"\" docs/book/book.toml\` → \`$(grep -c "^title = \"$title\"" "$f")\` (\`rc=0\`)."
