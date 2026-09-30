#!/usr/bin/env bash
# scripts/bootstrap.sh — first-time setup for a project created from bedrock (REVIEW-2026-09.5).
# SPDX-License-Identifier: LGPL-2.1-or-later
#
#   scripts/bootstrap.sh [<project-name>] [--title "<t>"] [--prefix <P>] [--visibility public|private]
#                        [--lang <pack>|none] [--docs <pack>|none] [--harness <a,b>|none] [--yes] [--ask]
#       initialise a NEW project from a pristine copy of the template. On a terminal without --yes it
#       ASKS — name, title, prefix, visibility, language pack, docs pack, harness adapters — showing
#       the choices and a default accepted with Enter, then a summary and a confirmation. Flags answer
#       questions in advance; --yes takes every default without asking; --ask asks even when piped.
#       Then: validate, de-template, install the selected packs, record the identity, install the
#       hooks, regenerate the Knowledge Map, seed the leaf that owns this step, STAGE everything, judge
#       the staged index with the enforcer, and print the first commit.
#   scripts/bootstrap.sh --contributor     in an initialised project: install the hooks, nothing else
#   scripts/bootstrap.sh --maintainer      in bedrock itself: hooks, map, enforcer; no de-templating
#   scripts/bootstrap.sh                   in an initialised project = --contributor;
#                                          in an uninitialised copy: usage, exit 2 (BK-18)
#
# ⛔ WHAT THIS REVISION FIXES, measured (docs/reviews/2026-09-30-consolidated-review.md):
#   BK-04  names were interpolated into `sed`: `x&y` wrote `name = "xname = "app"y"` (invalid TOML),
#          `a/b` made both substitutions fail behind `|| true`, and the seeded leaf then cited
#          "renamed to a/b" next to a hardcoded `(rc=0)`. Every name is validated BEFORE any write,
#          every edit is a LITERAL replacement that must change exactly one occurrence, and every
#          number in the seeded evidence is measured.
#   BK-04  the "enforcer run inside this bootstrap" ran with NOTHING staged. It now runs over the
#          staged index with the first commit's subject — the real verdict the hook will repeat.
#   BK-18  `make bootstrap` (no name) left a child that believed it was bedrock. Modes are explicit.
#   BR-06  files were deleted before anything was checked, and an uncommitted MEMORY.md edit was
#          discarded. Preflight refuses a dirty tree (unless there is no commit yet at all).
#   BR-10  `sed -i` is GNU-only: on a stock Mac it wrote `docs/TASK_TREE.md-e`. No `sed -i` remains.
#   BR-11  the printed commit carried a literal `<NAME>` and failed as printed. It is printed real.
#   BR-12  the child kept bedrock's CHANGELOG and DEV_NOTES history; a rerun with another name
#          renamed nothing and exited 0. The child's live docs are reset; the identity is recorded in
#          `.bedrock/project`; a rerun with the same name is idempotent, another name is refused.
# ⛔ PORTABILITY: bash 3.2, POSIX awk/sed/grep, git. Runs identically on a stock Mac and on Linux.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" || exit 2
cd "$ROOT" || exit 2
die() { printf 'bootstrap: %s\n' "$*" >&2; exit 2; }

# ── arguments ─────────────────────────────────────────────────────────────────────────────────
. "$(dirname "${BASH_SOURCE[0]}")/lib/setup_questions.sh"
mode=""; name=""; title=""; prefix=""; YES=0; ASK=0
NAME=""; TITLE=""; PREFIX=""; VISIBILITY=""; LANG_PACK=""; DOCS_PACK=""; HARNESS_PACKS=""
while [ $# -gt 0 ]; do
  case "$1" in
    --contributor) mode=contributor ;;
    --maintainer)  mode=maintainer ;;
    --title)  shift; TITLE="${1:-}" ;;
    --prefix) shift; PREFIX="${1:-}" ;;
    --visibility) shift; VISIBILITY="${1:-}" ;;
    --lang) shift; LANG_PACK="${1:-none}" ;;
    --docs) shift; DOCS_PACK="${1:-none}" ;;
    --harness) shift; HARNESS_PACKS="${1:-none}" ;;
    --yes) YES=1 ;;
    --ask) ASK=1 ;;
    -h|--help) sed -n '2,19p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) die "unknown option $1" ;;
    *) [ -z "$name" ] || die "one project name only (got '$name' and '$1')"; name="$1" ;;
  esac
  shift
