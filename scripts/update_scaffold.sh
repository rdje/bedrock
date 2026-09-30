#!/usr/bin/env bash
# scripts/update_scaffold.sh — pull the latest spine from bedrock into THIS project, by ownership class.
# SPDX-License-Identifier: LGPL-2.1-or-later
#
#   scripts/update_scaffold.sh <bedrock-repo-url-or-local-path> [--ref <tag|sha|branch>] [--plan]
#                              [--merge] [--force] [--no-self-replace]
#
# THE RULES (docs/decisions/decision_updater_ownership_classes.md):
#   • The file list is the MANIFEST OF THE SOURCE (`.bedrock/manifest`), never this copy's (BK-09). A
#     child created from 0.4.0 used to upgrade with 0.4.0's list and land a half-installed spine.
#   • STEP 0: this script replaces ITSELF from the source and re-executes, so the code that upgrades
#     is the source's, whatever version the child was created from (BK-09).
#   • By class:  spine — identical → nothing; absent → seeded; different and byte-identical to the
#                template version this project last synced from → FAST-FORWARDED (it was never touched);
#                different otherwise → `.bedrock-incoming/<path>`, NEVER overwritten (`--merge` offers a
#                three-way merge into a side file).   seed — seeded when absent, never touched.
#                project — never touched.   maintainer — bedrock-only, never shipped.
#   • MIGRATIONS (`migrations/NNNN-<slug>.sh`, `# since: <version>`) repair what an older template
#     created, run in order for every version newer than this project's recorded one (BK-10).
#   • `DOCTRINE_VERSION` is written ONLY after every check the fetched driver registers exists and the
#     gate passes over the staged upgrade (BK-09). An `UPDATE-<version>` leaf with measured evidence owns
#     the upgrade commit, and the exact commit command is printed (BK-10).
#   • The source is resolved from a pinned `--ref` (or the source's HEAD, whose sha is recorded), and
#     EXPORTED with `git archive` — no `.git`, no build output (BR-09). This script acts on the
#     repository it LIVES IN, never on the caller's directory (BR-09).
#   • A dirty tree is REFUSED (`--force` skips that check only): uncommitted content survives nothing.
#   • The three bookkeeping edits the upgrade commit needs are additive, minimal and printed: the
#     `UPDATE-<version>` row in docs/TASK_TREE.md, and MEMORY.md's `latest_commit` (plus a stale
#     `active_work_unit` / placeholder `next_action`, so the RESUME-POINTER gate can pass).
# ⛔ PORTABILITY: bash 3.2, POSIX awk/sed/grep, git ≥ 2.x. No `sed -i`.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" || exit 2
cd "$ROOT" || exit 2
die() { printf 'update: %s\n' "$*" >&2; exit 2; }
ORIG_ARGS=("$@")
SRC=""; REF=""; PLAN=0; MERGE=0; FORCE=0; NOSELF=0
while [ $# -gt 0 ]; do
  case "$1" in
    --ref) shift; REF="${1:-}" ;;
    --plan) PLAN=1 ;;
    --merge) MERGE=1 ;;
    --force) FORCE=1 ;;
    --no-self-replace) NOSELF=1 ;;
    -h|--help) sed -n '2,30p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) die "unknown option $1" ;;
    *) [ -z "$SRC" ] || die "one source only"; SRC="$1" ;;
  esac
  shift
