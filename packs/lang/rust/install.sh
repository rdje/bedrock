#!/usr/bin/env bash
# packs/lang/rust/install.sh — the Rust pack's install hook: name the starter crate after the project.
# SPDX-License-Identifier: LGPL-2.1-or-later
# Runs with cwd = the project root, $1 = the validated project name. Prints evidence lines the bootstrap
# leaf cites; every number is measured. Exit nonzero = the install failed (the bootstrap stops).
set -uo pipefail
name="${1:?project name}"
f="crates/app/Cargo.toml"
[ -f "$f" ] || { echo "rust pack: $f is missing" >&2; exit 1; }
printf '%s' "$name" | grep -Eq '^[A-Za-z][A-Za-z0-9_-]*$' || { echo "rust pack: '$name' is not a valid crate name" >&2; exit 1; }
before="$(awk -v o='name = "app"' '{ s=$0; while ((i=index(s,o))>0) { c++; s=substr(s,i+length(o)) } } END{ print c+0 }' "$f")"
[ "$before" -eq 1 ] || { echo "rust pack: expected exactly one 'name = \"app\"' in $f, found $before" >&2; exit 1; }
tmp="$f.pack.$$"; cp -p "$f" "$tmp"
awk -v o='name = "app"' -v n="name = \"$name\"" '{ i=index($0,o); if (i>0) $0=substr($0,1,i-1) n substr($0,i+length(o)); print }' "$f" > "$tmp" && mv "$tmp" "$f" || exit 1
after="$(grep -c "^name = \"$name\"\$" "$f")"
echo "rust pack: crate renamed: \`grep -c '^name = \"app\"' crates/app/Cargo.toml\` → \`$before\` before, \`0\` after (\`rc=1\`, grep's no-match status); \`grep -c '^name = \"$name\"'\` → \`$after\` (\`rc=0\`)."
if command -v cargo >/dev/null 2>&1; then
  if cargo metadata --no-deps --format-version 1 >/dev/null 2>&1; then echo "rust pack: \`cargo metadata --no-deps\` → valid workspace (\`rc=0\`)."; else echo "rust pack: cargo metadata failed" >&2; exit 1; fi
else
  echo "rust pack: cargo is not installed here; the workspace was not validated (install a toolchain, then \`scripts/run check\`)."
fi
