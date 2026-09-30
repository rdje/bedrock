#!/usr/bin/env bash
# scripts/check_doctrines.sh — THE GENERAL DOCTRINE ENFORCER (driver + registry).
# SPDX-License-Identifier: LGPL-2.1-or-later
#
# Runs every mechanizable doctrine check as one registry over ONE change context, reports each
# verdict, and exits NONZERO on any breach OR any refusal. Called by .githooks/pre-commit and
# .githooks/commit-msg (fast local gate) and by CI, per introduced commit (the backstop a local
# --no-verify cannot dodge).
#
#   scripts/check_doctrines.sh                      judge the INDEX against HEAD (pre-commit)
#   scripts/check_doctrines.sh --message <file>     the same, with the commit message (commit-msg)
#   scripts/check_doctrines.sh --commit <rev>       judge one commit against its parent (CI)
#   scripts/check_doctrines.sh --range <a>..<b>     judge every commit the range introduces (CI)
#
# THE EXIT CONTRACT a check must honour (scripts/lib/spine.sh): 0 holds · 1 breach · 2 REFUSED.
# ⛔ A refusal FAILS THE RUN. A check that cannot evaluate — git failed, a dependency is missing,
#   a pattern is invalid — never reports the doctrine as holding. Measured before this driver
#   (BK-17, BR-05, BK-14): a git failure, a missing python3, an invalid regex and a lost executable
#   bit each produced a green run over a change that was never judged.
#
# Enforcement layering (defense in depth):
#   E1 discovery  : the doctrine docs (README, MEMORY_ARCHITECTURE, TOOLBOX, docs/decisions/).
#   E2 self-check : THIS script + each registered scripts/check_*.sh (single source of truth).
#   E3 git hook   : .githooks/pre-commit and .githooks/commit-msg call this.
#   E4 CI         : the same script runs in CI, per commit, so a bypassed local hook still fails.
#
# To add a PROJECT-SPECIFIC doctrine, append a check to scripts/check_doctrines.project.sh
# (the pluggable slot) — never edit this driver's universal registry.
set -uo pipefail   # deliberately NOT -e: run ALL checks, collect every result, then report.

SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
. "$(dirname "$SELF")/lib/spine.sh"

MSG_FILE=""; COMMIT=""; RANGE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --message) shift; MSG_FILE="${1:-}" ;;
    --commit)  shift; COMMIT="${1:-}" ;;
    --range)   shift; RANGE="${1:-}" ;;
    -h|--help) sed -n '2,16p' "$SELF" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) printf 'check_doctrines: unknown argument %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done

# ── --range: one run per introduced commit, oldest first; any failure fails the range ──────────
if [ -n "$RANGE" ]; then
  from="${RANGE%%..*}"; to="${RANGE##*..}"
  [ -n "$to" ] || { printf 'check_doctrines: --range needs <a>..<b>\n' >&2; exit 2; }
  case "$from" in ""|0000000000000000000000000000000000000000)
    printf '=== range has no known base (new branch or first push): judging the tip only ===\n'
    exec bash "$SELF" --commit "$to" ;;
  esac
  git rev-parse --verify -q "$from^{commit}" >/dev/null || { printf 'check_doctrines: REFUSED — %s is not a commit\n' "$from" >&2; exit 2; }
  shas="$(git rev-list --reverse "$from..$to" 2>/dev/null)" || { printf 'check_doctrines: REFUSED — git rev-list %s failed\n' "$RANGE" >&2; exit 2; }
  [ -n "$shas" ] || { printf '=== range %s introduces no commit ===\n' "$RANGE"; exit 0; }
  bad=0; n=0; exc=0
  for sha in $shas; do
    n=$((n+1)); printf '\n##### commit %s — %s\n' "$(git rev-parse --short "$sha")" "$(git log -1 --format=%s "$sha" | cut -c1-100)"
    if git log -1 --format=%B "$sha" | git interpret-trailers --parse 2>/dev/null | grep -qi '^Spine-Exception:'; then exc=$((exc+1)); fi
    bash "$SELF" --commit "$sha" || bad=$((bad+1))
  done
  printf '\n=== range %s: %d commit(s), %d failing, %d with a Spine-Exception ===\n' "$RANGE" "$n" "$bad" "$exc"
  [ "$bad" -eq 0 ]; exit