done
[ -n "$SRC" ] || { sed -n '4,6p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2; exit 2; }

# ── preflight ────────────────────────────────────────────────────────────────────────────────
for t in git awk sed grep cmp tar; do command -v "$t" >/dev/null 2>&1 || die "required tool missing: $t"; done
git rev-parse --git-dir >/dev/null 2>&1 || die "$ROOT is not a git repository"
if [ "$FORCE" != 1 ] && [ -n "$(git status --porcelain --untracked-files=all)" ]; then
  { echo "update: REFUSED — the working tree is not clean. Commit or stash first."
    echo "  Committed content is always recoverable; UNCOMMITTED content is recoverable by nothing. This tool"
    echo "  writes files, so it declines to meet your uncommitted work. (--force skips THIS check only.)"; } >&2
  exit 2
fi
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# ── fetch: a full clone (the merge base needs history), then EXPORT the pinned commit ──────
if [ -d "$SRC/.git" ] || [ -f "$SRC/.git" ]; then SRC_GIT="$SRC"
else git clone -q "$SRC" "$tmp/src" 2>"$tmp/clone.err" || die "clone failed: $SRC ($(head -1 "$tmp/clone.err"))"; SRC_GIT="$tmp/src"; fi
sha="$(git -C "$SRC_GIT" rev-parse --verify -q "${REF:-HEAD}^{commit}")" || die "ref '${REF:-HEAD}' does not resolve in $SRC"
mkdir -p "$tmp/bedrock" && git -C "$SRC_GIT" archive "$sha" | tar -x -C "$tmp/bedrock" || die "export of $sha failed"
B="$tmp/bedrock"
[ -f "$B/.bedrock/manifest" ] || die "the source at $sha ships no .bedrock/manifest — it is older than this updater; pass --ref of a newer commit"
new_version="$(cat "$B/DOCTRINE_VERSION" 2>/dev/null)"; new_v="${new_version##* }"
old_version="$(cat DOCTRINE_VERSION 2>/dev/null || echo 'bedrock-scaffold 0.0.0')"; old_v="${old_version##* }"
ver_ge() { awk -v a="$1" -v b="$2" 'BEGIN{ n=split(a,x,"."); m=split(b,y,"."); for(i=1;i<=3;i++){ p=x[i]+0; q=y[i]+0; if(p>q) exit 0; if(p<q) exit 1 } exit 0 }'; }
ver_ge "$new_v" "$old_v" || { [ "$FORCE" = 1 ] || die "the source ($new_version at $(git -C "$SRC_GIT" rev-parse --short "$sha")) is OLDER than this project ($old_version): a downgrade is refused (--force to insist)"; }

# ── step 0: replace this script from the source, then re-execute ───────────────────────────
if [ "$NOSELF" != 1 ] && [ "$PLAN" != 1 ] && ! cmp -s "$B/scripts/update_scaffold.sh" scripts/update_scaffold.sh; then
  mkdir -p .bedrock-incoming/scripts
  cp -p scripts/update_scaffold.sh .bedrock-incoming/scripts/update_scaffold.sh.previous
  cp "$B/scripts/update_scaffold.sh" scripts/update_scaffold.sh && chmod +x scripts/update_scaffold.sh
  echo "update: step 0 — replaced scripts/update_scaffold.sh with the source's (yours is kept at .bedrock-incoming/scripts/update_scaffold.sh.previous); re-executing"
  # --force: the clean-tree and version checks passed above; the tree is dirty now only by this replacement
  exec bash scripts/update_scaffold.sh "${ORIG_ARGS[@]}" --no-self-replace --force
fi

# ── the merge base: EVERY commit that carried the version this project last synced from ──────
# A version spans several commits when a follow-up lands without a bump, so "unmodified" means
# identical to the file at ANY of them; the FIRST such commit is the three-way merge base.
base_rev="$(git -C "$SRC_GIT" log --format=%H -S"$old_version" -- DOCTRINE_VERSION 2>/dev/null | tail -1)"
removal="$(git -C "$SRC_GIT" log --format=%H -S"$old_version" -- DOCTRINE_VERSION 2>/dev/null | head -1)"
if [ -n "$base_rev" ]; then
  if [ "$removal" = "$base_rev" ]; then BASE_CANDS="$(git -C "$SRC_GIT" rev-list "$sha" --not "$base_rev^" 2>/dev/null)"
  else BASE_CANDS="$(git -C "$SRC_GIT" rev-list "$removal^" --not "$base_rev^" 2>/dev/null)"; fi
else BASE_CANDS=""; fi
base_of() { [ -n "$base_rev" ] && git -C "$SRC_GIT" show "$base_rev:$1" 2>/dev/null; }
# A child has bedrock's maintainer note stripped at bootstrap: compare what WOULD be written, not the raw source.
norm() { # $1 = a file, $2 = the path it stands for: Markdown loses the maintainer note in a child; scripts mention the marker in code and are compared raw
  case "${2:-$1}" in *.md) [ -f MAINTAINING.md ] && { cat "$1"; return; }; awk '{ if (!d && index($0,"BEDROCK-MAINTAINER-NOTE:START")) d=1; if (!d) print; else if (index($0,"BEDROCK-MAINTAINER-NOTE:END")) d=0 }' "$1" ;;
                       *) cat "$1" ;; esac; }
unmodified() { # $1 = path → 0 if the project's file equals that path at any commit carrying $old_version
  local c
  for c in $BASE_CANDS; do
    git -C "$SRC_GIT" show "$c:$1" > "$tmp/cand" 2>/dev/null || continue
    norm "$tmp/cand" "$1" > "$tmp/candn"; cmp -s "$tmp/candn" "$1" && return 0
  done
  return 1
}