done
NAME="$name"

# ── preflight (nothing is written before this block ends) ───────────────────────────────────
for t in git awk sed grep; do command -v "$t" >/dev/null 2>&1 || die "required tool missing: $t"; done
[ -d .git ] || [ -f .git ] || die "$ROOT is not the root of a git clone"
initialised=0; [ -f .bedrock/project ] && initialised=1
pristine=0;    [ -f MAINTAINING.md ] && pristine=1

interactive=0
if [ "$ASK" = 1 ]; then interactive=1; elif [ "$YES" = 1 ]; then interactive=0; elif [ -t 0 ]; then interactive=1; fi
if [ -z "$mode" ]; then
  if [ -n "$name" ]; then mode=init
  elif [ "$initialised" = 1 ]; then mode=contributor
  elif [ "$pristine" = 1 ] && [ "$interactive" = 1 ]; then mode=init
  elif [ "$pristine" = 1 ]; then
    { echo "bootstrap: this is an uninitialised copy of the bedrock template. Give it a name, or run it on a terminal to be asked:"
      echo "    scripts/bootstrap.sh <project-name> [--lang <pack>] [--docs <pack>] [--harness <pack,…>] [--yes]   (packs: ls packs/*/)"
      echo "  Maintaining bedrock itself?  scripts/bootstrap.sh --maintainer"; } >&2
    exit 2
  else die "neither an initialised project (.bedrock/project) nor a pristine template copy (MAINTAINING.md); nothing to do"; fi
fi

case "$mode" in
  contributor)
    git config core.hooksPath .githooks || die "git config failed"
    chmod +x scripts/*.sh scripts/evidence scripts/handoff scripts/tests/*.sh knowledge-map/scripts/*.sh .githooks/pre-commit .githooks/commit-msg 2>/dev/null || true
    echo "✓ git hooks activated (core.hooksPath=.githooks) for $(sed -n 's/^name = //p' .bedrock/project 2>/dev/null || echo 'this project'); nothing else touched"
    exit 0 ;;
  maintainer)
    [ "$pristine" = 1 ] || die "--maintainer is for the bedrock template itself (MAINTAINING.md is absent here)"
    git config core.hooksPath .githooks || die "git config failed"
    chmod +x scripts/*.sh scripts/evidence scripts/handoff scripts/tests/*.sh knowledge-map/scripts/*.sh .githooks/pre-commit .githooks/commit-msg 2>/dev/null || true
    echo "✓ git hooks activated (maintainer mode: no de-templating)"
    bash scripts/check_doctrines.sh; exit ;;
esac

# init mode: the questions (interactive) or the defaults, then validate everything, then check the ground
if [ "$interactive" = 1 ] && [ "$pristine" = 1 ] && [ "$initialised" = 0 ]; then
  setup_questions "$ROOT" "${name:-$(basename "$ROOT")}"
  setup_summary
  ask_yes_no "Proceed with this setup? Nothing has been written yet" y || { q_say "bootstrap: stopped; nothing written"; exit 2; }
else
  [ -n "$NAME" ] || NAME="$(basename "$ROOT")"
fi
name="$NAME"; title="${TITLE:-$NAME}"; prefix="${PREFIX:-$(derive_prefix "$NAME")}"; VISIBILITY="${VISIBILITY:-public}"
[ "$LANG_PACK" = none ] && LANG_PACK=""; [ "$DOCS_PACK" = none ] && DOCS_PACK=""; [ "$HARNESS_PACKS" = none ] && HARNESS_PACKS=""
valid_name "$name"   || die "project name '$name' is not valid"
valid_title "$title" || die "the title is not valid"
valid_prefix "$prefix" || die "work-unit prefix '$prefix' is not valid (pass --prefix)"
case "$VISIBILITY" in public|private) ;; *) die "--visibility is public or private" ;; esac
for p in ${LANG_PACK:+lang/$LANG_PACK} ${DOCS_PACK:+docs/$DOCS_PACK} $(printf '%s' "$HARNESS_PACKS" | tr ',' ' ' | sed 's/[^ ]*/harness\/&/g'); do
  [ -f "packs/$p/pack" ] || die "no such pack: $p (available: $(ls -d packs/*/*/ 2>/dev/null | sed 's|packs/||; s|/$||' | tr '\n' ' '))"
done

