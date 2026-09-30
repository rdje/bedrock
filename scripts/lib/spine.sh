#!/usr/bin/env bash
# scripts/lib/spine.sh — THE ONE LIBRARY EVERY CHECK READS THE CHANGE THROUGH (REVIEW-2026-09.3).
# SPDX-License-Identifier: LGPL-2.1-or-later
#
# Sourced, never executed:   . "$(dirname "${BASH_SOURCE[0]}")/lib/spine.sh"; spine_init CHECK-ID
#
# ⭐ WHAT IT FIXES, measured on the reviewed tree (docs/reviews/2026-09-30-consolidated-review.md):
#   BK-17  every check began `ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"` unchecked, and listed
#          the change with `git diff … 2>/dev/null || true`, so a git failure became "nothing staged",
#          which PASSES. Here a git failure is a REFUSAL (exit 2), never a verdict.
#   BR-03  checks read the WORKTREE while judging the INDEX, so an unstaged edit could hide a staged
#          defect. Here every read goes through `spine_read`, which reads the AFTER snapshot only.
#   BR-04  CI ran the driver on an empty index, so eight of thirteen checks passed vacuously. Here a
#          check receives a change context — BEFORE and AFTER revisions — and CI sets it per commit.
#   BR-08  `--diff-filter=ACM` dropped deletions and renames. Here `spine_changes` enumerates every
#          status, NUL-delimited, with both sides of a rename.
#   BK-06  configuration came from the worktree, so a commit could loosen the gate judging it. Here
#          gate-defining configuration is read from BEFORE (`spine_config`, `spine_config_file`).
#   NT-07  scratch files were written under `target/` inside the worktree. Here `spine_tmp` is a
#          temporary directory outside it, removed on exit.
#
# THE EXIT CONTRACT (every check, the driver reports it):   0 = the doctrine holds
#                                                            1 = a breach
#                                                            2 = cannot evaluate — REFUSED, and the
#                                                                driver FAILS on it; an error is never green
# THE CHANGE CONTEXT (environment, set by the driver; defaults for a bare run):
#   SPINE_BEFORE   a commit-ish, or unset → HEAD (the empty tree when there is no commit yet)
#   SPINE_AFTER    ":" → the index (the local pre-commit case) — or a commit-ish (CI, per commit)
#   SPINE_COMMIT_MSG  path of the commit message when one is available (commit-msg hook, CI)
#   SPINE_MERGE    "1" when AFTER is a merge commit (binding is exempt; invariants are not)
#
# ⛔ PORTABILITY: bash 3.2, POSIX awk/sed/grep, git ≥ 2.x. No arrays that bash 3.2 lacks, no GNU flags.

SPINE_ID="${SPINE_ID:-SPINE}"
SPINE_EMPTY_TREE="4b825dc642cb6eb9a060e54bf8d69288fbee4904"

spine_refuse() { printf '%s: REFUSED — %s\n' "$SPINE_ID" "$*" >&2; exit 2; }
spine_fail()   { printf '%s: %s\n' "$SPINE_ID" "$*" >&2; }
spine_ok()     { printf '%s: %s\n' "$SPINE_ID" "$*"; }

# git, checked: a failing git command is a refusal, not an empty result.
spine_git() {
  local out
  if ! out="$(git "$@" 2>"${SPINE_TMP:-/tmp}/.spine_git_err.$$")"; then
    local err; err="$(head -1 "${SPINE_TMP:-/tmp}/.spine_git_err.$$" 2>/dev/null)"; rm -f "${SPINE_TMP:-/tmp}/.spine_git_err.$$"
    spine_refuse "git $1 failed: ${err:-no message}"
  fi
  rm -f "${SPINE_TMP:-/tmp}/.spine_git_err.$$"
  printf '%s' "$out"
}

spine_tmp() { # a scratch directory OUTSIDE the worktree, removed on exit
  if [ -z "${SPINE_TMP:-}" ]; then
    SPINE_TMP="$(mktemp -d 2>/dev/null)" || spine_refuse "mktemp failed"
    trap 'rm -rf "$SPINE_TMP"' EXIT
  fi
  printf '%s' "$SPINE_TMP"
}