# ── classify and act ─────────────────────────────────────────────────────────────────────────
n_cur=0; n_seed=0; n_ff=0; n_diff=0; n_merge=0
SEEDED=""; FF=""; DIFFER=""
strip_maintainer_note() { # a spine MARKDOWN file that carries bedrock's maintainer note loses it in a child
  [ -f MAINTAINING.md ] && return 0
  case "$1" in *.md) ;; *) return 0 ;; esac
  grep -q 'BEDROCK-MAINTAINER-NOTE:START' "$1" || return 0
  local t="$1.update.$$"; cp -p "$1" "$t"
  awk '{ if (!d && index($0,"BEDROCK-MAINTAINER-NOTE:START")) d=1; if (!d) print; else if (index($0,"BEDROCK-MAINTAINER-NOTE:END")) d=0 }' "$1" > "$t" && mv "$t" "$1"
}
offer_merge() {
  local f="$1" theirs="$2" bt ot rc reply
  [ -n "$base_rev" ] || { echo "           no common ancestor resolvable (recorded version: $old_version) — compare instead:  diff $f .bedrock-incoming/$f"; return 0; }
  printf '           merge theirs into a COPY of yours, 3-way from %s? [y/N] ' "$(git -C "$SRC_GIT" rev-parse --short "$base_rev")"
  read -r reply </dev/tty 2>/dev/null || reply=""
  case "$reply" in [yY]*) ;; *) echo "           skipped — nothing written"; return 0 ;; esac
  bt="$tmp/base.$$"; ot="$tmp/ours.$$"
  base_of "$f" > "$bt" || { echo "           $f did not exist at the base — no merge; compare instead."; return 0; }
  cp "$f" "$ot"; git merge-file -p --diff3 "$ot" "$bt" "$theirs" > ".bedrock-incoming/$f.merged"; rc=$?
  if [ "$rc" -eq 0 ]; then echo "           ✓ merged cleanly → .bedrock-incoming/$f.merged (yours is still untouched)"
  else echo "           ⚠ merged with $rc conflict(s) → .bedrock-incoming/$f.merged — resolve the <<<<<<< markers there. Yours is untouched."; fi
  echo "             Take it only after reading it:  cp .bedrock-incoming/$f.merged $f"; n_merge=$((n_merge+1))
}
apply_spine() { # $1 = path (file) — relative
  local f="$1" src="$B/$1"
  [ -f "$src" ] || return 0
  [ "$f" = "DOCTRINE_VERSION" ] && return 0          # written last, only after the gate passes
  [ "$f" = "scripts/update_scaffold.sh" ] && return 0 # the running script: replaced in step 0 only, never here
  if [ ! -f "$f" ]; then
    [ "$PLAN" = 1 ] && { echo "  would seed     $f"; n_seed=$((n_seed+1)); return 0; }
    mkdir -p "$(dirname "$f")"; cp "$src" "$f"; strip_maintainer_note "$f"
    case "$f" in *.sh|.githooks/*|scripts/evidence|scripts/handoff|migrations/*) chmod +x "$f" ;; esac
    SEEDED="$SEEDED $f"; n_seed=$((n_seed+1)); echo "  seeded         $f"; return 0
  fi
  norm "$src" "$f" > "$tmp/srcn"; cmp -s "$tmp/srcn" "$f" && { n_cur=$((n_cur+1)); return 0; }
  if unmodified "$f"; then
    [ "$PLAN" = 1 ] && { echo "  would update   $f (unmodified since $old_version)"; n_ff=$((n_ff+1)); return 0; }
    cp -p "$f" "$tmp/keep.mode"; cp "$src" "$f"; strip_maintainer_note "$f"
    FF="$FF $f"; n_ff=$((n_ff+1)); echo "  updated        $f (yours was the unmodified $old_version version)"; return 0
  fi
  [ "$PLAN" = 1 ] && { echo "  would differ   $f (modified here; theirs would go to .bedrock-incoming/)"; n_diff=$((n_diff+1)); return 0; }
  mkdir -p ".bedrock-incoming/$(dirname "$f")"; cp "$src" ".bedrock-incoming/$f"
  DIFFER="$DIFFER $f"; n_diff=$((n_diff+1)); echo "  DIFFERS        $f — yours is UNTOUCHED; theirs is .bedrock-incoming/$f"
  [ "$MERGE" = 1 ] && offer_merge "$f" "$src"
  return 0
}
apply_seed() {
  local f="$1" src="$B/$1"
  [ -f "$src" ] || return 0
  if [ ! -f "$f" ]; then
    [ "$PLAN" = 1 ] && { echo "  would seed     $f"; n_seed=$((n_seed+1)); return 0; }
    mkdir -p "$(dirname "$f")"; cp "$src" "$f"; strip_maintainer_note "$f"
    SEEDED="$SEEDED $f"; n_seed=$((n_seed+1)); echo "  seeded         $f (yours to edit from now on)"
  fi
}
echo "update: $old_version → $new_version (source $(git -C "$SRC_GIT" rev-parse --short "$sha"), base $( [ -n "$base_rev" ] && git -C "$SRC_GIT" rev-parse --short "$base_rev" || echo unresolved))$( [ "$PLAN" = 1 ] && echo ' — PLAN ONLY, nothing written')"
grep -vE '^[[:space:]]*(#|$)' "$B/.bedrock/manifest" | while read -r path cls _; do
  case "$cls" in
    spine|seed) ;;
    *) continue ;;
  esac
  case "$path" in
    */) ( cd "$B" && find "$path" -type f ) | sort | while read -r f; do [ "$cls" = spine ] && apply_spine "$f" || apply_seed "$f"; done ;;
    *)  [ "$cls" = spine ] && apply_spine "$path" || apply_seed "$path" ;;
  esac
