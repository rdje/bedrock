#!/usr/bin/env bash
# scripts/update_scaffold.sh — pull the latest project-NEUTRAL spine from the bedrock
# template into THIS project, WITHOUT touching your roadmap, task-trees, decisions, or code.
#
#   scripts/update_scaffold.sh <bedrock-repo-url-or-local-path>
#
# Two categories: NEUTRAL is re-synced (overwritten) because it never carries project
# content; SEED_ONCE is copied only when ABSENT, because it carries a decision the
# project owns and must reach a project that predates it without reverting it.
# Everything else project-owned
# (CLAUDE.md, README.md, ROADMAP.md, the live-docs, the project doctrine slot, the curated
# subsystems.md, and all of docs/tasks/ + docs/decisions/ records) is deliberately left
# alone. After syncing: review `git diff`, run `make gate`, and commit.
set -euo pipefail
URL="${1:-}"
[ -n "$URL" ] || { echo "usage: scripts/update_scaffold.sh <bedrock-repo-url-or-local-path>" >&2; exit 2; }
ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
if [ -d "$URL/.git" ]; then
  cp -R "$URL" "$tmp/bedrock"
else
  git clone --depth 1 "$URL" "$tmp/bedrock" >/dev/null 2>&1 || { echo "clone failed: $URL" >&2; exit 1; }
fi

# The project-NEUTRAL spine — safe to overwrite because it never carries project content.
NEUTRAL=(
  MEMORY_ARCHITECTURE.md
  DOCTRINE_ENFORCEMENT.md
  TOOLBOX.md
  README_POLICY.md
  COMMIT.md
  AGENTS.md
  docs/TASK_TREE.md
  docs/TASK_TREE_README.md
  docs/tasks/TEMPLATE.md
  docs/decisions/TEMPLATE.md
  .githooks/pre-commit
  .githooks/commit-msg
  scripts/check_doctrines.sh
  scripts/check_memory_architecture.sh
  scripts/check_live_doc_currency.sh
  scripts/check_no_background_jobs.sh
  scripts/check_lesson_promotion.sh
  scripts/check_routing_evidence.sh
  scripts/check_gap_claims.sh
  scripts/check_table_arity.sh
  scripts/check_readme_stability.sh
  scripts/check_waiver_routing.sh
  scripts/check_task_acceptance.sh
  .doctrine/README.md
  scripts/check_docpaths.sh
  scripts/check_task_tree_ownership.sh
  knowledge-map/scripts/gen_knowledge_map.sh
  knowledge-map/scripts/check_knowledge_map.sh
  DOCTRINE_VERSION
)

# ⛔ SEEDED ONCE, NEVER OVERWRITTEN — a spine file that carries a PROJECT DECISION.
#
# `NEUTRAL` above is blind-overwrite, which is correct for a file that never holds project
# content. A file that a project is MEANT to edit cannot be in it: re-syncing would silently
# revert that project's decision, and the more deliberate the decision, the worse the loss.
#
# But such a file still has to REACH a project that predates it, or a new spine rule lands
# only in projects created afterwards — which is exactly the gap this category was added to
# close (`BEDROCK-MAINTENANCE.2.9` follow-up): `VISIBILITY.md` carries a declared posture a
# project may change, so it is copied when ABSENT and left alone when present.
SEED_ONCE=(
  VISIBILITY.md
)

n=0
s=0
for f in "${SEED_ONCE[@]}"; do
  if [ -f "$tmp/bedrock/$f" ] && [ ! -f "$f" ]; then
    mkdir -p "$(dirname "$f")"
    cp "$tmp/bedrock/$f" "$f"
    echo "  seeded $f (new — review it; it carries a decision this project owns)"
    s=$((s+1))
  elif [ -f "$f" ]; then
    echo "  kept   $f (already present — a project decision is never overwritten)"
  fi
done

for f in "${NEUTRAL[@]}"; do
  if [ -f "$tmp/bedrock/$f" ]; then
    mkdir -p "$(dirname "$f")"
    cp "$tmp/bedrock/$f" "$f"
    echo "  synced $f"
    n=$((n+1))
  fi
done
chmod +x scripts/*.sh knowledge-map/scripts/*.sh .githooks/pre-commit .githooks/commit-msg 2>/dev/null || true

echo "✓ $n scaffold file(s) synced, $s seeded, to $(cat DOCTRINE_VERSION 2>/dev/null || echo '?')."
echo "  Review 'git diff', run 'make gate', then commit."
