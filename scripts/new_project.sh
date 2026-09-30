#!/usr/bin/env bash
# scripts/new_project.sh — create a NEW project from bedrock, start to finish, from a clone of bedrock.
# SPDX-License-Identifier: LGPL-2.1-or-later
#
#   scripts/new_project.sh [--name <n>] [--dest <dir>] [--github|--local] [--owner <gh-user-or-org>]
#                          [--title "<t>"] [--prefix <P>] [--visibility public|private]
#                          [--lang <pack>|none] [--docs <pack>|none] [--harness <a,b>|none] [--yes] [--push|--no-push]
#
# Maintainer request, 2026-09-30: the user must not have to remember `gh repo create --template …`.
# Run this in a clone of bedrock and answer the questions (Enter accepts each default); it then
#   1. creates the repository — on GitHub through `gh` (if installed and logged in, and you say so),
#      from this bedrock as the template, with your visibility — or a local repository from an export;
#   2. clones / initialises it at the destination;
#   3. runs scripts/bootstrap.sh there with your answers (packs installed, identity recorded, hooks on);
#   4. makes the first commit through the hooks, and pushes it if you asked;
#   5. prints where the project is and what to do next.
# Nothing is written before the summary is confirmed. bash 3.2, git; `gh` only for the GitHub path.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" || exit 2
cd "$ROOT" || exit 2
. "$ROOT/scripts/lib/setup_questions.sh"
die() { printf 'new_project: %s\n' "$*" >&2; exit 2; }
[ -f MAINTAINING.md ] && [ -d packs ] || die "run this from a clone of bedrock (the template itself); a project uses scripts/bootstrap.sh"

NAME=""; TITLE=""; PREFIX=""; VISIBILITY=""; LANG_PACK=""; DOCS_PACK=""; HARNESS_PACKS=""
DEST=""; WHERE=""; OWNER=""; YES=0; PUSH=""
while [ $# -gt 0 ]; do
  case "$1" in
    --name) shift; NAME="${1:-}" ;;
    --dest) shift; DEST="${1:-}" ;;
    --github) WHERE=github ;;
    --local) WHERE=local ;;
    --owner) shift; OWNER="${1:-}" ;;
    --title) shift; TITLE="${1:-}" ;;
    --prefix) shift; PREFIX="${1:-}" ;;
    --visibility) shift; VISIBILITY="${1:-}" ;;
    --lang) shift; LANG_PACK="${1:-none}" ;;
    --docs) shift; DOCS_PACK="${1:-none}" ;;
    --harness) shift; HARNESS_PACKS="${1:-none}" ;;
    --yes) YES=1 ;;
    --push) PUSH=1 ;;
    --no-push) PUSH=0 ;;
    -h|--help) sed -n '2,18p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown option $1" ;;
  esac
  shift
done
interactive=1; [ "$YES" = 1 ] && interactive=0; [ -t 0 ] || [ "$YES" = 0 ] && interactive=$interactive

gh_ok=0
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then gh_ok=1; fi
template="$(git remote get-url origin 2>/dev/null | sed 's/\.git$//; s|^git@github\.com:|https://github.com/|')"

if [ "$YES" = 1 ]; then
  [ -n "$NAME" ] || die "--yes needs --name"
  TITLE="${TITLE:-$NAME}"; PREFIX="${PREFIX:-$(derive_prefix "$NAME")}"; VISIBILITY="${VISIBILITY:-public}"
  [ "$LANG_PACK" = none ] && LANG_PACK=""; [ "$DOCS_PACK" = none ] && DOCS_PACK=""; [ "$HARNESS_PACKS" = none ] && HARNESS_PACKS=""
  WHERE="${WHERE:-$( [ "$gh_ok" = 1 ] && echo github || echo local )}"
else
  setup_questions "$ROOT" "${NAME:-my-project}"
  if [ -z "$WHERE" ]; then
    if [ "$gh_ok" = 1 ]; then
      Q_OPTS="github|create it on GitHub from the bedrock template (gh is logged in), then clone it
local|a local git repository only; add a remote later"
      ask_choice WHERE "Where should the repository live?" github
    else
      q_say "  (gh is not installed or not logged in: the repository will be local; add a remote later)"; WHERE=local
    fi
  fi
  if [ "$WHERE" = github ] && [ -z "$OWNER" ]; then
    ask_text OWNER "GitHub owner (your user or an organisation)" "$(gh api user -q .login 2>/dev/null || true)"
  fi
  [ -n "$DEST" ] || ask_text DEST "Destination directory" "$(cd "$ROOT/.." && pwd)/$NAME"
  setup_summary
  q_say "  where       $WHERE${OWNER:+ ($OWNER/$NAME)}"; q_say "  directory   $DEST"; q_say ""
  ask_yes_no "Create the project now?" y || { q_say "new_project: stopped; nothing written"; exit 2; }