done > "$tmp/actions.log"
cat "$tmp/actions.log"
# counters were incremented in a subshell (the pipeline): recount from the log
n_seed="$(grep -c '^  \(seeded\|would seed\)' "$tmp/actions.log" || true)"; n_ff="$(grep -c '^  \(updated\|would update\)' "$tmp/actions.log" || true)"
n_diff="$(grep -c '^  \(DIFFERS\|would differ\)' "$tmp/actions.log" || true)"
n_total="$(grep -vE '^[[:space:]]*(#|$)' "$B/.bedrock/manifest" | awk '$2=="spine"||$2=="seed"' | wc -l | tr -d ' ')"

if [ "$PLAN" = 1 ]; then
  echo "update: PLAN — $n_seed to seed, $n_ff to update (unmodified), $n_diff differ (would go to .bedrock-incoming/); migrations newer than $old_v:"
  for m in "$B"/migrations/[0-9]*.sh; do [ -f "$m" ] || continue; since="$(sed -n 's/^# since: *//p' "$m" | head -1)"; ver_ge "$old_v" "$since" || echo "  would run      $(basename "$m") (since $since)"; done
  echo "update: nothing written (--plan)"; exit 0
fi

# ── migrations, oldest first, for every version newer than the project's ────────────────────
MIGRATED=""
for m in "$B"/migrations/[0-9]*.sh; do
  [ -f "$m" ] || continue
  since="$(sed -n 's/^# since: *//p' "$m" | head -1)"
  ver_ge "$old_v" "${since:-0.0.0}" && continue
  out="$(bash "$m" "$new_version" 2>&1)"; rc=$?
  printf '%s\n' "$out" | sed 's/^/  /'
  [ "$rc" -eq 0 ] || die "$(basename "$m") failed (rc=$rc); nothing is committed — inspect, fix, re-run"
  MIGRATED="$MIGRATED $(basename "$m" .sh)"
done
n_mig="$(printf '%s' "$MIGRATED" | wc -w | tr -d ' ')"

# ── every check the fetched driver registers must exist and parse ───────────────────────────
missing=""; n_checks=0
for c in $(grep -E '^  "[A-Z-]+\|' "$B/scripts/check_doctrines.sh" | sed 's/.*|//; s/"$//' | sort -u); do
  n_checks=$((n_checks+1)); [ -f "$c" ] && bash -n "$c" 2>/dev/null || missing="$missing $c"
done
[ -z "$missing" ] || die "registered check(s) missing or unparsable after sync:$missing"