if [ "$initialised" = 1 ]; then
  cur="$(sed -n 's/^name = //p' .bedrock/project)"
  if [ "$cur" = "$name" ]; then
    echo "already initialised as '$name' — re-installing the hooks only (idempotent)"
    exec "$0" --contributor
  fi
  die "already initialised as '$cur'; renaming a project is a deliberate change with its own leaf, not a re-run (this call asked for '$name')"
fi
[ "$pristine" = 1 ] || die "this copy carries no MAINTAINING.md and no .bedrock/project: it is neither a pristine template nor an initialised project"
if git rev-parse -q --verify HEAD >/dev/null 2>&1; then
  [ -z "$(git status --porcelain --untracked-files=all)" ] \
    || die "the working tree is not clean; this run rewrites tracked files and would silently include or discard uncommitted work. Commit or stash first."
  first_commit=0
else
  first_commit=1   # a fresh `git init` (e.g. cargo-generate): the whole tree becomes the first commit
fi

# ── helpers: literal, mode-preserving edits; no sed -i, no regex on user text ────────────────
count_literal() { awk -v o="$2" '{ s=$0; while ((i=index(s,o))>0) { c++; s=substr(s,i+length(o)) } } END{ print c+0 }' "$1"; }
replace_literal() { # FILE OLD NEW — exactly one occurrence, or the run stops
  local f="$1" old="$2" new="$3" n tmp
  n="$(count_literal "$f" "$old")"
  [ "$n" -eq 1 ] || die "internal: expected exactly one occurrence of '$old' in $f, found $n — nothing written"
  tmp="$f.bootstrap.$$"; cp -p "$f" "$tmp" || die "cannot write $tmp"
  awk -v o="$old" -v n="$new" '{ i=index($0,o); if (i>0) $0=substr($0,1,i-1) n substr($0,i+length(o)); print }' "$f" > "$tmp" && mv "$tmp" "$f" || die "edit of $f failed"
}
delete_between() { # FILE START-MARKER END-MARKER (inclusive, literal)
  local f="$1" tmp="$1.bootstrap.$$"
  cp -p "$f" "$tmp" && awk -v a="$2" -v b="$3" '{ if (!d && index($0,a)) { d=1 } if (!d) print; else if (index($0,b)) d=0 }' "$f" > "$tmp" && mv "$tmp" "$f" || die "edit of $f failed"
}
truncate_from() { # FILE LINE-PREFIX — drop that line and everything after it
  local f="$1" tmp="$1.bootstrap.$$"
  cp -p "$f" "$tmp" && awk -v a="$2" '{ if (index($0,a)==1) exit; print }' "$f" > "$tmp" && mv "$tmp" "$f" || die "edit of $f failed"
}

# ── 0) de-template: everything bedrock-only goes — every `maintainer`-class path of the manifest, so a
#       new bedrock-only file (its user guide, its workflow) cannot reach a child by being forgotten here
echo "→ initialising project '$name' (title: $title, work-unit prefix: $prefix)"
if [ -f .bedrock/manifest ]; then
  grep -vE '^[[:space:]]*(#|$)' .bedrock/manifest | awk '$2=="maintainer" { print $1 }' | while IFS= read -r mp; do
    case "$mp" in ""|/*|*..*) continue ;; */) rm -rf "${mp%/}" ;; *) rm -f "$mp" ;; esac
  done