fi
[ -n "$DEST" ] || DEST="$(cd "$ROOT/.." && pwd)/$NAME"
[ -e "$DEST" ] && die "$DEST already exists; choose another destination"
valid_name "$NAME" || die "invalid name"

# ── 1+2. the repository ──────────────────────────────────────────────────────────────────────
created_on=""
if [ "$WHERE" = github ]; then
  [ "$gh_ok" = 1 ] || die "the GitHub path needs gh installed and logged in (gh auth login), or use --local"
  [ -n "$OWNER" ] || OWNER="$(gh api user -q .login 2>/dev/null)" || die "cannot determine the GitHub owner; pass --owner"
  [ -n "$template" ] || die "this bedrock clone has no origin remote to use as the template"
  echo "→ creating $OWNER/$NAME on GitHub from the template $template ($VISIBILITY)…"
  if ( cd "$(dirname "$DEST")" && gh repo create "$OWNER/$NAME" --template "$template" "--$VISIBILITY" --clone >/dev/null ) \
     && [ -d "$DEST/.git" ]; then created_on="github"
  else
    echo "new_project: gh could not create or clone the repository (is bedrock marked 'Template repository' on GitHub?); falling back to a local repository" >&2
    WHERE=local
  fi
  # GitHub's copy may take a moment to carry the files
  if [ "$created_on" = github ] && [ ! -f "$DEST/MAINTAINING.md" ]; then sleep 3; ( cd "$DEST" && git pull -q 2>/dev/null ); fi
fi
if [ "$WHERE" = local ]; then
  echo "→ creating a local repository at $DEST from bedrock $(git rev-parse --short HEAD)…"
  mkdir -p "$DEST" && git archive HEAD | tar -x -C "$DEST" || die "export failed"
  ( cd "$DEST" && git init -q -b main . && git add -A && git -c core.hooksPath=/dev/null commit -qm "Initial commit" ) || die "git init failed"
  created_on="local"
fi

# ── 3. bootstrap with the answers ───────────────────────────────────────────────────────────
echo "→ bootstrapping…"
( cd "$DEST" && bash scripts/bootstrap.sh "$NAME" --title "$TITLE" --prefix "$PREFIX" --visibility "$VISIBILITY" \
    --lang "${LANG_PACK:-none}" --docs "${DOCS_PACK:-none}" --harness "${HARNESS_PACKS:-none}" --yes ) > "$DEST/.bootstrap.log" 2>&1 \
  || { tail -20 "$DEST/.bootstrap.log" >&2; die "bootstrap failed in $DEST (log: $DEST/.bootstrap.log)"; }
grep -E '^✓' "$DEST/.bootstrap.log" | sed 's/^/  /'

# ── 4. the first commit, through the hooks; then the push ────────────────────────────────────
subject="$PREFIX-BOOTSTRAP-0001 (leaf BOOTSTRAP.1): bootstrapped from bedrock"
( cd "$DEST" && printf '%s\n' "$subject" > git_message_brief.txt && git commit -q -F git_message_brief.txt && : > git_message_brief.txt ) \
  || die "the first commit was refused by the hooks in $DEST — read the output above"
rm -f "$DEST/.bootstrap.log"
echo "✓ first commit made: $subject"
if [ "$created_on" = github ]; then
  if [ -z "$PUSH" ]; then if [ "$interactive" = 1 ]; then ask_yes_no "Push the first commit to GitHub now?" y && PUSH=1 || PUSH=0; else PUSH=1; fi; fi
  if [ "$PUSH" = 1 ]; then ( cd "$DEST" && git push -q -u origin main ) && echo "✓ pushed to $OWNER/$NAME" || echo "new_project: push failed; push later with: git push -u origin main" >&2; fi
fi

cat <<EOT

✓ project '$NAME' is ready at $DEST${created_on:+ ($created_on)}.

Next, in $DEST:
  1) read VISIBILITY.md (posture: $VISIBILITY) and ROADMAP.md; replace the roadmap with yours
  2) cp docs/tasks/TEMPLATE.md docs/tasks/<TREE-ID>.md, register it in docs/TASK_TREE.md, point MEMORY.md at it
  3) work leaf by leaf; commit via COMMIT.md; run  scripts/gate  anytime; end every session with  scripts/handoff
$( [ "$created_on" = local ] && echo "  (to publish later: create an empty repository on GitHub, then  git remote add origin <url> && git push -u origin main)" )
EOT