# ── bookkeeping for the upgrade commit: identity, the leaf, the index row, the pointer ──────
prefix="$(sed -n 's/^prefix = //p' .bedrock/project 2>/dev/null | head -1)"; [ -n "$prefix" ] || prefix="PROJECT"
vtag="$(printf '%s' "$new_v" | tr '.' '-')"; tree="UPDATE-$vtag"
wu="$prefix-SPINE-$(printf '%s' "$new_v" | awk -F. '{ printf "%d%02d%02d", $1, $2, $3 }')"
subject="$wu (leaf $tree.1): spine updated to $new_version"
today="$(date +%F)"
n_seed_s="$(printf '%s' "$SEEDED" | wc -w | tr -d ' ')"; n_ff_s="$(printf '%s' "$FF" | wc -w | tr -d ' ')"
# (the per-file arrays were built in a subshell; the counts from the log are authoritative)
cat > "docs/tasks/$tree.md" <<LEAF
# $tree: spine updated to $new_version

## Metadata

- Tree ID: \`$tree\`
- Status: \`done\`
- Roadmap lane: project setup
- Created: \`$today\`
- Owner: repo-local workflow

## Goal

Record the update of this project's discipline spine from \`$old_version\` to \`$new_version\` (source
commit \`$(git -C "$SRC_GIT" rev-parse --short "$sha")\`), performed by \`scripts/update_scaffold.sh\` by ownership class, with the
evidence that run measured, so the upgrade commit passes the project's own gates.

## Task Tree

- ID: \`$tree.1\`
  Status: \`done\`
  Goal: sync the spine by manifest class, run the migrations, verify the registered checks, judge the staged upgrade.

  ### Acceptance Checklist (enforced by \`TASK-ACCEPTANCE\`)

  - [x] **ROOT CAUSE (WHY + WHERE)** — \`cat DOCTRINE_VERSION\` → \`$old_version\` before this run (\`rc=0\`); the
    source at \`$(git -C "$SRC_GIT" rev-parse --short "$sha")\` is \`$new_version\`, and its manifest lists $n_total spine/seed paths of which
    $n_seed were absent here and $n_ff carried this project's unmodified \`$old_v\` version; $n_diff differ and were NOT
    touched (theirs in \`.bedrock-incoming/\`).
  - [x] **ADDRESSED (verified)** — \`scripts/update_scaffold.sh\` → \`$n_seed seeded, $n_ff updated, $n_diff differ, $n_mig migration(s)\`
    (\`rc=0\`); migrations run:${MIGRATED:- none}; the enforcer over the STAGED index with this commit's subject: __GATE__
  - [x] **NO REGRESSION** — every check the fetched driver registers exists and parses: \`$n_checks/$n_checks\` (\`rc=0\`);
    nothing this project modified was overwritten ($n_diff file(s) reported as DIFFERS, theirs beside them); the same
    enforcer is the commit hook, so the upgrade commit is judged again exactly as measured here.

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| — | \`$tree.1\` | \`done\` | the upgrade itself; review \`.bedrock-incoming/\` if any file differs, then continue your roadmap |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| \`$tree.1\` | \`$subject\` | source $(git -C "$SRC_GIT" rev-parse --short "$sha") |
LEAF
# the index row (additive, after the last row of the Active Task Trees table)
if [ -f docs/TASK_TREE.md ] && ! grep -q "tasks/$tree.md" docs/TASK_TREE.md; then
  t="docs/TASK_TREE.md.update.$$"; cp -p docs/TASK_TREE.md "$t"
  awk -v row="| [\`$tree\`](tasks/$tree.md) | \`done\` | \`.1\` — spine updated to $new_version | repo-local |" '
    /^## Active Task Trees/ { sec=1 }
    { if (sec && intable && $0 !~ /^\|/) { print row; intable=0; sec=0 } if (sec && $0 ~ /^\|/) intable=1; print }
    END { if (sec && intable) print row }' docs/TASK_TREE.md > "$t" && mv "$t" docs/TASK_TREE.md
  echo "  edited         docs/TASK_TREE.md (+1 row: $tree)"
fi
# the pointer (RESUME-POINTER must pass on the upgrade commit)
if [ -f MEMORY.md ]; then
  t="MEMORY.md.update.$$"; cp -p MEMORY.md "$t"
  awk -v id="$wu" -v tree="$tree" '
    /^- latest_commit:/ { print "- latest_commit: `" id "` — spine updated to the version in DOCTRINE_VERSION."; next }
    /^- next_action:/ && ($0 ~ /_none yet_|<[a-z]/) { print "- next_action: review the spine update (docs/tasks/" tree ".md and .bedrock-incoming/ if present), then continue your roadmap."; next }
    { print }' MEMORY.md > "$t" && mv "$t" MEMORY.md
  echo "  edited         MEMORY.md (latest_commit → $wu)"
fi
git add -A || die "git add failed"
[ -f knowledge-map/scripts/gen_knowledge_map.sh ] && { bash knowledge-map/scripts/gen_knowledge_map.sh > KNOWLEDGE_MAP.md && git add KNOWLEDGE_MAP.md; }
# a pointer that still fails structurally (no existing tree named, a placeholder, an old shape) cannot pass
# the gate: repair active_work_unit first; if that is not enough, rewrite the whole current-state block and
# keep the previous one beside the tree (never lost).
if [ -f MEMORY.md ] && ! SPINE_COMMIT_MSG= bash scripts/check_resume_pointer.sh >/dev/null 2>&1; then
  t="MEMORY.md.update.$$"; cp -p MEMORY.md "$t"
  awk -v tree="$tree" '/^- active_work_unit:/ { print "- active_work_unit: `" tree "` (done) — then your own tree; previously: " substr($0, 22); next } { print }' MEMORY.md > "$t" && mv "$t" MEMORY.md
  git add MEMORY.md; echo "  edited         MEMORY.md (active_work_unit named no existing tree; now $tree)"
fi
if [ -f MEMORY.md ] && ! SPINE_COMMIT_MSG= bash scripts/check_resume_pointer.sh >/dev/null 2>&1; then
  mkdir -p .bedrock-incoming; cp -p MEMORY.md .bedrock-incoming/MEMORY.md.previous
  t="MEMORY.md.update.$$"; cp -p MEMORY.md "$t"
  awk '/^## Current state/ { exit } { print }' MEMORY.md > "$t"
  cat >> "$t" <<SEED
## Current state (OVERWRITE this block each update — do not append)

- next_action: review the spine update (docs/tasks/$tree.md, and .bedrock-incoming/ if present), then continue your roadmap; the previous pointer is at .bedrock-incoming/MEMORY.md.previous.
- active_work_unit: \`$tree\` (done) — then your own tree.
- latest_commit: \`$wu\` — spine updated to the version in DOCTRINE_VERSION.
- in_flight_uncommitted: none.
- blockers: none.
SEED
  mv "$t" MEMORY.md; git add MEMORY.md
  echo "  edited         MEMORY.md (the current-state block could not be repaired in place; rewritten — previous block kept at .bedrock-incoming/MEMORY.md.previous)"
fi

# ── the gate over the staged upgrade, with the commit's subject ─────────────────────────────
printf '%s\n' "$subject" > "$tmp/subject"
echo "update: judging the staged upgrade with the enforcer…"
gate_out="$(bash scripts/check_doctrines.sh --message "$tmp/subject" 2>&1)"; gate_rc=$?
printf '%s\n' "$gate_out" | grep -vE '^  ✅'
gate_tail="$(printf '%s\n' "$gate_out" | grep -E '^=== (all doctrines green|[0-9]+ doctrine breach)' | tail -1)"
t="docs/tasks/$tree.md.update.$$"; cp -p "docs/tasks/$tree.md" "$t"
awk -v r="\`scripts/check_doctrines.sh --message <subject>\` → \`${gate_tail:-(no summary line)}\` (\`rc=$gate_rc\`)." '{ i=index($0,"__GATE__"); if (i>0) $0=substr($0,1,i-1) r substr($0,i+8); print }' "docs/tasks/$tree.md" > "$t" && mv "$t" "docs/tasks/$tree.md"
git add "docs/tasks/$tree.md"
if [ "$gate_rc" -ne 0 ]; then
  echo "update: the gate REFUSED the staged upgrade — DOCTRINE_VERSION is NOT written. Fix what it names (often .bedrock-incoming/ merges), re-run the gate, commit." >&2
  exit 1
fi
printf '%s\n' "$new_version" > DOCTRINE_VERSION && git add DOCTRINE_VERSION
echo "✓ update: $n_seed seeded, $n_ff updated, $n_diff differ, $n_mig migration(s) — DOCTRINE_VERSION is now $new_version; the upgrade is staged."
[ "$n_diff" -gt 0 ] && { echo "  ⚠️  $n_diff file(s) you modified were NOT touched; the source's versions are in .bedrock-incoming/. Review them, take what you"; echo "      want, then:  rm -rf .bedrock-incoming   (improvement often flows project → bedrock; theirs is not automatically better)"; }
cat <<EOT

Commit the update (everything is staged; docs/tasks/$tree.md carries the evidence):
       printf '%s\\n' '$subject' > git_message_brief.txt
       git commit -F git_message_brief.txt && : > git_message_brief.txt
EOT