fi

# ── the change context ────────────────────────────────────────────────────────────────────────
if [ -n "$COMMIT" ]; then
  sha="$(git rev-parse --verify -q "$COMMIT^{commit}" 2>/dev/null)" || { printf 'check_doctrines: REFUSED — %s is not a commit\n' "$COMMIT" >&2; exit 2; }
  parents="$(git rev-list --parents -n 1 "$sha" | cut -d' ' -f2-)"
  set -- $parents
  case $# in
    0) export SPINE_BEFORE="$SPINE_EMPTY_TREE" ;;
    1) export SPINE_BEFORE="$1" ;;
    *) export SPINE_BEFORE="$1" SPINE_MERGE=1 ;;
  esac
  export SPINE_AFTER="$sha"
  COMMIT_SHA="$sha"
else
  export SPINE_AFTER=":"
  # a merge commit being made: git runs the commit-msg hook for it too; its parents were judged
  [ -f "$(git rev-parse --git-path MERGE_HEAD 2>/dev/null)" ] && export SPINE_MERGE=1
fi
spine_init DRIVER
if [ -n "$COMMIT" ]; then
  MSG_FILE="$(spine_tmp)/message"; git log -1 --format=%B "$COMMIT_SHA" > "$MSG_FILE" || { printf 'check_doctrines: REFUSED — cannot read the message of %s\n' "$COMMIT_SHA" >&2; exit 2; }
fi
[ -z "$MSG_FILE" ] || { [ -r "$MSG_FILE" ] || { printf 'check_doctrines: REFUSED — message file %s unreadable\n' "$MSG_FILE" >&2; exit 2; }; export SPINE_COMMIT_MSG="$MSG_FILE"; }

# Universal registry. Each entry: "ID|what it proves|relative/path/to/check.sh"
DOCTRINES=(
  "MEMORY-ARCH|durable 4-layer memory architecture invariants, and every spine document present (MEMORY_ARCHITECTURE.md)|scripts/check_memory_architecture.sh"
  "DOCPATH|changed .md files carry no checkout-specific absolute paths|scripts/check_docpaths.sh"
  "TASK-TREE-OWNERSHIP|every code change — added, modified, deleted or renamed — is owned by a task-tree leaf|scripts/check_task_tree_ownership.sh"
  "README-STABILITY|README.md stays a stable landing page — a line cap AND a byte cap (README_POLICY.md)|scripts/check_readme_stability.sh"
  "WAIVER-ROUTING|a task leaf saying a gate does not apply names the leaf that owns fixing it|scripts/check_waiver_routing.sh"
  "TASK-ACCEPTANCE|a code change is owned by a leaf whose ticked checklist carries tool output IN each box|scripts/check_task_acceptance.sh"
  "LIVE-DOC-CURRENCY|no tracked document reports its own currency (Last updated: …) — git carries it, a hand-kept date is false the day after|scripts/check_live_doc_currency.sh"
  "LESSON-PROMOTION|a new dated lesson in DEV_NOTES.md is PROMOTED to the retrievable layer (docs/knowledge or a decisions record gaining answers:) or EXPLICITLY DECLINED in its leaf — never silently dropped|scripts/check_lesson_promotion.sh"
  "ROUTING-EVIDENCE|a task leaf that routes a finding OUT to another tree records a ROUTING EVIDENCE section — what was measured, and whether the finding reproduces outside the family it is sent to|scripts/check_routing_evidence.sh"
  "GAP-CLAIM-CENSUS|a task leaf that ADDS a nothing-checks-X claim records the census it rests on, in the same section — such a sentence quantifies over the whole tree and is false the moment one reader exists|scripts/check_gap_claims.sh"
  "TABLE-ARITY-RATCHET|a changed markdown file may not RAISE the number of table rows whose cell count disagrees with their header — GFM silently drops the extra cells or pads the missing ones|scripts/check_table_arity.sh"
  "COMMIT-MESSAGE|the commit subject is id-shaped and the message carries no agent attribution trailer (evaluated wherever a message exists: commit-msg hook and CI)|scripts/check_commit_message.sh"
  "MANIFEST|.bedrock/manifest classifies every shipped path (spine / seed / project / maintainer) and every spine path it names exists — the updater's ground truth|scripts/check_manifest.sh"
  "NEUTRALITY|no spine logic names a language, a build or docs tool, or a harness — the neutrality contract as a gate (bedrock itself only)|scripts/check_neutrality.sh"
  "RESUME-POINTER|MEMORY.md is TRUE for this commit: latest_commit names it when the change is governed, the active tree exists, the frontier leaf exists and is open, next_action is set — a fresh agent in any harness resumes from the repository alone|scripts/check_resume_pointer.sh"
)
# Optional subsystems: registered when present. ⛔ "present" is the file, not its mode — every
# check is run through bash, so a lost executable bit (core.fileMode=false, a zip, an editor)
# cannot silently drop a check (BK-14).
[ -f "knowledge-map/scripts/check_knowledge_map.sh" ] && \
  DOCTRINES+=("KNOWLEDGE-MAP|the derived Knowledge Map is in sync with its sources|knowledge-map/scripts/check_knowledge_map.sh")