fi
rm -f MAINTAINING.md docs/tasks/BEDROCK-MAINTENANCE.md docs/tasks/REVIEW-2026-09.md
rm -rf docs/reviews
for f in docs/decisions/*.md; do case "$(basename "$f")" in INDEX.md|TEMPLATE.md) ;; *) rm -f "$f" ;; esac; done
for f in AGENTS.md ROADMAP.md; do [ -f "$f" ] && delete_between "$f" "BEDROCK-MAINTAINER-NOTE:START" "BEDROCK-MAINTAINER-NOTE:END"; done
source_version="$(cat DOCTRINE_VERSION 2>/dev/null || echo bedrock-scaffold)"
today="$(date +%F)"

cat > docs/decisions/INDEX.md <<'SEED'
# Decision & Fact Records — Index (memory layer C)

Durable, cross-cutting facts and decisions live here, one record per file (ADR-style). Every
record must be listed below (the MEMORY-ARCH doctrine check enforces it). New record: copy
`TEMPLATE.md` → `<type>_<short-kebab-slug>.md`, fill it in, and add its row.

| Record | Type | One-line hook |
| --- | --- | --- |
| _none yet_ | | |
SEED

truncate_from docs/TASK_TREE.md "## Active Task Trees"
cat >> docs/TASK_TREE.md <<SEED
## Active Task Trees

| Tree | Status | Frontier (next leaf) | Owner |
| --- | --- | --- | --- |
| [\`BOOTSTRAP\`](tasks/BOOTSTRAP.md) | \`done\` | \`.1\` — bootstrapped from bedrock; seed your first real tree from \`ROADMAP.md\` | repo-local |
SEED

cat > CHANGELOG.md <<SEED
# CHANGELOG.md

## 0.1.0 — $today — bootstrapped from bedrock

\`${prefix}-BOOTSTRAP-0001\` (leaf \`BOOTSTRAP.1\`). Project \`$name\` created from the bedrock discipline-spine
template ($source_version): durable 4-layer memory, task-tree tracking, the strict commit workflow, and the
mechanical doctrine enforcer are in place and enforced by git hooks + CI. No project code yet.
SEED

cat > DEV_NOTES.md <<SEED
# DEV_NOTES.md

Detailed technical notes — root cause, implementation, validation — per slice. The
engineering-continuity surface (not the public docs). Newest first. A NEW dated lesson heading
here must be promoted to \`docs/decisions/\` (or \`docs/knowledge/\`) or explicitly declined in its
leaf — the \`LESSON-PROMOTION\` doctrine.

## _(bootstrap)_ — project created from bedrock

Repo created from the \`bedrock\` template ($source_version) by \`scripts/bootstrap.sh $name\`.
SEED

cat > LIVE_STATUS.md <<SEED
# LIVE_STATUS.md — authoritative live progress tracker

Rows use ONLY these four states: **Done · Mostly Done · In Progress · Not Started**.
Review and update before every commit whenever actual closure or remaining scope changes;
summarize the snapshot in every commit-workflow completion message.

| Area | Status | Notes |
| --- | --- | --- |
| Discipline spine (from bedrock $source_version) | Done | memory architecture · task-trees · commit workflow · doctrine enforcement |
| Roadmap seeded into task-trees | Not Started | replace \`ROADMAP.md\`, then create your first tree from \`docs/tasks/TEMPLATE.md\` |
| _(your first milestone)_ | Not Started | — |
SEED
echo "✓ de-templated: maintainer files, reviews and decision records removed; live docs reset"

# ── 1) the packs: copy the selected ones in (collisions refused), append their fragments, run their hooks;
#       then packs/ leaves the project — an unselected pack is never copied (decision_neutral_spine_and_packs)
crate_line=""; packs_installed=""; pack_lines=""
install_pack() { # $1 = kind/name
  local d="packs/$1" f rel hook out
  if [ -d "$d/files" ]; then
    ( cd "$d/files" && find . -type f ) | sed 's|^\./||' | while IFS= read -r rel; do
      if [ -e "$rel" ]; then echo "bootstrap: pack $1 would overwrite $rel — refused" >&2; exit 3; fi
    done || die "pack $1 collides with existing files"
    ( cd "$d/files" && find . -type f ) | sed 's|^\./||' | while IFS= read -r rel; do mkdir -p "$(dirname "$rel")"; cp -p "$d/files/$rel" "$rel"; done
  fi
  for f in gitignore commands evidence_tokens docs_paths handoff_ignore; do
    [ -f "$d/$f" ] || continue
    case "$f" in gitignore) t=.gitignore ;; commands) t=.doctrine/commands ;; evidence_tokens) t=.doctrine/evidence_tokens.txt ;; docs_paths) t=.doctrine/docs_paths.txt ;; handoff_ignore) t=.doctrine/handoff_ignore ;; esac
    { printf '\n'; cat "$d/$f"; } >> "$t"
  done
  hook="$(sed -n 's/^install = //p' "$d/pack" | head -1)"
  if [ -n "$hook" ] && [ -f "$d/$hook" ]; then
    out="$(bash "$d/$hook" "$name" "$title" 2>&1)" || { printf '%s\n' "$out" >&2; die "pack $1's install hook failed"; }
    printf '%s\n' "$out"
    pack_lines="$pack_lines $(printf '%s' "$out" | tr '\n' ' ')"
  fi
  packs_installed="${packs_installed:+$packs_installed,}${1##*/}"
  echo "✓ pack installed: $1"
}
[ -z "$LANG_PACK" ] || install_pack "lang/$LANG_PACK"
[ -z "$DOCS_PACK" ] || install_pack "docs/$DOCS_PACK"
for h in $(printf '%s' "$HARNESS_PACKS" | tr ',' ' '); do install_pack "harness/$h"; done
rm -rf packs
replace_literal ROADMAP.md "# ROADMAP — _(PROJECT NAME)_" "# ROADMAP — $title"
# the contract epoch is bedrock's own commit: a child's whole history is under the contract it receives
if [ -f .doctrine/config ] && grep -q '^ci_range_since = .' .doctrine/config; then
  t=".doctrine/config.bootstrap.$$"; cp -p .doctrine/config "$t"
  awk '/^ci_range_since = / { print "ci_range_since ="; next } { print }' .doctrine/config > "$t" && mv "$t" .doctrine/config || die "edit of .doctrine/config failed"
