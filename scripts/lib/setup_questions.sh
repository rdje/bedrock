#!/usr/bin/env bash
# scripts/lib/setup_questions.sh — the guided question-and-answer setup, shared by scripts/bootstrap.sh
# (a copy made with GitHub's "Use this template") and scripts/new_project.sh (run from bedrock itself).
# SPDX-License-Identifier: LGPL-2.1-or-later
#
# Maintainer requests, 2026-09-30: every question shows its choices and a sensible default accepted
# with Enter; invalid input is re-asked; a summary and a final confirmation come before anything is
# written; plain prompts, no TUI library, so it runs identically on a stock Mac, Linux and CI; the
# answers are also settable by flags (the non-interactive path) and recorded in .bedrock/project.
# Prompts go to stderr, so answers can be piped in (tests) and stdout stays clean. bash 3.2.

q_say()  { printf '%s\n' "$*" >&2; }
q_read() { local ans; IFS= read -r ans 2>/dev/null || ans=""; printf '%s' "$ans"; }

# ask_text VAR "question" "default" [validator]   — validator: a function returning 0/1 and printing why on failure
ask_text() {
  local var="$1" q="$2" def="$3" val="${4:-}" ans
  while :; do
    printf '%s [%s]: ' "$q" "${def:-none}" >&2
    ans="$(q_read)"; [ -n "$ans" ] || ans="$def"
    if [ -n "$val" ] && ! "$val" "$ans"; then q_say "  ↳ try again."; continue; fi
    eval "$var=\"\$ans\""; return 0
  done
}
# ask_choice VAR "question" "default-key"   — options in $Q_OPTS, one "key|title" per line; numbered;
# answer by number or key; Enter = default
ask_choice() {
  local var="$1" q="$2" def="$3"
  local i=0 keys="" k t ans n opt
  q_say "$q"
  while IFS= read -r opt; do [ -n "$opt" ] || continue; i=$((i+1)); k="${opt%%|*}"; t="${opt#*|}"; keys="$keys $k"; printf '  %d) %-10s %s%s\n' "$i" "$k" "$t" "$( [ "$k" = "$def" ] && printf '  (default)' )" >&2; done <<OPTS
$Q_OPTS
OPTS
  while :; do
    printf '  choice [%s]: ' "$def" >&2
    ans="$(q_read)"; [ -n "$ans" ] || ans="$def"
    n=0; for k in $keys; do n=$((n+1)); if [ "$ans" = "$k" ] || [ "$ans" = "$n" ]; then eval "$var=\"\$k\""; return 0; fi; done
    q_say "  ↳ '$ans' is not one of the choices; answer with a number or a name."
  done
}
# ask_multi VAR "question" "default"   — options in $Q_OPTS; comma-separated numbers/keys, or 'none'
ask_multi() {
  local var="$1" q="$2" def="$3"
  local i=0 keys="" k t ans n picked item ok opt found
  q_say "$q"
  q_say "  0) none"
  while IFS= read -r opt; do [ -n "$opt" ] || continue; i=$((i+1)); k="${opt%%|*}"; t="${opt#*|}"; keys="$keys $k"; printf '  %d) %-10s %s\n' "$i" "$k" "$t" >&2; done <<OPTS
$Q_OPTS
OPTS
  while :; do
    printf '  choices, comma-separated [%s]: ' "$def" >&2
    ans="$(q_read)"; [ -n "$ans" ] || ans="$def"
    picked=""; ok=1
    for item in $(printf '%s' "$ans" | tr ',' ' '); do
      [ "$item" = 0 ] || [ "$item" = none ] && continue
      n=0; found=""
      for k in $keys; do n=$((n+1)); if [ "$item" = "$k" ] || [ "$item" = "$n" ]; then found="$k"; fi; done
      [ -n "$found" ] || { ok=0; q_say "  ↳ '$item' is not one of the choices."; break; }
      case " $picked " in *" $found "*) ;; *) picked="${picked:+$picked }$found" ;; esac
    done
    [ "$ok" = 1 ] || continue
    eval "$var=\"\$(printf '%s' \"\$picked\" | tr ' ' ',')\""; return 0
  done
}
ask_yes_no() { # ask_yes_no "question" y|n → 0 = yes
  local q="$1" def="$2" ans
  while :; do
    printf '%s [%s]: ' "$q" "$( [ "$def" = y ] && echo 'Y/n' || echo 'y/N' )" >&2
    ans="$(q_read)"; [ -n "$ans" ] || ans="$def"
    case "$ans" in y|Y|yes|YES) return 0 ;; n|N|no|NO) return 1 ;; *) q_say "  ↳ answer y or n." ;; esac
  done
}

