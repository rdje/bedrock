#!/usr/bin/env bash
# TASK-ACCEPTANCE — the leaf that owns a governed change carries, IN THIS CHANGE, a ticked checklist
# whose three hard-gated boxes each hold tool output inside their own bullet.
# SPDX-License-Identifier: LGPL-2.1-or-later
#
# ⭐ THE DISCIPLINE, stated with no project's nouns: a change lands with (a) the CAUSE located,
# (b) the EFFECT measured, and (c) a statement that nothing regressed — each backed by output from
# a tool that was actually run, not by prose. "I fixed it" is a claim; a pasted verdict is an
# artifact someone else can re-run.
#
# THE CONTRACT (decision_ownership_contract, REVIEW-2026-09.4), on top of TASK-TREE-OWNERSHIP's binding:
#   • LABELS ARE ANCHORED: a box is `- [x] **ROOT CAUSE…`, `- [x] **ADDRESSED…`, `- [x] **NO REGRESSION…`
#     with the label at the START of the bold text; exactly one per label in the leaf's section.
#     (Matching a keyword anywhere in a box let a `**FIX** — addressed by…` line stand in for an
#     unticked ADDRESSED box, BK-03.)
#   • EVIDENCE IS NEW IN THIS CHANGE: each box's bullet — the box line and its indented continuation
#     lines — gains at least one line here. Yesterday's evidence answers for nothing (BK-01).
#   • EVIDENCE IS TOOL OUTPUT IN A CODE SPAN: a result signature must sit INSIDE backticks (or a fenced
#     block) in the bullet — `rc=0`, `exit 1`, `12 passed / 0 failed`, a declared token — never in
#     prose. A bare version number or a bare tool name is not evidence (BK-03, NT-04). The
#     tool-neutral shape is the line `scripts/evidence -- <command>` prints: `evidence: rc=N cmd="…"`.
#   • Box-scoping stays the soundness property: the signature must sit in the SAME bullet.
#
# ⚠️ HONEST LIMIT: this proves a re-runnable artifact was cited in this change, not that it is true.
#    The un-fakeable leg is re-running `evidence:` lines in CI.
#
# ── PROJECT SEAMS (.doctrine/, read as of the LAST commit) ─────────────────────────────────────
#   docs_paths.txt        extra DOCUMENTATION patterns (exempt from governance), one ERE per line
#   evidence_tokens.txt   your tools' result signatures, one ERE per line, ADDED to the defaults
# Message-time check, like TASK-TREE-OWNERSHIP: NOT EVALUATED without a message.
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib/spine.sh"; spine_init TASK-ACCEPTANCE
T="$(spine_tmp)"

spine_load_docs_re
spine_governed_paths > "$T/governed.txt"
[ -s "$T/governed.txt" ] || { spine_ok "OK — no governed path in this change"; exit 0; }
[ -n "${SPINE_COMMIT_MSG:-}" ] || { spine_ok "NOT EVALUATED — needs the commit message (the commit-msg hook and CI supply it)"; exit 0; }
[ "${SPINE_MERGE:-0}" = 1 ] && { spine_ok "OK — merge commit: binding exempt"; exit 0; }
exception="$(spine_msg_exception "$SPINE_COMMIT_MSG")"
[ -z "$exception" ] || { spine_ok "EXCEPTION — no leaf judged: Spine-Exception: $exception"; exit 0; }

leaf="$(spine_msg_leaf "$SPINE_COMMIT_MSG")"
[ -n "$leaf" ] || { spine_fail "the subject names no leaf; see TASK-TREE-OWNERSHIP"; exit 1; }
tree="${leaf%%.*}"; file="docs/tasks/$tree.md"
spine_read "$file" > "$T/after.md" || { spine_fail "$file is not in this change's snapshot; see TASK-TREE-OWNERSHIP"; exit 1; }
bounds="$(spine_leaf_bounds "$T/after.md" "$leaf")"
[ -n "$bounds" ] || { spine_fail "$file has no section for leaf $leaf; see TASK-TREE-OWNERSHIP"; exit 1; }
start="${bounds% *}"; end="${bounds#* }"
spine_added_lines "$file" | sort -un > "$T/added.nums"

