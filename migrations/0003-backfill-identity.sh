#!/usr/bin/env bash
# migration 0003 — backfill .bedrock/project for a project created before the identity file existed.
# since: 0.16.0
# SPDX-License-Identifier: LGPL-2.1-or-later
# name = the repository directory; prefix = the first token of the latest commit subject's work-unit id,
# else the name upper-cased. Both are printed so the project can correct them in the same commit.
set -uo pipefail
if [ -f .bedrock/project ]; then echo "migration 0003: nothing to do"; exit 0; fi
name="$(basename "$(pwd)")"
prefix="$(git log -1 --format=%s 2>/dev/null | grep -oE '^[A-Z][A-Z0-9]*(-[A-Z0-9]+)*-[0-9]{4,}' | sed 's/-[0-9]*$//; s/-[A-Z0-9]*$//')"
[ -n "$prefix" ] || prefix="$(printf '%s' "$name" | tr '[:lower:]_' '[:upper:]-' | tr -cd 'A-Z0-9-' | sed 's/^-*//; s/-*$//; s/--*/-/g')"
[ -n "$prefix" ] || prefix="PROJECT"
mkdir -p .bedrock
cat > .bedrock/project <<SEED
# .bedrock/project — this project's identity (backfilled by migration 0003; correct name/title/prefix if wrong).
name = $name
title = $name
prefix = $prefix
created = $(date +%F)
source = ${1:-bedrock-scaffold}
packs =
SEED
echo "migration 0003: .bedrock/project written (name=$name, prefix=$prefix) — check it"