# ── the validators the setup uses ─────────────────────────────────────────────────────────────
valid_name()   { printf '%s' "$1" | grep -Eq '^[A-Za-z][A-Za-z0-9_-]{0,63}$' && return 0; q_say "  a project name is a letter, then letters, digits, '-' or '_' (max 64) — it names the identity, the work-unit prefix and a starter crate"; return 1; }
valid_title()  { case "$1" in *'`'*|*'\'*) q_say "  no backquote or backslash in a title"; return 1 ;; esac; [ "${#1}" -le 120 ] && return 0; q_say "  at most 120 characters"; return 1; }
valid_prefix() { printf '%s' "$1" | grep -Eq '^[A-Z][A-Z0-9]*(-[A-Z0-9]+)*$' && return 0; q_say "  a prefix is uppercase words joined by '-', e.g. MYPROJ or MY-PROJ"; return 1; }
derive_prefix() { printf '%s' "$1" | tr '[:lower:]_' '[:upper:]-' | tr -cd 'A-Z0-9-' | sed 's/^-*//; s/-*$//; s/--*/-/g'; }

# ── packs available under $1/packs ────────────────────────────────────────────────────────────
pack_title() { sed -n 's/^title = //p' "$1/pack" 2>/dev/null | head -1; }
pack_field() { sed -n "s/^$2 = //p" "$1/pack" 2>/dev/null | head -1; }
pack_options() { # $1 = packs root, $2 = kind → "name|title" per line, in the order the packs declare (`order =`)
  local d; for d in "$1"/packs/"$2"/*/; do [ -f "$d/pack" ] || continue; printf '%s\t%s|%s\n' "$(pack_field "$d" order | sed 's/^$/99/')" "$(basename "$d")" "$(pack_title "$d")"; done | sort -n | cut -f2-
}
pack_default() { # $1 = packs root, $2 = kind → the name of the pack declaring `default = yes`, else "none"
  local d; for d in "$1"/packs/"$2"/*/; do [ -f "$d/pack" ] || continue; [ "$(pack_field "$d" default)" = yes ] && { basename "$d"; return; }; done; echo none
}

# ── the setup questions: fills NAME TITLE PREFIX VISIBILITY LANG DOCS HARNESS (defaults respected) ─
# $1 = packs root (where packs/ lives), $2 = default name
setup_questions() {
  local proot="$1" defname="$2"
  q_say ""; q_say "bedrock — set up a new project. Enter accepts the value in brackets."; q_say ""
  [ -n "${NAME:-}" ]   || ask_text NAME "1/7  Project name" "$defname" valid_name
  [ -n "${TITLE:-}" ]  || ask_text TITLE "2/7  Display title" "$NAME" valid_title
  [ -n "${PREFIX:-}" ] || ask_text PREFIX "3/7  Work-unit prefix (commit subjects start with it)" "$(derive_prefix "$NAME")" valid_prefix
  if [ -z "${VISIBILITY:-}" ]; then
    Q_OPTS="public|the repository is public; nothing confidential ever goes in
private|the repository is private; record why in docs/decisions/"
    ask_choice VISIBILITY "4/7  Visibility posture (VISIBILITY.md; nothing confidential goes into a public repository)" public
  fi
  if [ -z "${LANG_PACK:-}" ]; then
    Q_OPTS="none|no language: add your own build and its verbs to .doctrine/commands
$(pack_options "$proot" lang)"
    ask_choice LANG_PACK "5/7  Language pack (the spine itself is language-neutral)" none
  fi
  if [ -z "${DOCS_PACK:-}" ]; then
    Q_OPTS="none|no docs tool: declare a docs verb later if you want one
$(pack_options "$proot" docs)"
    ask_choice DOCS_PACK "6/7  Docs pack (the public documentation surface)" none
  fi
  if [ -z "${HARNESS_PACKS:-}" ]; then
    Q_OPTS="$(pack_options "$proot" harness)"
    ask_multi HARNESS_PACKS "7/7  Harness packs (AGENTS.md is canonical and every harness reads it; a pack adds the adapter file a harness auto-reads, if it needs one, and its hand-off exclusions — the harness can be switched at any hand-off)" "$(pack_default "$proot" harness)"
  fi
  [ "$HARNESS_PACKS" = none ] && HARNESS_PACKS=""
  [ "$LANG_PACK" = none ] && LANG_PACK=""
  [ "$DOCS_PACK" = none ] && DOCS_PACK=""
}
setup_summary() {
  q_say ""; q_say "Summary:"
  q_say "  name        $NAME"; q_say "  title       $TITLE"; q_say "  prefix      $PREFIX   (first commit: ${PREFIX}-BOOTSTRAP-0001)"
  q_say "  visibility  $VISIBILITY"; q_say "  language    ${LANG_PACK:-none}"; q_say "  docs        ${DOCS_PACK:-none}"; q_say "  harness     ${HARNESS_PACKS:-none}"
  q_say ""
}