# ── result signatures: what a tool PRINTS, never what it is called ───────────────────────────
DEFAULT_SIG='\brc=[0-9]+|\bexit(ed)?[ =:](code )?[0-9]+|[0-9]+ (pass|passed|ok)[ ,/]+[0-9]+ (fail|failed)|test result: (ok|FAILED)|running [0-9]+ tests?|error\[E[0-9]{4}\]|could not compile|clippy::[a-z_]{3,}|panicked at|assertion (failed|`)|\bE2BIG\b|\bENOSPC\b|\bEACCES\b|\bARG_MAX\b|PIPESTATUS|^evidence: rc='
SIG="$DEFAULT_SIG"
lines="$(spine_config_file evidence_tokens.txt)"
if [ -n "$lines" ]; then
  if ! spine_re_from_lines "$lines"; then
    if [ -z "$(spine_touched_paths | grep -vE '^\.doctrine/|\.md$' || true)" ]; then
      lines="$(spine_read .doctrine/evidence_tokens.txt | grep -vE '^[[:space:]]*(#|$)' || true)"
      spine_re_from_lines "$lines" || spine_refuse ".doctrine/evidence_tokens.txt still holds an invalid regular expression ('$SPINE_BAD_RE')"
    else
      spine_refuse ".doctrine/evidence_tokens.txt as of the last commit holds an invalid regular expression ('$SPINE_BAD_RE'); repair it in a change that touches only .doctrine/ and documentation"
    fi
  fi
  [ -z "$SPINE_RE" ] || SIG="$SIG|$SPINE_RE"
fi

# the leaf's section, with absolute line numbers
sed -n "${start},${end}p" "$T/after.md" | awk -v s="$start" '{ printf "%d\t%s\n", NR+s-1, $0 }' > "$T/section.tsv"

fail=0
for label in 'ROOT CAUSE' 'ADDRESSED' 'NO REGRESSION'; do
  # the box lines carrying this label at the START of the bold text
  awk -F'\t' -v L="$label" '$2 ~ ("^[[:space:]]*-[[:space:]]*\\[[xX ]\\][[:space:]]*\\*\\*" L) { print $1 }' "$T/section.tsv" > "$T/boxes.nums"
  n="$(wc -l < "$T/boxes.nums" | tr -d ' ')"
  if [ "$n" -eq 0 ]; then spine_fail "leaf $leaf has no '$label' box (a box is '- [x] **${label}…**', label first)"; fail=1; continue; fi
  if [ "$n" -gt 1 ]; then spine_fail "leaf $leaf has $n '$label' boxes — exactly one per label"; fail=1; continue; fi
  box="$(cat "$T/boxes.nums")"
  # the bullet: the box line plus its indented / blank continuation lines, up to the next flush line
  awk -F'\t' -v b="$box" '
    $1 == b { print; inb = 1; next }
    inb { if ($2 ~ /^[[:space:]]+[^[:space:]]/ && $2 !~ /^[[:space:]]*-[[:space:]]*\[[xX ]\]/) print; else if ($2 ~ /^[[:space:]]*$/) print; else exit }
  ' "$T/section.tsv" > "$T/bullet.tsv"
  if ! sed -n "${box}p" "$T/after.md" | grep -qE '\[[xX]\]'; then
    spine_fail "leaf $leaf — the '$label' box is present but NOT ticked"; fail=1; continue
  fi
  # fresh: at least one bullet line is added in this change
  if ! awk -F'\t' 'NR==FNR { a[$1]=1; next } ($1 in a) { f=1 } END { exit (f ? 0 : 1) }' "$T/added.nums" "$T/bullet.tsv"; then
    spine_fail "leaf $leaf — the '$label' box carries no line added in this change: evidence must be NEW here, not inherited from an earlier commit"; fail=1; continue
  fi
  # evidence: a result signature INSIDE a code span (or a fenced block) of the bullet.
  # ⛔ The bullet is FLATTENED first: Markdown lets an inline code span wrap onto the next line, and
  #    a per-line scan then sees an unclosed backtick, loses the span and shifts the parity of every
  #    span after it — measured on this repository's own leaf `.3`, whose wrapped
  #    `arms: … (of 37)` span hid the `rc=0` beside it.
  cut -f2- "$T/bullet.tsv" | awk '
    /^[[:space:]]*```/ { fence = !fence; next }
    fence { print; next }
    { line = $0; sub(/^[[:space:]]+/, "", line); s = s (s == "" ? "" : " ") line }
    END { while (match(s, /`[^`]+`/)) { print substr(s, RSTART+1, RLENGTH-2); s = substr(s, RSTART+RLENGTH) } }
  ' > "$T/spans.txt"
  if ! grep -qE "$SIG" "$T/spans.txt"; then
    {
      echo "TASK-ACCEPTANCE: leaf $leaf — the '$label' box is ticked but no tool output sits INSIDE a code span of its bullet."
      echo "  A tick is a claim. Cite the command and its result in backticks, e.g. \`scripts/gate\` → \`=== all doctrines green ===\` (\`rc=0\`),"
      echo "  or paste the line \`scripts/evidence -- <command>\` prints. Prose, a version number or a tool's name is not evidence."
      echo "  Declare your own tools' result shapes in .doctrine/evidence_tokens.txt (one extended regular expression per line)."
    } >&2
    fail=1
  fi
done

[ "$fail" -eq 0 ] || exit 1
spine_ok "OK — leaf $leaf: three boxes ticked, each with new tool output in its own bullet"
exit 0