spine_init() { # $1 = CHECK-ID
  SPINE_ID="${1:-$SPINE_ID}"
  spine_tmp >/dev/null
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || spine_refuse "not inside a git worktree, or git failed (${GIT_DIR:+GIT_DIR=$GIT_DIR})"
  [ -n "$ROOT" ] || spine_refuse "git rev-parse returned no root"
  cd "$ROOT" || spine_refuse "cannot cd to $ROOT"
  # BEFORE
  if [ -n "${SPINE_BEFORE:-}" ]; then
    SPINE_BEFORE_SHA="$(git rev-parse --verify -q "${SPINE_BEFORE}^{commit}" 2>/dev/null)" \
      || { [ "$SPINE_BEFORE" = "$SPINE_EMPTY_TREE" ] && SPINE_BEFORE_SHA="$SPINE_EMPTY_TREE"; } \
      || spine_refuse "SPINE_BEFORE='$SPINE_BEFORE' does not resolve to a commit"
  elif SPINE_BEFORE_SHA="$(git rev-parse --verify -q 'HEAD^{commit}' 2>/dev/null)" && [ -n "$SPINE_BEFORE_SHA" ]; then
    :
  else
    SPINE_BEFORE_SHA="$SPINE_EMPTY_TREE"
  fi
  # AFTER
  SPINE_AFTER="${SPINE_AFTER:-:}"
  if [ "$SPINE_AFTER" != ":" ]; then
    SPINE_AFTER_SHA="$(git rev-parse --verify -q "${SPINE_AFTER}^{commit}" 2>/dev/null)" \
      || spine_refuse "SPINE_AFTER='$SPINE_AFTER' does not resolve to a commit"
  else
    SPINE_AFTER_SHA=":"
    git rev-parse --git-dir >/dev/null 2>&1 || spine_refuse "no index to judge"
  fi
  export SPINE_BEFORE_SHA SPINE_AFTER_SHA SPINE_AFTER ROOT
}

# ── the change ───────────────────────────────────────────────────────────────────────────────
# spine_changes: one line per entry, "STATUS<TAB>path" or "R<TAB>old<TAB>new" (also C). Statuses:
# A added · M modified · D deleted · R renamed · C copied · T type-changed.
spine_changes() {
  # ⛔ The NUL-delimited stream goes to a FILE: a `$( )` capture silently drops every NUL byte
  #    ("ignored null byte in input"), the entries run together, and the parse yields NOTHING —
  #    which every caller would read as "no change". Found by the probe drivers on first run.
  local f="$SPINE_TMP/changes.z" st a b
  if [ "$SPINE_AFTER_SHA" = ":" ]; then
    git diff --cached --name-status -M -z "$SPINE_BEFORE_SHA" > "$f" 2>"$SPINE_TMP/.err" || spine_refuse "git diff --cached failed: $(head -1 "$SPINE_TMP/.err")"
  else
    git diff --name-status -M -z "$SPINE_BEFORE_SHA" "$SPINE_AFTER_SHA" > "$f" 2>"$SPINE_TMP/.err" || spine_refuse "git diff failed: $(head -1 "$SPINE_TMP/.err")"
  fi
  [ -s "$f" ] || return 0
  while IFS= read -r -d '' st; do
    case "$st" in
      R*|C*) IFS= read -r -d '' a; IFS= read -r -d '' b; printf '%s\t%s\t%s\n' "${st%%[0-9]*}" "$a" "$b" ;;
      *)     IFS= read -r -d '' a; printf '%s\t%s\n' "$st" "$a" ;;
    esac
  done < "$f"
}
# paths that exist in AFTER and were touched (A, M, T, C-new, R-new)
spine_changed_paths() { spine_changes | awk -F'\t' '$1=="D"{next} $1=="R"||$1=="C"{print $3; next} {print $2}'; }
# paths that no longer exist in AFTER (D, R-old)
spine_removed_paths() { spine_changes | awk -F'\t' '$1=="D"{print $2; next} $1=="R"{print $2}'; }
# every path touched on either side
spine_touched_paths() { spine_changes | awk -F'\t' '{ print $2; if ($1=="R"||$1=="C") print $3 }'; }

