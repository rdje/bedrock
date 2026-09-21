#!/usr/bin/env bash
# scripts/update_scaffold.sh — pull the latest project-NEUTRAL spine from the bedrock
# template into THIS project, WITHOUT touching your roadmap, task-trees, decisions, or code.
#
#   scripts/update_scaffold.sh <bedrock-repo-url-or-local-path>
#
# ⛔⛔ THIS TOOL NEVER OVERWRITES. It used to, and that was wrong — measured, not feared.
#
# The premise was that the files below "never carry project content". Across the three
# projects created from this template, that premise is FALSE for most of them:
# `docs/TASK_TREE.md` diverges by 20-30 lines (it indexes the project's OWN trees),
# `TOOLBOX.md` by 27-616, `check_task_acceptance.sh` by up to 447, `check_readme_stability.sh`
# by 217. A "pull the latest spine" run silently replaced a mature project's hardened checks
# with the template's simpler ones, and `make gate` PASSED afterwards — because template
# files satisfy template checks, so the advertised safety net cannot see this class at all.
#
# It happened: 2026-09-21, a run in one project wiped its task-tree index (11 registered
# trees), its four own doctrine rows, its tool registry and its tiered commit workflow. It was
# recoverable only because nothing had been committed yet.
#
# ⭐ AND THE IMPROVEMENT OFTEN FLOWS THE OTHER WAY. `MAINTAINING.md` records that transfer
# runs BOTH ways: a mature project hardens a check and sends it back here. Overwriting that
# project from here is backwards.
#
# So: identical → nothing. Absent → seeded. Different → the incoming version is written
# into `.bedrock-incoming/<path>` and reported, and you merge deliberately. Nothing you have
# is ever modified, renamed or deleted.
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

# ⛔ Refuse on a dirty tree. Recovery from any surprise is `git checkout -- <file>`, and
# that is only simple when the tree was clean to begin with. `--force` is available for
# someone who has read this and wants it anyway.
if [ "${2:-}" != "--force" ] && [ -n "$(git status --porcelain)" ]; then
  echo "REFUSED: the working tree is dirty." >&2
  echo "  This tool writes files. Commit or stash first, so that reviewing what it did is a" >&2
  echo "  clean 'git diff' and undoing it is 'git checkout -- <file>'." >&2
  echo "  Deliberate override: scripts/update_scaffold.sh <url> --force" >&2
  exit 2
fi

n=0; s=0; d=0
apply_one() { # $1 = path, $2 = "seed-only" | "offer"
  local f="$1" mode="$2" src="$tmp/bedrock/$1"
  [ -f "$src" ] || return 0
  if [ ! -f "$f" ]; then
    mkdir -p "$(dirname "$f")"
    cp "$src" "$f"
    echo "  seeded   $f (new)"
    s=$((s+1))
    return 0
  fi
  if cmp -s "$src" "$f"; then
    n=$((n+1))
    return 0
  fi
  if [ "$mode" = "seed-only" ]; then
    echo "  kept     $f (yours — it carries a decision this project owns)"
    return 0
  fi
  # ⛔ The incoming copy goes into ONE directory, never beside the original. A
  #    `<file>.bedrock-new` sitting next to `<file>` is one `git add -A` away from being
  #    committed as if it were project content, and one careless glance away from being
  #    mistaken for the real file. `.bedrock-incoming/` is a single thing to read and a
  #    single thing to delete, and it is obvious in `git status`.
  mkdir -p ".bedrock-incoming/$(dirname "$f")"
  cp "$src" ".bedrock-incoming/$f"
  echo "  DIFFERS  $f — yours is UNTOUCHED; theirs is .bedrock-incoming/$f"
  d=$((d+1))
}

for f in "${SEED_ONCE[@]}"; do apply_one "$f" "seed-only"; done
for f in "${NEUTRAL[@]}"; do apply_one "$f" "offer"; done
chmod +x scripts/*.sh knowledge-map/scripts/*.sh .githooks/pre-commit .githooks/commit-msg 2>/dev/null || true

echo "✓ $n already current, $s seeded, $d differ — nothing of yours was modified."
if [ "$d" -gt 0 ]; then
  echo "  ⚠️  NOTHING of yours was touched. The template's versions are in .bedrock-incoming/."
  echo "      Review them, take only what you want, then:  rm -rf .bedrock-incoming"
  echo "        diff -ru . .bedrock-incoming 2>/dev/null | less     # or file by file"
  echo "      Improvement often flows project -> bedrock, so the template's version is NOT"
  echo "      automatically the better one (MAINTAINING.md: transfer runs both ways)."
fi
echo "  Review 'git status', run 'make gate', then commit."
