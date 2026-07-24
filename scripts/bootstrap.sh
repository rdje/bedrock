#!/usr/bin/env bash
# scripts/bootstrap.sh — first-time setup for a project scaffolded from bedrock.
#
#   scripts/bootstrap.sh [project-name]
#
# With a project-name it DE-TEMPLATES this copy into a fresh project: removes bedrock's own
# maintainer files (MAINTAINING.md + the BEDROCK-MAINTENANCE tree + the provenance record)
# and resets the layer-A/C seeds, then installs hooks, sets the name, generates the Knowledge
# Map, and verifies the enforcer. Without a name it just installs hooks + regenerates the map
# (safe to run in the bedrock source repo itself — it will NOT remove the maintainer files).
#
# Idempotent. It does NOT invent a task-tree from your roadmap — that judgment is left to you.
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
name="${1:-}"

# 0) de-template (only when a project name is given AND this is still a pristine bedrock copy)
if [ -n "$name" ] && [ -f MAINTAINING.md ]; then
  echo "→ de-templating this bedrock copy into project '$name'…"
  rm -f MAINTAINING.md docs/tasks/BEDROCK-MAINTENANCE.md docs/decisions/reference_bedrock_provenance.md

  cat > MEMORY.md <<SEED
# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~50 lines)

> The bounded layer-A resume pointer (see \`MEMORY_ARCHITECTURE.md\`). OVERWRITE the
> "Current state" block each update — never append history here.

## How to resume

1. Read \`README.md\`, \`MEMORY_ARCHITECTURE.md\`, \`TOOLBOX.md\`, \`DOCTRINE_ENFORCEMENT.md\`.
2. Open the active task-tree below → its Current Frontier → continue from the next action.

## Current state

- **Project:** $name — fresh from the bedrock template.
- **Active tree:** _none yet_
- **Next action:** replace \`ROADMAP.md\`; create your first task-tree
  (\`cp docs/tasks/TEMPLATE.md docs/tasks/<TREE-ID>.md\`), register it in \`docs/TASK_TREE.md\`.
- **Latest commit:** _none yet_
- **In-flight uncommitted work:** none.
SEED

  cat > docs/decisions/INDEX.md <<'SEED'
# Decision & Fact Records — Index (memory layer C)

Durable, cross-cutting facts and decisions live here, one record per file (ADR-style). Every
record must be listed below (the MEMORY-ARCH doctrine check enforces it). New record: copy
`TEMPLATE.md` → `<type>_<short-kebab-slug>.md`, fill it in, and add its row.

| Record | Type | One-line hook |
| --- | --- | --- |
| _none yet_ | | |
SEED

  # reset the Active Task Trees section (the workflow doc above it is preserved)
  sed -i '/^## Active Task Trees/,$d' docs/TASK_TREE.md
  cat >> docs/TASK_TREE.md <<'SEED'
## Active Task Trees

| Tree | Status | Frontier (next leaf) | Owner |
| --- | --- | --- | --- |
| _none yet — seed your first tree from `ROADMAP.md`_ | | | |
SEED

  # strip the maintainer-only notes (bounded by BEDROCK-MAINTAINER-NOTE markers)
  for f in CLAUDE.md ROADMAP.md; do
    [ -f "$f" ] && sed -i '/BEDROCK-MAINTAINER-NOTE:START/,/BEDROCK-MAINTAINER-NOTE:END/d' "$f"
  done
  echo "✓ de-templated (maintainer files removed; layer-A/C + tree index reset)"
fi

# 1) activate the git hooks (E3 enforcement)
git config core.hooksPath .githooks
echo "✓ git hooks activated (core.hooksPath=.githooks)"

# 2) make the spine scripts executable
chmod +x scripts/*.sh knowledge-map/scripts/*.sh .githooks/pre-commit .githooks/commit-msg 2>/dev/null || true
echo "✓ scripts marked executable"

# 3) set the project name (crate + roadmap title)
if [ -n "$name" ]; then
  [ -f crates/app/Cargo.toml ] && sed -i "s/^name = \"app\"/name = \"$name\"/" crates/app/Cargo.toml || true
  [ -f ROADMAP.md ] && sed -i "s/# ROADMAP — _(PROJECT NAME)_/# ROADMAP — $name/" ROADMAP.md || true
  echo "✓ project name set to '$name'"
fi

# 4) generate the derived Knowledge Map (after de-templating, so it reflects the reset)
if [ -x knowledge-map/scripts/gen_knowledge_map.sh ]; then
  knowledge-map/scripts/gen_knowledge_map.sh > "$(knowledge-map/scripts/gen_knowledge_map.sh --print-map-path)"
  echo "✓ KNOWLEDGE_MAP.md generated"
fi

# 5) sanity: run the enforcer
echo "→ running the doctrine enforcer…"
scripts/check_doctrines.sh || { echo "enforcer reported a breach — fix it before your first commit"; exit 1; }

cat <<'EOF'

bedrock is ready.

Next:
  1) Replace ROADMAP.md with your project's real roadmap.
  2) Create your first task-tree:
       cp docs/tasks/TEMPLATE.md docs/tasks/<TREE-ID>.md    # then fill it in
       (register it in docs/TASK_TREE.md's Active Task Trees table)
  3) Work its first leaf, then commit via COMMIT.md.

Re-run the spine check anytime with:  make gate
EOF
