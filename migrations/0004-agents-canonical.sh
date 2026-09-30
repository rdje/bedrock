#!/usr/bin/env bash
# migration 0004 — AGENTS.md becomes the canonical instruction file; CLAUDE.md a one-line adapter (NT-08).
# since: 0.13.0
# SPDX-License-Identifier: LGPL-2.1-or-later
# Older templates had the body in CLAUDE.md and AGENTS.md pointing at it. The BODY is moved, not lost:
# the project's CLAUDE.md content becomes AGENTS.md; CLAUDE.md becomes the adapter.
set -uo pipefail
if [ -f CLAUDE.md ] && ! grep -q 'AGENTS.md' CLAUDE.md; then
  if [ -f AGENTS.md ] && grep -q 'MEMORY_ARCHITECTURE.md' AGENTS.md && [ "$(wc -l < AGENTS.md | tr -d ' ')" -gt 20 ]; then
    # AGENTS.md is already the canonical text (the sync fast-forwarded it): keep the old CLAUDE.md
    # body beside the tree, never lost, and point CLAUDE.md at AGENTS.md
    mkdir -p .bedrock-incoming; cp -p CLAUDE.md .bedrock-incoming/CLAUDE.md.previous
    echo "migration 0004: AGENTS.md is already canonical; the previous CLAUDE.md body is kept at .bedrock-incoming/CLAUDE.md.previous"
  else
    cp -p CLAUDE.md AGENTS.md
  fi
  cat > CLAUDE.md <<'ADAPTER'
# CLAUDE.md — Claude Code adapter

@AGENTS.md

This file exists only because Claude Code auto-reads it. The complete, harness-neutral
instructions are in [`AGENTS.md`](AGENTS.md): read that file and follow it exactly. Nothing
here overrides it, and a project that does not use Claude Code may delete this file.
ADAPTER
  grep -q 'MEMORY_ARCHITECTURE.md' AGENTS.md || printf '\nRead `MEMORY_ARCHITECTURE.md` and `README.md` first.\n' >> AGENTS.md
  echo "migration 0004: the instruction body moved from CLAUDE.md to AGENTS.md; CLAUDE.md is now the adapter"
else
  echo "migration 0004: nothing to do"
fi