# ── the snapshots ────────────────────────────────────────────────────────────────────────────
spine_after_ls() { # every path in AFTER (optionally filtered by a pathspec-like glob, e.g. '*.md')
  if [ "$SPINE_AFTER_SHA" = ":" ]; then git ls-files --cached -- ${1:+"$1"} 2>/dev/null || spine_refuse "git ls-files failed"
  else git ls-tree -r --name-only "$SPINE_AFTER_SHA" 2>/dev/null | { if [ -n "${1:-}" ]; then awk -v g="$1" 'BEGIN{ gsub(/\./,"\\.",g); gsub(/\*/,".*",g); g="^"g"$" } $0 ~ g' ; else cat; fi; }
  fi
}
spine_after_has() { # 0 if $1 exists in AFTER
  if [ "$SPINE_AFTER_SHA" = ":" ]; then git cat-file -e ":$1" 2>/dev/null; else git cat-file -e "$SPINE_AFTER_SHA:$1" 2>/dev/null; fi
}
spine_before_has() { [ "$SPINE_BEFORE_SHA" != "$SPINE_EMPTY_TREE" ] && git cat-file -e "$SPINE_BEFORE_SHA:$1" 2>/dev/null; }
spine_read() { # content of $1 in AFTER on stdout; exit 1 if absent; REFUSED on a git error
  spine_after_has "$1" || return 1
  if [ "$SPINE_AFTER_SHA" = ":" ]; then git show ":$1" 2>/dev/null || spine_refuse "git show :$1 failed"
  else git show "$SPINE_AFTER_SHA:$1" 2>/dev/null || spine_refuse "git show $SPINE_AFTER_SHA:$1 failed"; fi
}
spine_read_before() { spine_before_has "$1" || return 1; git show "$SPINE_BEFORE_SHA:$1" 2>/dev/null || spine_refuse "git show $SPINE_BEFORE_SHA:$1 failed"; }
spine_diff() { # unified diff (-U0) of $1 between BEFORE and AFTER
  if [ "$SPINE_AFTER_SHA" = ":" ]; then git diff --cached -U0 "$SPINE_BEFORE_SHA" -- "$1" 2>/dev/null || spine_refuse "git diff --cached -- $1 failed"
  else git diff -U0 "$SPINE_BEFORE_SHA" "$SPINE_AFTER_SHA" -- "$1" 2>/dev/null || spine_refuse "git diff -- $1 failed"; fi
}
spine_added_lines() { # NEW-file line numbers of the lines $1 gains in this change (added or modified)
  spine_diff "$1" | awk '
    /^@@/ { split($3,a,","); ln=a[1]+0; next }
    /^\+\+\+/ { next }
    /^\+/ { print ln; ln++; next }'
}
spine_added_text() { spine_diff "$1" | grep '^+' | grep -v '^+++' | sed 's/^+//'; }

# ── configuration, from BEFORE (a commit cannot weaken the gate that judges it) ──────────────
spine_config_file() { # content of .doctrine/$1 as of BEFORE, comments and blanks stripped; empty if absent
  spine_read_before ".doctrine/$1" 2>/dev/null | grep -vE '^[[:space:]]*(#|$)' || true
}
spine_config() { # $1 = key, $2 = default — from .doctrine/config (key = value) as of BEFORE
  local v; v="$(spine_config_file config | awk -F'=' -v k="$1" '{ key=$1; sub(/^[ \t]+/,"",key); sub(/[ \t]+$/,"",key); if (key==k) { v=$2; sub(/^[ \t]+/,"",v); sub(/[ \t]+$/,"",v); print v } }' | tail -1)"
  printf '%s' "${v:-$2}"
}
spine_re_valid() { # 0 if $1 is a valid ERE for this grep (2 from grep = invalid)
  grep -E -e "$1" /dev/null >/dev/null 2>&1; [ $? -ne 2 ]
}
# ⛔ NEVER call spine_refuse inside a `$( )` capture: `exit 2` there ends the SUBSHELL only, the
#    caller continues with an empty string, and an empty pattern matches everything — the check
#    would then PASS on the very configuration it meant to refuse (found by the suite's
#    invalid_regex_refused arm). Loaders therefore set VARIABLES and return a status; the caller
#    refuses at top level.
spine_re_from_lines() { # $1 = text (one ERE per line) → sets SPINE_RE; returns 1 and sets SPINE_BAD_RE on an invalid line
  local line
  SPINE_RE=""; SPINE_BAD_RE=""
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    spine_re_valid "$line" || { SPINE_BAD_RE="$line"; return 1; }
    SPINE_RE="${SPINE_RE:+$SPINE_RE|}$line"
  done <<SPINE_EOF
$1
SPINE_EOF
  return 0
}