if [ -f "scripts/check_doctrines.project.sh" ]; then
  DOCTRINES+=("PROJECT-SPECIFIC|this project's own doctrine checks|scripts/check_doctrines.project.sh")
else
  printf '  -- %-22s skipped: no scripts/check_doctrines.project.sh\n' "PROJECT-SPECIFIC"
fi

fails=0; refusals=0; exceptions=0
ctx="index vs $(git rev-parse --short "$SPINE_BEFORE_SHA" 2>/dev/null || echo "$SPINE_BEFORE_SHA" | cut -c1-7)"
[ "$SPINE_AFTER_SHA" = ":" ] || ctx="$(git rev-parse --short "$SPINE_AFTER_SHA") vs $(git rev-parse --short "$SPINE_BEFORE_SHA" 2>/dev/null || echo empty-tree)${SPINE_MERGE:+ (merge)}"
printf '=== doctrine enforcement (%s checks; %s) ===\n' "${#DOCTRINES[@]}" "$ctx"
for entry in "${DOCTRINES[@]}"; do
  id="${entry%%|*}"; rest="${entry#*|}"; proves="${rest%%|*}"; path="${rest##*|}"
  if [ ! -f "$path" ]; then
    printf '  ⛔ REFUSED  %-22s (registered check is missing: %s)\n' "$id" "$path"; refusals=$((refusals+1)); continue
  fi
  out="$(SPINE_ID="$id" bash "$path" 2>&1)"; rc=$?
  case "$rc" in
    0) case "$out" in
         *"NOT EVALUATED"*) printf '  ⏸  %-22s not evaluated here: %s\n' "$id" "$(printf '%s' "$out" | sed -n 's/^[^:]*: NOT EVALUATED — //p' | head -1)" ;;
         *"EXCEPTION"*)     printf '  ⚠️  %-22s EXCEPTION — %s\n' "$id" "$(printf '%s' "$out" | sed -n 's/^[^:]*: EXCEPTION — //p' | head -1)"; exceptions=$((exceptions+1)) ;;
         *)                 printf '  ✅ %-22s %s\n' "$id" "$proves" ;;
       esac ;;
    1) printf '  ❌ %-22s %s\n' "$id" "$proves"; printf '%s\n' "$out" | sed 's/^/       /'; fails=$((fails+1)) ;;
    *) printf '  ⛔ REFUSED  %-22s cannot evaluate (exit %s) — an error is not a pass\n' "$id" "$rc"; printf '%s\n' "$out" | sed 's/^/       /'; refusals=$((refusals+1)) ;;
  esac
done

if [ "$fails" -ne 0 ] || [ "$refusals" -ne 0 ]; then
  printf '=== %d doctrine breach(es), %d refusal(s) — commit blocked ===\n' "$fails" "$refusals" >&2
  exit 1
fi
if [ "$exceptions" -gt 0 ]; then printf '=== all doctrines green — with %d recorded exception(s) ===\n' "$exceptions"; else printf '=== all doctrines green ===\n'; fi
exit 0
