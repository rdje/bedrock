#!/usr/bin/env bash
# RESUME-POINTER — the resume pointer (MEMORY.md, layer A) is TRUE for the commit being made.
# SPDX-License-Identifier: LGPL-2.1-or-later
#
# THE GUARANTEE (docs/decisions/decision_context_continuity.md): a fresh agent, in any harness,
# after any session end, resumes from the repository alone by reading MEMORY.md. That only holds if
# the pointer is true at HEAD, and until now no gate checked it: a `latest_commit` that names an
# older commit, or a frontier leaf that no longer exists, is exactly how a resumed session starts
# wrong — invisibly.
#
# THE RULE, judged with the message (commit-msg hook, and CI per commit):
#   1. `next_action:` is present and not a placeholder.
#   2. `active_work_unit:` names at least one tree that exists in this snapshot; every leaf it names
#      exists; the LAST leaf it names — the frontier — is not `done`.
#   3. When this change is GOVERNED (it touches more than documentation), `latest_commit:` names THIS
#      commit's work-unit id (the subject's first token, e.g. `PROJ-AREA-0007`). A documentation-only
#      commit may leave the pointer as it is.
# A merge commit is exempt. Without a message the check says NOT EVALUATED.
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib/spine.sh"; spine_init RESUME-POINTER
T="$(spine_tmp)"

spine_read MEMORY.md > "$T/mem" || { spine_fail "MEMORY.md (the resume pointer) is missing"; exit 1; }
fail=0

next="$(spine_pointer_field "$T/mem" next_action)"
if [ -z "$next" ] || printf '%s' "$next" | grep -qiE '_none yet_|^<|^$'; then
  spine_fail "MEMORY.md: 'next_action:' is empty or a placeholder — the pointer must say what is next"; fail=1
fi

awu="$(spine_pointer_field "$T/mem" active_work_unit)"
if [ -z "$awu" ]; then
  spine_fail "MEMORY.md: 'active_work_unit:' is missing"; fail=1
else
  spine_pointer_refs "$awu" > "$T/refs"
  grep -q '^tree ' "$T/refs" || { spine_fail "MEMORY.md: 'active_work_unit:' names no tree that exists under docs/tasks/ — got: $awu"; fail=1; }
  while read -r kind id st; do
    [ "$kind" = leaf ] || continue
    [ "$st" != missing ] || { spine_fail "MEMORY.md: 'active_work_unit:' names leaf $id, which does not exist in its tree"; fail=1; }
  done < "$T/refs"
  last="$(grep '^leaf ' "$T/refs" | tail -1)"
  if [ -n "$last" ]; then
    set -- $last
    [ "$3" != done ] || { spine_fail "MEMORY.md: the frontier leaf $2 is already \`done\` — point at the next open leaf"; fail=1; }
  fi
fi

if [ -n "${SPINE_COMMIT_MSG:-}" ] && [ "${SPINE_MERGE:-0}" != 1 ]; then
  spine_load_docs_re
  if [ -n "$(spine_governed_paths)" ]; then
    id="$(spine_subject_id "$(spine_msg_subject "$SPINE_COMMIT_MSG")")"
    latest="$(spine_pointer_field "$T/mem" latest_commit)"
    if [ -n "$id" ] && ! printf '%s' "$latest" | grep -qF "$id"; then
      spine_fail "MEMORY.md: 'latest_commit:' must name THIS commit ($id) when the change is governed — got: ${latest:-<empty>}"
      spine_fail "  Overwrite the current-state block in the same commit (COMMIT.md step 3); a stale pointer is a wrong resume."
      fail=1
    fi
  fi
elif [ -z "${SPINE_COMMIT_MSG:-}" ]; then
  [ "$fail" -eq 0 ] && { spine_ok "NOT EVALUATED — the latest_commit rule needs the message (structure holds: $(grep -c '^tree ' "$T/refs" 2>/dev/null || echo 0) tree(s) named)"; exit 0; }
fi

[ "$fail" -eq 0 ] || exit 1
spine_ok "OK — pointer true: $(grep '^tree ' "$T/refs" | awk '{printf "%s ", $2}')frontier $(grep '^leaf ' "$T/refs" | tail -1 | awk '{print $2 " (" $3 ")"}')"
exit 0
