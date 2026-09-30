#!/usr/bin/env bash
# migration 0006 — record the packs a project created before packs existed already carries (REVIEW-2026-09.8).
# since: 0.19.0
# SPDX-License-Identifier: LGPL-2.1-or-later
# A Rust workspace at the root means the rust pack; docs/book/ means mdbook; a harness adapter file means
# its harness pack. Recorded in .bedrock/project `packs =` so the updater syncs those packs' files.
set -uo pipefail
[ -f .bedrock/project ] || { echo "migration 0006: no .bedrock/project (migration 0003 creates it)"; exit 0; }
have="$(sed -n 's/^packs = //p' .bedrock/project | head -1 | tr ',' ' ')"
add=""
has() { case " $have $add " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }
[ -f Cargo.toml ] && ! has rust && add="$add rust"
[ -f docs/book/book.toml ] && ! has mdbook && add="$add mdbook"
[ -f CLAUDE.md ] && ! has claude && add="$add claude"
[ -f GEMINI.md ] && ! has gemini && add="$add gemini"
[ -f QWEN.md ] && ! has qwen && add="$add qwen"
add="${add# }"
[ -n "$add" ] || { echo "migration 0006: nothing to do"; exit 0; }
all="$(printf '%s' "$have $add" | tr ' ' '\n' | grep -v '^$' | paste -sd, -)"
t=".bedrock/project.migration.$$"; cp -p .bedrock/project "$t"
awk -v p="$all" '/^packs = / { print "packs = " p; next } { print }' .bedrock/project > "$t" && mv "$t" .bedrock/project
grep -q '^packs = ' .bedrock/project || printf 'packs = %s\n' "$all" >> .bedrock/project
echo "migration 0006: packs recorded in .bedrock/project: $all"