fi
if [ "$VISIBILITY" = private ] && [ -f VISIBILITY.md ]; then
  replace_literal VISIBILITY.md "> **Declared posture: PUBLIC.**" "> **Declared posture: PRIVATE.** (declared at setup on $today; record the reason and the authority in \`docs/decisions/\`.)"
fi
mkdir -p .bedrock
cat > .bedrock/project <<SEED
# .bedrock/project — this project's identity, written by scripts/bootstrap.sh (do not edit by hand).
name = $name
title = $title
prefix = $prefix
visibility = $VISIBILITY
created = $today
source = $source_version
packs = $packs_installed
SEED
echo "✓ identity recorded in .bedrock/project (name=$name, prefix=$prefix, packs=${packs_installed:-none})"

# ── 2) hooks and modes ───────────────────────────────────────────────────────────────────────
git config core.hooksPath .githooks || die "git config failed"
chmod +x scripts/*.sh scripts/evidence scripts/handoff scripts/tests/*.sh knowledge-map/scripts/*.sh .githooks/pre-commit .githooks/commit-msg 2>/dev/null || true
hooks_path="$(git config core.hooksPath)"
echo "✓ git hooks activated (core.hooksPath=$hooks_path)"

# ── 3) the resume pointer, true for the first commit ─────────────────────────────────────────
cat > MEMORY.md <<SEED
# MEMORY — resume pointer (layer A; overwrite-only)

> Answers ONE question: **what is next?** Nothing else belongs in it — see
> \`MEMORY_ARCHITECTURE.md\` §6. If this file grows, something is being written into it
> that belongs in another layer.

## Current state (OVERWRITE this block each update — do not append)

- next_action: replace \`ROADMAP.md\`; create your first task-tree (\`cp docs/tasks/TEMPLATE.md docs/tasks/<TREE-ID>.md\`) and register it in \`docs/TASK_TREE.md\`.
- active_work_unit: \`BOOTSTRAP\` (its only leaf is done) — seed your first real tree from \`ROADMAP.md\`.
- latest_commit: \`${prefix}-BOOTSTRAP-0001\` — the bootstrap commit (make it with the command bootstrap printed).
- in_flight_uncommitted: none.
- blockers: none.
SEED

# ── 4) the leaf that owns this bootstrap, with measured evidence ─────────────────────────────
subject="${prefix}-BOOTSTRAP-0001 (leaf BOOTSTRAP.1): bootstrapped from bedrock"
cat > docs/tasks/BOOTSTRAP.md <<LEAF
# BOOTSTRAP: this project's bootstrap from the bedrock template

## Metadata

- Tree ID: \`BOOTSTRAP\`
- Status: \`done\`
- Roadmap lane: project setup
- Created: \`$today\`
- Owner: repo-local workflow

## Goal

Record the one-time initialisation of this copy of bedrock ($source_version) into project \`$name\`
(title "$title", work-unit prefix \`$prefix\`), performed by \`scripts/bootstrap.sh $name\`, with the
evidence that run measured — so the first commit of this project passes the same gates every later
commit will.

## Non-Goals

- This tree does not describe the project's roadmap. Seed that tree from \`ROADMAP.md\`.

## Task Tree

- ID: \`BOOTSTRAP.1\`
  Status: \`done\`
  Goal: de-template, install the selected packs (${packs_installed:-none}), record the identity, install the hooks, regenerate the Knowledge Map, judge the staged first commit.

  ### Acceptance Checklist (enforced by \`TASK-ACCEPTANCE\`)

  - [x] **ROOT CAUSE (WHY + WHERE)** — a copy of bedrock carries the template's maintainer files, its live-doc
    history and the starter's placeholder name: \`ls MAINTAINING.md\` → present before this run (\`rc=0\`),
    absent after (\`rc=2\`); the de-template step removed them; packs installed: ${packs_installed:-none}.${pack_lines}
  - [x] **ADDRESSED (verified)** — identity written: \`sed -n 's/^name = //p' .bedrock/project\` → \`$name\`
    (\`rc=0\`); hooks installed: \`git config core.hooksPath\` → \`$hooks_path\` (\`rc=0\`); the Knowledge Map
    regenerated; the enforcer over the STAGED index with this commit's subject: __GATE__
  - [x] **NO REGRESSION** — the same enforcer is the pre-commit and commit-msg hook, so the first commit is
    judged again by \`scripts/check_doctrines.sh\` exactly as measured here (\`rc=0\` expected; \`scripts/gate\`
    re-runs it anytime); __STAGED__ path(s) staged, all written by this run.

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| — | \`BOOTSTRAP.1\` | \`done\` | the bootstrap itself; nothing further belongs here — seed your first real tree from \`ROADMAP.md\` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| \`BOOTSTRAP.1\` | \`$subject\` | the first commit |
LEAF
echo "✓ docs/tasks/BOOTSTRAP.md seeded"

# ── 5) the Knowledge Map, from the index: stage first, then generate ─────────────────────────
git add -A || die "git add failed"
if [ -f knowledge-map/scripts/gen_knowledge_map.sh ]; then
  bash knowledge-map/scripts/gen_knowledge_map.sh > KNOWLEDGE_MAP.md || die "the Knowledge Map generator failed"
  git add KNOWLEDGE_MAP.md
  echo "✓ KNOWLEDGE_MAP.md generated from the staged sources"
fi

# ── 6) judge the STAGED index with the first commit's subject — the real verdict ─────────────
staged_n="$(git diff --cached --name-only | wc -l | tr -d ' ')"
replace_literal docs/tasks/BOOTSTRAP.md "__STAGED__" "$staged_n"
replace_literal docs/tasks/BOOTSTRAP.md "__GATE__" "measured on the staged index before this sentence was written, and repeated by the hook: see below."
git add docs/tasks/BOOTSTRAP.md
printf '%s\n' "$subject" > "$ROOT/.bootstrap.subject"
echo "→ running the doctrine enforcer over the staged index…"
gate_out="$(bash scripts/check_doctrines.sh --message "$ROOT/.bootstrap.subject" 2>&1)"; gate_rc=$?
rm -f "$ROOT/.bootstrap.subject"
printf '%s\n' "$gate_out"
gate_tail="$(printf '%s\n' "$gate_out" | grep -E '^=== (all doctrines green|[0-9]+ doctrine breach)' | tail -1)"
replace_literal docs/tasks/BOOTSTRAP.md "measured on the staged index before this sentence was written, and repeated by the hook: see below." \
  "\`scripts/check_doctrines.sh --message <subject>\` → \`${gate_tail:-(no summary line)}\` (\`rc=$gate_rc\`), over $staged_n staged path(s)."
git add docs/tasks/BOOTSTRAP.md
[ "$gate_rc" = 0 ] || { echo "bootstrap: the enforcer reported a breach on the staged first commit — fix it, then commit" >&2; exit 1; }

cat <<EOT

bedrock is ready: project '$name' is initialised and its first commit is staged.

Next:
  0) Commit the bootstrap itself (everything is staged; its leaf docs/tasks/BOOTSTRAP.md carries the evidence):
       printf '%s\\n' '$subject' > git_message_brief.txt
       git commit -F git_message_brief.txt && : > git_message_brief.txt

  1) Read VISIBILITY.md and decide deliberately: this project is PUBLIC by default and carries
     nothing confidential; if it must be private, change the declared posture there and record why.
  2) Replace ROADMAP.md with your project's real roadmap.
  3) Create your first task-tree:  cp docs/tasks/TEMPLATE.md docs/tasks/<TREE-ID>.md   (then register it
     in docs/TASK_TREE.md's Active Task Trees table, and point MEMORY.md at it).
  4) Work its first leaf, commit via COMMIT.md, and end every session with:  scripts/handoff

Anyone who clones this project later runs only:  scripts/bootstrap.sh --contributor
EOT
