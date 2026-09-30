#!/usr/bin/env bash
# scripts/tests/spine_tests.sh — THE SPINE CONFORMANCE SUITE (REVIEW-2026-09.2).
# SPDX-License-Identifier: LGPL-2.1-or-later
#
# Builds a child project from the working tree exactly the way a user would (a one-commit copy,
# `bootstrap.sh demo`, the printed first commit), then runs every scenario of the consolidated
# review (docs/reviews/2026-09-30-consolidated-review.md §9–§10) as an arm with an EXPECTED
# outcome. A RED arm must be REFUSED for the stated reason; a GREEN control must pass.
#
# ⭐ AN ARM THE SPINE DOES NOT YET SATISFY IS REGISTERED AS `xfail`, NOT DELETED. The run stays
#   green while it fails as expected, and turns RED the moment it starts passing (`XPASS`), so the
#   leaf that fixes it has to move it to `req` in the same commit. The list of `xfail` arms IS the
#   open backlog of the review, kept honest by execution rather than by memory.
#
# ⛔ PORTABILITY: bash 3.2 (stock macOS), POSIX awk/sed/grep, git. No python, no GNU-only flags.
#
# Usage:  scripts/tests/spine_tests.sh [--list] [--only <arm>] [--keep]
#   --list   print the arms and their expectation, run nothing
#   --only   run one arm (by name); its child is kept and its path printed
#   --keep   keep every scenario child (default: removed)
# Exit:    0 = every req arm passed and every xfail arm failed; 1 = a FAIL or an XPASS; 2 = cannot run
set -uo pipefail

SUITE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)" || exit 2
cd "$SUITE_ROOT" || exit 2

ONLY=""; KEEP=0; LIST=0
while [ $# -gt 0 ]; do
  case "$1" in
    --list) LIST=1 ;;
    --only) shift; ONLY="${1:-}"; KEEP=1 ;;
    --keep) KEEP=1 ;;
    -h|--help) sed -n '2,24p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "spine_tests: unknown argument '$1'" >&2; exit 2 ;;
  esac
  shift
done

# ── the registry: name · expectation · review id ────────────────────────────────────────────
# expectation: req = must behave as required today; xfail = known open item (must NOT behave yet)
ARMS="
docs_only_change_passes                 req    GREEN
owned_change_with_fresh_evidence_passes req    GREEN
bootstrap_first_commit_as_printed       req    BR-11
bootstrap_bad_names_refused             req    BK-04
bootstrap_no_name_uninitialised_exit2   req    BK-18
bootstrap_under_bsd_sed                 req    BR-10
ownership_dart_perl_julia_no_leaf       req    NT-03
spine_hook_and_workflow_no_leaf         req    BK-05
deletion_needs_leaf                     req    BR-08
evidence_reuse_done_leaf                req    BK-01
prose_evidence_refused                  req    BK-03
keyword_box_shadowing_refused           req    BK-03
bare_version_number_not_evidence        req    BK-03
stamped_evidence_line_accepted          req    NT-04
config_weakened_same_commit             req    BK-06
env_bypass_ignored                      req    BK-08
exception_trailer_honoured              req    BK-08
subdir_markdown_not_a_leaf              req    BK-15
spine_docs_deleted                      req    BK-13
child_without_claude_md_passes          req    NT-08
project_slot_not_executable             req    BK-14
git_failure_refused                     req    BK-17
unstaged_fix_hides_staged_defect        req    BR-03
ci_judges_each_commit                   req    BR-04
commit_msg_human_named_claude           req    BK-11
commit_msg_agent_co_developed_by        req    BK-11
commit_msg_leading_blank_line           req    BK-11
knowledge_map_single_line_comment       req    BK-12
census_make_sure_not_a_discharge        req    BK-16
waiver_owner_must_resolve               req    BK-16
scratch_stays_out_of_worktree           req    NT-07
rename_needs_leaf                       req    BR-08
no_python3_gate_green                   req    NT-12
invalid_regex_refused                   req    BR-05
invalid_regex_repair_allowed            req    BR-05
ci_message_judged                       req    BR-21
subject_hello_refused                   req    BR-21
second_commit_reusing_evidence_refused  req    BK-01
open_leaf_owns_two_commits              req    BK-01
done_leaf_child_leaf_passes             req    BK-01
duplicate_label_refused                 req    BK-03
docs_paths_declared_exempt              req    NT-03
spine_path_cannot_be_exempted           req    BK-05
code_paths_txt_retired                  req    BK-07
merge_commit_exempt_from_binding        req    BR-04
exception_counted_in_ci                 req    BK-08
resume_pointer_stale_refused            req    CONTINUITY
resume_pointer_missing_leaf_refused     req    CONTINUITY
docs_only_commit_keeps_pointer          req    CONTINUITY
handoff_refuses_dirty_tree              req    CONTINUITY
handoff_refuses_stale_pointer           req    CONTINUITY
handoff_refuses_running_job             req    CONTINUITY
handoff_ok_then_resume_from_fresh_clone req    CONTINUITY
bootstrap_rerun_same_name_idempotent    req    BR-12
bootstrap_rerun_other_name_refused      req    BR-12
bootstrap_dirty_tree_refused            req    BR-06
bootstrap_contributor_mode              req    BK-18
bootstrap_identity_and_history_reset    req    BR-12
bootstrap_evidence_truthful             req    BK-04
bootstrap_fresh_git_init_allowed        req    BR-06
updater_child_0_4_0_upgrades            req    BK-09
updater_child_0_6_1_upgrades            req    BK-10
updater_never_overwrites_modified       req    BR-01
updater_self_replaces                   req    BK-09
updater_refuses_dirty_tree              req    BR-01
updater_refuses_downgrade               req    BR-09
updater_plan_writes_nothing             req    BR-01
updater_same_version_is_noop_commitable req    BK-10
waiver_owner_real_leaf_passes           req    BK-16
waiver_historical_not_rejudged          req    BR-17
lesson_decline_per_lesson               req    BR-18
lesson_promoted_via_knowledge           req    BR-18
knowledge_map_shows_tree_status         req    BK-12
child_no_packs_bootstraps_and_gates     req    NT-01
unselected_packs_not_copied             req    NT-01
rust_pack_child_runs_check              req    NT-05
run_refuses_undeclared_verb             req    NT-05
harness_adapters_point_to_agents        req    NT-08
mdbook_pack_child                       req    NT-06
wizard_answers_piped                    req    SETUP
wizard_invalid_answer_reasked           req    SETUP
wizard_decline_writes_nothing           req    SETUP
new_project_local                       req    SETUP
add_pack_later                          req    NT-01
bedrock_itself_green_in_ci_mode         req    NT-14
child_carries_no_book                   req    BOOK
book_coverage_refuses_dropped_doctrine  req    BOOK
ci_range_respects_contract_epoch        req    BR-04
"

# ⛔ THE SUITE IS THE TEMPLATE'S TEST: every arm builds a child from a PRISTINE copy of bedrock (its
#   maintainer files, its packs). In a project created from bedrock neither exists, so the suite does not
#   apply there — it says so and exits 0 rather than fail for a reason that is not a defect. A project
#   proves its own spine with `scripts/gate`, each check's `--self-test`, and the probe drivers.
if [ ! -f MAINTAINING.md ] || [ ! -d packs ]; then
  printf 'spine_tests: NOT APPLICABLE — this is a project created from bedrock, not the template; the conformance suite builds children from the pristine template. Run scripts/gate here.\n'
  exit 0
fi

if [ "$LIST" = 1 ]; then
  printf '%s\n' "$ARMS" | awk 'NF==3 { printf "  %-40s %-6s %s\n", $1, $2, $3 }'
  exit 0
fi

WORK="$(mktemp -d)"; export WORK
[ "$KEEP" = 1 ] || trap 'rm -rf "$WORK"' EXIT
BASE="$WORK/base"

note() { printf 'spine_tests: %s\n' "$*" >&2; }

# ── build the base child once: a one-commit copy of the WORKING TREE, bootstrapped, committed ──
build_base() {
  mkdir -p "$BASE"
  # tracked + untracked-but-not-ignored, so a change under test is part of the child
  git ls-files -co --exclude-standard -z | tar --null -T - -cf - | tar -x -C "$BASE" || return 1
  ( cd "$BASE" \
    && git init -q -b main . \
    && git config user.email t@example.invalid && git config user.name tester \
    && git config core.hooksPath .githooks \
    && chmod +x scripts/*.sh knowledge-map/scripts/*.sh .githooks/* 2>/dev/null \
    && git add -A && git -c core.hooksPath=/dev/null commit -qm "Initial commit" \
    && ./scripts/bootstrap.sh demo --lang rust --harness claude --yes > "$WORK/bootstrap.log" 2>&1 \
    && git add -A \
    && printf '%s\n' 'DEMO-BOOTSTRAP-0001 (leaf BOOTSTRAP.1): bootstrapped from bedrock' > git_message_brief.txt \
    && git commit -q -F git_message_brief.txt > "$WORK/first_commit.log" 2>&1 \
    && : > git_message_brief.txt )
}

# ── helpers available to every arm (cwd = the arm's own child, $T) ─────────────────────────
OUT=""; RC=0
regen_map() { # what the pre-commit hook does before the driver runs, so `gate` judges the same tree
  if [ -x knowledge-map/scripts/gen_knowledge_map.sh ]; then
    m="$(knowledge-map/scripts/gen_knowledge_map.sh --print-map-path)"
    knowledge-map/scripts/gen_knowledge_map.sh > "$m" 2>/dev/null && git add "$m" 2>/dev/null
  fi
}
gate()   { # [subject] — judges the index WITH a message, as the commit-msg hook does (binding is message-time)
  regen_map; printf '%s\n' "${1:-DEMO-APP-0002: an unowned change}" > "$T/.subject"
  OUT="$(bash scripts/check_doctrines.sh --message "$T/.subject" 2>&1)"; RC=$?; }
gate_ci() { OUT="$(bash scripts/check_doctrines.sh --commit "${1:-HEAD}" 2>&1)"; RC=$?; }
commit_hooks() { # $1 = message (may be multi-line); commits through the real hooks
  printf '%s\n' "$1" > "$T/.msg"; OUT="$(git commit -q -F "$T/.msg" 2>&1)"; RC=$?; rm -f "$T/.msg"
}
commit_nohooks() { printf '%s\n' "$1" > "$T/.msg"; git -c core.hooksPath=/dev/null commit -q -F "$T/.msg" >/dev/null 2>&1; rc=$?; rm -f "$T/.msg"; return $rc; }
has() { printf '%s\n' "$OUT" | grep -qF -- "$1"; }
# ⛔ The driver names EVERY check on its ✅ line, so "the output mentions X" is always true.
#    A refusal BY X is the ❌ / ?? / REFUSED line that carries X — nothing looser.
refused_by() { [ "$RC" -ne 0 ] && printf '%s\n' "$OUT" | grep -qE "(❌|\?\?|REFUSED)[[:space:]]+$1([[:space:]]|:|$)"; }
green() { [ "$RC" -eq 0 ]; }
edit_line() { # file · exact old line · new line (portable, no sed -i)
  awk -v o="$2" -v n="$3" '$0==o { $0=n } { print }' "$1" > "$1.tmp" && mv "$1.tmp" "$1"
}
code_change() { printf 'fn main() { println!("changed"); }\n' > crates/app/src/main.rs; }
point_to() { # $1 = work-unit id [, $2 = active_work_unit text]: make MEMORY.md true for the commit about to be made
  awk -v id="$1" -v awu="${2:-}" '
    /^- latest_commit:/ { print "- latest_commit: `" id "`."; next }
    /^- active_work_unit:/ && awu != "" { print "- active_work_unit: " awu; next }
    { print }' MEMORY.md > "$T/.mem" && mv "$T/.mem" MEMORY.md && git add MEMORY.md
}
good_leaf() { # $1 = tree id (default FEAT); a correctly evidenced, new-shape leaf
  local t="${1:-FEAT}"
  cat <<LEAF
# $t: a feature

## Task Tree

- ID: \`$t\`
  Status: \`active\`
  Goal: the feature
  Children: \`.1\`

- ID: \`$t.1\`
  Status: \`active\`
  Goal: rewrite main

  ### Acceptance Checklist

  - [x] **ROOT CAUSE (WHY + WHERE)** — \`cargo test\` → \`test result: FAILED. 0 passed; 1 failed\` (\`rc=101\`) at \`crates/app/src/main.rs:1\`.
  - [x] **ADDRESSED (verified)** — after: \`cargo test\` → \`test result: ok. 1 passed; 0 failed\` (\`rc=0\`).
  - [x] **NO REGRESSION** — \`scripts/check_doctrines.sh\` → \`=== all doctrines green ===\` (\`rc=0\`).

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| \`$t.1\` | \`DEMO-APP-0002 (leaf $t.1): rewrite main\` | — |
LEAF
}
boxes_leaf() { # $1 = tree id · then three box bodies on stdin (one per line)
  local t="$1" rc ad nr
  IFS= read -r rc; IFS= read -r ad; IFS= read -r nr
  cat <<LEAF
# $t: a feature

## Task Tree

- ID: \`$t.1\`
  Status: \`active\`
  Goal: a change

  ### Acceptance Checklist

  - [x] **ROOT CAUSE (WHY + WHERE)** — $rc
  - [x] **ADDRESSED (verified)** — $ad
  - [x] **NO REGRESSION** — $nr
LEAF
}

# ── the arms: return 0 when the spine behaves AS REQUIRED, 1 when it does not ──────────────
arm_docs_only_change_passes() {
  printf '\nA README line.\n' >> README.md; git add README.md; gate; green
}
arm_owned_change_with_fresh_evidence_passes() {
  code_change; good_leaf > docs/tasks/FEAT.md; point_to DEMO-APP-0002 '`FEAT` → frontier leaf `FEAT.1` (`active`)'; git add -A
  commit_hooks 'DEMO-APP-0002 (leaf FEAT.1): rewrite main'; green
}
fresh_copy() { # rebuild $T as a fresh, un-bootstrapped one-commit copy of the template (GitHub's "Use this template")
  rm -rf "$T"; mkdir -p "$T"
  ( cd "$SUITE_ROOT" && git ls-files -co --exclude-standard -z | tar --null -T - -cf - | tar -x -C "$T" )
  cd "$T" && git init -q -b main . && git config user.email t@example.invalid && git config user.name tester \
    && chmod +x scripts/*.sh knowledge-map/scripts/*.sh .githooks/* 2>/dev/null \
    && git add -A && git -c core.hooksPath=/dev/null commit -qm "Initial commit"
}
arm_bootstrap_first_commit_as_printed() {
  # a fresh, un-bootstrapped copy; run bootstrap; execute the printed commit block verbatim
  fresh_copy || return 1
  ./scripts/bootstrap.sh demo --yes > "$T/.boot.log" 2>&1 || return 1
  # the printed block: the lines between "Commit the bootstrap itself" and the next blank line
  printed="$(awk '/Commit the bootstrap itself/ { on=1; next } on && /^[[:space:]]*$/ { exit } on && /^[[:space:]]+(git|printf)/ { print }' "$T/.boot.log")"
  [ -n "$printed" ] || return 1
  OUT="$(bash -c "$printed" 2>&1)"; RC=$?
  green && git log -1 --format=%s | grep -qE '^[A-Z][A-Z0-9_]*-BOOTSTRAP-0001 '
}
arm_bootstrap_bad_names_refused() {
  local n ok=0
  for n in 'x&y' 'a/b' 'my.proj' 'Stitch CAD'; do
    fresh_copy >/dev/null 2>&1 || return 1
    before="$(git status --porcelain | wc -l | tr -d ' ')"
    ./scripts/bootstrap.sh "$n" --yes >/dev/null 2>&1; rc=$?
    after="$(git status --porcelain | wc -l | tr -d ' ')"
    # refused with exit 2 and NOTHING written
    if [ "$rc" -eq 2 ] && [ "$after" = "$before" ]; then ok=$((ok+1)); fi
  done
  [ "$ok" -eq 4 ]
}
arm_bootstrap_no_name_uninitialised_exit2() {
  fresh_copy >/dev/null 2>&1 || return 1
  ./scripts/bootstrap.sh >/dev/null 2>&1; rc=$?
  [ "$rc" -eq 2 ] && [ -f MAINTAINING.md ]
}
arm_bootstrap_under_bsd_sed() {
  # meaningful only where a BSD sed exists at /usr/bin/sed; elsewhere the arm is vacuously required
  if /usr/bin/sed --version >/dev/null 2>&1; then return 0; fi   # GNU sed there: nothing to test
  [ -x /usr/bin/sed ] || return 0
  fresh_copy >/dev/null 2>&1 || return 1
  PATH="/usr/bin:/bin:/usr/sbin:/sbin" ./scripts/bootstrap.sh demo --lang rust --yes > "$T/.boot.log" 2>&1; rc=$?
  [ "$rc" -eq 0 ] && grep -q '^name = "demo"' crates/app/Cargo.toml && ! ls docs/TASK_TREE.md-e >/dev/null 2>&1 \
    && printf '%s\n' 'DEMO-BOOTSTRAP-0001 (leaf BOOTSTRAP.1): bootstrapped from bedrock' > "$T/.m" \
    && PATH="/usr/bin:/bin:/usr/sbin:/sbin" git commit -q -F "$T/.m" >/dev/null 2>&1
}
arm_ownership_dart_perl_julia_no_leaf() {
  mkdir -p lib t test bin
  printf 'void main() {}\n' > lib/app.dart; printf 'package Foo; 1;\n' > lib/Foo.pm
  printf 'use Test::More; ok(1); done_testing;\n' > t/basic.t
  printf 'using Test\n@test true\n' > test/runtests.jl; printf 'print "hi\\n";\n' > bin/tool.pl
  git add -A; gate; refused_by 'TASK-TREE-OWNERSHIP'
}
arm_spine_hook_and_workflow_no_leaf() {
  printf '#!/usr/bin/env bash\nexit 0\n' > .githooks/pre-commit
  git rm -q .github/workflows/doctrines.yml; git add -A; gate; refused_by 'TASK-TREE-OWNERSHIP'
}
arm_deletion_needs_leaf() {
  git rm -q crates/app/src/main.rs; gate; refused_by 'TASK-TREE-OWNERSHIP'
}
arm_evidence_reuse_done_leaf() {
  printf 'fn main() { std::process::exit(3); }\n' > crates/app/src/main.rs
  edit_line docs/tasks/BOOTSTRAP.md '- Owner: repo-local workflow' '- Owner: repo-local workflow '
  git add crates/app/src/main.rs docs/tasks/BOOTSTRAP.md
  commit_hooks 'DEMO-APP-0002 (leaf BOOTSTRAP.1): rewrite main'
  refused_by 'TASK-ACCEPTANCE'
}
arm_prose_evidence_refused() {
  code_change
  printf '%s\n' 'I believe it is the parser, see section 1.2.3.' 'should exit 0 now.' 'will run cargo test later.' \
    | boxes_leaf FEAT > docs/tasks/FEAT.md
  git add -A; commit_hooks 'DEMO-APP-0002 (leaf FEAT.1): x'; refused_by 'TASK-ACCEPTANCE'
}
arm_keyword_box_shadowing_refused() {
  code_change
  cat > docs/tasks/FEAT.md <<'L'
# FEAT

- ID: `FEAT.1`
  Status: `active`
  Goal: a change

  ### Acceptance Checklist

  - [x] **ROOT CAUSE (WHY + WHERE)** — `cargo test` → `test result: FAILED` (`rc=101`) at `crates/app/src/main.rs:1`.
  - [x] **FIX** — addressed by rewriting main (`rc=0`).
  - [ ] **ADDRESSED (verified)** — TODO
  - [x] **NO REGRESSION** — `cargo test` → `test result: ok`.
L
  git add -A; commit_hooks 'DEMO-APP-0002 (leaf FEAT.1): x'; refused_by 'TASK-ACCEPTANCE'
}
arm_bare_version_number_not_evidence() {
  code_change
  printf '%s\n' 'Julia 1.10.4 is installed.' 'now on Julia 1.10.4.' 'still Julia 1.10.4.' \
    | boxes_leaf FEAT > docs/tasks/FEAT.md
  git add -A; commit_hooks 'DEMO-APP-0002 (leaf FEAT.1): x'; refused_by 'TASK-ACCEPTANCE'
}
arm_stamped_evidence_line_accepted() {
  # the tool-neutral evidence shape: a line the wrapper prints, pasted into each box
  [ -x scripts/evidence ] || return 1
  scripts/evidence -- sh -c 'echo ok' > "$T/.ev" 2>/dev/null; line="$(head -1 "$T/.ev")"
  printf '%s\n' "$line" | grep -q '^evidence: rc=0 ' || return 1
  code_change
  printf '%s\n' "$line" "$line" "$line" | sed 's/^/`/; s/$/`/' | boxes_leaf FEAT > docs/tasks/FEAT.md
  point_to DEMO-APP-0002 '`FEAT` → frontier leaf `FEAT.1` (`active`)'; git add -A; commit_hooks 'DEMO-APP-0002 (leaf FEAT.1): x'; green
}
arm_config_weakened_same_commit() {
  printf '^nothing-matches-this$\n' > .doctrine/code_paths.txt
  printf 'echo hi\n' > scripts/new_tool.sh
  git add -A; gate; refused_by 'TASK-TREE-OWNERSHIP' || refused_by 'TASK-ACCEPTANCE'
}
arm_env_bypass_ignored() {
  code_change; git add -A; printf 'DEMO-APP-0002: unowned\n' > "$T/.subject"
  OUT="$(SPINE_ALLOW_UNOWNED=1 SPINE_COMMIT_MSG="$T/.subject" bash scripts/check_task_tree_ownership.sh 2>&1)"; RC=$?
  [ "$RC" -ne 0 ]
}
arm_exception_trailer_honoured() {
  code_change; point_to DEMO-APP-0002; git add -A
  commit_hooks 'DEMO-APP-0002: vendored change

Spine-Exception: vendored third-party sources, no leaf applies'
  green
}
arm_subdir_markdown_not_a_leaf() {
  mkdir -p docs/tasks/artifacts/perf; printf '# perf notes\n' > docs/tasks/artifacts/perf/README.md
  code_change; good_leaf > docs/tasks/FEAT.md; point_to DEMO-APP-0002 '`FEAT` → frontier leaf `FEAT.1` (`active`)'; git add -A
  commit_hooks 'DEMO-APP-0002 (leaf FEAT.1): rewrite main'; green
}
arm_spine_docs_deleted() {
  git rm -q MEMORY_ARCHITECTURE.md AGENTS.md DOCTRINE_ENFORCEMENT.md TOOLBOX.md COMMIT.md
  gate; refused_by 'MEMORY-ARCH'
}
arm_child_without_claude_md_passes() {
  git rm -q CLAUDE.md; gate; green
}
arm_project_slot_not_executable() {
  printf '#!/usr/bin/env bash\necho "PROJECT: always fails" >&2\nexit 1\n' > scripts/check_doctrines.project.sh
  chmod -x scripts/check_doctrines.project.sh
  gate; refused_by 'PROJECT-SPECIFIC'
}
arm_git_failure_refused() {
  code_change; git add -A
  OUT="$(GIT_DIR="$T/no-such-dir" bash scripts/check_doctrines.sh 2>&1)"; RC=$?
  [ "$RC" -ne 0 ] && has 'REFUSED'
}
arm_unstaged_fix_hides_staged_defect() {
  printf '# FEAT\n\n- Last updated: 2026-01-01\n' > docs/tasks/FEAT.md; git add docs/tasks/FEAT.md
  printf '# FEAT\n' > docs/tasks/FEAT.md          # the worktree is clean; the INDEX is not
  gate; refused_by 'LIVE-DOC-CURRENCY'
}
arm_ci_judges_each_commit() {
  code_change; git add -A; commit_nohooks 'DEMO-APP-0002: unowned, hooks bypassed' || return 1
  gate_ci HEAD; refused_by 'TASK-TREE-OWNERSHIP'
}
arm_commit_msg_human_named_claude() {
  printf 'DEMO-APP-0003 (leaf X.1): pair session\n\nCo-Authored-By: Claude Martin <claude.martin@example.fr>\n' > "$T/.m"
  bash .githooks/commit-msg "$T/.m" >/dev/null 2>&1
}
arm_commit_msg_agent_co_developed_by() {
  printf 'DEMO-APP-0003: x\n\nCo-Developed-By: Claude <noreply@anthropic.com>\n' > "$T/.m"
  ! bash .githooks/commit-msg "$T/.m" >/dev/null 2>&1
}
arm_commit_msg_leading_blank_line() {
  printf '\nDEMO-APP-0003 (leaf X.1): subject on line 2\n' > "$T/.m"
  bash .githooks/commit-msg "$T/.m" >/dev/null 2>&1
}
arm_knowledge_map_single_line_comment() {
  printf '<!-- curated input -->\n- `crates/demo/` — the CLI entry point.\n<!-- TODO: add the storage layer -->\n- `crates/store/` — persistence.\n- `crates/net/` — networking.\n' > knowledge-map/subsystems.md
  git add knowledge-map/subsystems.md    # the generator reads the INDEX (BR-14), as the hook does
  # ⛔ never `gen | grep -q` under pipefail: grep exits at the first match, the generator takes SIGPIPE
  bash knowledge-map/scripts/gen_knowledge_map.sh > "$T/.map" && grep -q 'crates/demo' "$T/.map"
}
arm_census_make_sure_not_a_discharge() {
  printf '# FEAT\n\n### `.3` — gap\n- **THE GAP** — nothing checks the retry budget; make sure we revisit.\n' > docs/tasks/FEAT.md
  git add -A; ! bash scripts/check_gap_claims.sh >/dev/null 2>&1
}
arm_waiver_owner_must_resolve() {
  printf '# FEAT\n\n- the diagnosis-toolbox signatures do not apply to this V1.2 migration.\n' > docs/tasks/FEAT.md
  git add -A; ! bash scripts/check_waiver_routing.sh >/dev/null 2>&1
}
arm_scratch_stays_out_of_worktree() {
  edit_line .gitignore '/target' '# (target removed: a non-Rust project)'
  git add .gitignore; commit_nohooks 'DEMO-CFG-0002: non-Rust gitignore' || return 1
  printf '\n- a note\n' >> docs/tasks/BOOTSTRAP.md; git add docs/tasks/BOOTSTRAP.md
  bash scripts/check_gap_claims.sh >/dev/null 2>&1
  bash scripts/check_live_doc_currency.sh --self-test >/dev/null 2>&1
  [ -z "$(git status --porcelain --untracked-files=all | grep -v 'docs/tasks/BOOTSTRAP.md')" ]
}

arm_rename_needs_leaf() {
  git mv crates/app/src/main.rs crates/app/src/app.rs; gate; refused_by 'TASK-TREE-OWNERSHIP'
}
arm_no_python3_gate_green() {
  # a PATH with everything the spine needs except python3: no check needs it any more (NT-12)
  mkdir -p "$T/bin"
  for t in bash sh git awk sed grep head tail cut tr wc sort uniq mktemp dirname basename cat diff cmp mv rm mkdir seq paste date ls cp chmod tar env comm; do
    p="$(command -v "$t" 2>/dev/null)"; [ -n "$p" ] && ln -s "$p" "$T/bin/$t"
  done
  printf '\nA README line.\n' >> README.md; git add README.md
  OUT="$(PATH="$T/bin" bash scripts/check_doctrines.sh 2>&1)"; RC=$?
  green && ! has 'python'
}
arm_invalid_regex_refused() {
  mkdir -p .doctrine; printf '[\n' > .doctrine/docs_paths.txt; git add .doctrine/docs_paths.txt
  commit_nohooks 'DEMO-CFG-0003: broken docs paths' || return 1
  code_change; good_leaf > docs/tasks/FEAT.md; git add -A; gate 'DEMO-APP-0002 (leaf FEAT.1): x'; refused_by 'TASK-TREE-OWNERSHIP'
}
arm_invalid_regex_repair_allowed() {
  mkdir -p .doctrine; printf '[\n' > .doctrine/docs_paths.txt; git add .doctrine/docs_paths.txt
  commit_nohooks 'DEMO-CFG-0003: broken docs paths' || return 1
  printf '^docs/site/\n' > .doctrine/docs_paths.txt; good_leaf > docs/tasks/FEAT.md; point_to DEMO-APP-0002 '`FEAT` → frontier leaf `FEAT.1` (`active`)'; git add -A
  gate 'DEMO-APP-0002 (leaf FEAT.1): repair'; green
}
arm_ci_message_judged() {
  # a subject the shape rule rejects, committed with the hooks bypassed: CI must still refuse it
  printf '\nA README line.\n' >> README.md; git add README.md; commit_nohooks '(no id): fix' || return 1
  gate_ci HEAD; refused_by 'COMMIT-MESSAGE'
}
arm_subject_hello_refused() {
  # BR-21: a bare word is not a work-unit id; the permissive rule accepts it until REVIEW-2026-09.4
  printf 'hello\n' > "$T/.m"; ! bash scripts/check_commit_message.sh "$T/.m" >/dev/null 2>&1
}

arm_second_commit_reusing_evidence_refused() {
  code_change; good_leaf > docs/tasks/FEAT.md; point_to DEMO-APP-0002 '`FEAT` → frontier leaf `FEAT.1` (`active`)'; git add -A
  commit_hooks 'DEMO-APP-0002 (leaf FEAT.1): rewrite main' || return 1
  printf 'fn main() { println!("again"); }\n' > crates/app/src/main.rs
  printf '\n- a note outside the leaf\n' >> docs/tasks/FEAT.md          # the file changes, the leaf section does not
  point_to DEMO-APP-0003; git add -A; commit_hooks 'DEMO-APP-0003 (leaf FEAT.1): change again'; refused_by 'TASK-TREE-OWNERSHIP'
}
arm_open_leaf_owns_two_commits() {
  code_change; good_leaf > docs/tasks/FEAT.md; point_to DEMO-APP-0002 '`FEAT` → frontier leaf `FEAT.1` (`active`)'; git add -A
  commit_hooks 'DEMO-APP-0002 (leaf FEAT.1): rewrite main' || return 1
  printf 'fn main() { println!("again"); }\n' > crates/app/src/main.rs; point_to DEMO-APP-0003
  # the second commit adds NEW evidence lines to each box and a commit-log row
  awk '{ print } /\*\*ROOT CAUSE/ { print "    second pass: `cargo test` → `test result: FAILED. 0 passed; 1 failed` (`rc=101`)." }
       /\*\*ADDRESSED/ { print "    second pass: `cargo test` → `test result: ok. 1 passed; 0 failed` (`rc=0`)." }
       /\*\*NO REGRESSION/ { print "    second pass: `scripts/check_doctrines.sh` → `=== all doctrines green ===` (`rc=0`)." }' docs/tasks/FEAT.md > "$T/.f" && mv "$T/.f" docs/tasks/FEAT.md
  git add -A; commit_hooks 'DEMO-APP-0003 (leaf FEAT.1): change again'; green
}
arm_done_leaf_child_leaf_passes() {
  # BOOTSTRAP.1 is done; a follow-up as a child leaf BOOTSTRAP.1.1 with its own evidence is accepted
  code_change
  cat >> docs/tasks/BOOTSTRAP.md <<'L'

- ID: `BOOTSTRAP.1.1`
  Status: `done`
  Goal: a follow-up to the bootstrap

  ### Acceptance Checklist

  - [x] **ROOT CAUSE (WHY + WHERE)** — `cargo test` → `test result: FAILED. 0 passed; 1 failed` (`rc=101`) at `crates/app/src/main.rs:1`.
  - [x] **ADDRESSED (verified)** — `cargo test` → `test result: ok. 1 passed; 0 failed` (`rc=0`).
  - [x] **NO REGRESSION** — `scripts/check_doctrines.sh` → `=== all doctrines green ===` (`rc=0`).
L
  point_to DEMO-APP-0002 '`BOOTSTRAP` → frontier leaf `BOOTSTRAP.1.1` (`done`) — then seed your first real tree'
  awk '{ sub(/\(`done`\) — then/, "— then"); print }' MEMORY.md > "$T/.m" && mv "$T/.m" MEMORY.md
  point_to DEMO-APP-0002 '`BOOTSTRAP` (its leaves are done) — seed your first real tree from `ROADMAP.md`'
  git add -A; commit_hooks 'DEMO-APP-0002 (leaf BOOTSTRAP.1.1): follow-up'; green
}
arm_duplicate_label_refused() {
  code_change
  { good_leaf; printf '  - [x] **ADDRESSED (verified)** — a second one: `cargo test` → `test result: ok` (`rc=0`).\n'; } > docs/tasks/FEAT.md
  # the extra box lands inside the leaf section only if it sits before "## Commit Log"; rebuild accordingly
  awk 'BEGIN{d=0} /^## Commit Log/ && !d { print "  - [x] **ADDRESSED (verified)** — a second one: `cargo test` → `test result: ok` (`rc=0`)."; print ""; d=1 } { print }' <(good_leaf) > docs/tasks/FEAT.md
  git add -A; commit_hooks 'DEMO-APP-0002 (leaf FEAT.1): x'; refused_by 'TASK-ACCEPTANCE'
}
arm_docs_paths_declared_exempt() {
  # a project declares its docs site as documentation: a change there needs no leaf
  mkdir -p .doctrine; printf '^docs/site/\n' > .doctrine/docs_paths.txt; git add .doctrine/docs_paths.txt
  commit_nohooks 'DEMO-CFG-0003: declare the docs site' || return 1
  mkdir -p docs/site; printf '<html></html>\n' > docs/site/index.html; git add -A; gate; green
}
arm_spine_path_cannot_be_exempted() {
  mkdir -p .doctrine; printf '^\\.githooks/\n' > .doctrine/docs_paths.txt; git add .doctrine/docs_paths.txt
  commit_nohooks 'DEMO-CFG-0003: try to exempt the hooks' || return 1
  printf '#!/usr/bin/env bash\nexit 0\n' > .githooks/pre-commit; git add -A; gate; refused_by 'TASK-TREE-OWNERSHIP'
}
arm_code_paths_txt_retired() {
  mkdir -p .doctrine; printf '\\.rs$\n' > .doctrine/code_paths.txt; git add .doctrine/code_paths.txt
  commit_nohooks 'DEMO-CFG-0003: old seam' || return 1
  code_change; good_leaf > docs/tasks/FEAT.md; git add -A; gate 'DEMO-APP-0002 (leaf FEAT.1): x'
  [ "$RC" -ne 0 ] && has 'code_paths.txt is no longer read'
}
arm_merge_commit_exempt_from_binding() {
  git checkout -q -b topic
  code_change; good_leaf > docs/tasks/FEAT.md; point_to DEMO-APP-0002 '`FEAT` → frontier leaf `FEAT.1` (`active`)'; git add -A
  commit_hooks 'DEMO-APP-0002 (leaf FEAT.1): rewrite main' || return 1
  git checkout -q main; printf '\nA README line.\n' >> README.md; git add README.md
  commit_hooks 'DEMO-DOC-0001: a docs line' || return 1
  git merge -q --no-ff -m 'Merge branch topic' topic >/dev/null 2>&1 || return 1
  gate_ci HEAD; green
}
arm_exception_counted_in_ci() {
  base="$(git rev-parse HEAD)"
  code_change; point_to DEMO-APP-0002; git add -A
  commit_hooks 'DEMO-APP-0002: vendored change

Spine-Exception: vendored third-party sources, no leaf applies' || return 1
  OUT="$(bash scripts/check_doctrines.sh --range "$base..HEAD" 2>&1)"; RC=$?
  green && has '1 with a Spine-Exception'
}

arm_resume_pointer_stale_refused() {
  # a governed commit that leaves latest_commit pointing at the previous commit
  code_change; good_leaf > docs/tasks/FEAT.md; git add -A
  commit_hooks 'DEMO-APP-0002 (leaf FEAT.1): rewrite main'; refused_by 'RESUME-POINTER'
}
arm_resume_pointer_missing_leaf_refused() {
  code_change; good_leaf > docs/tasks/FEAT.md; point_to DEMO-APP-0002 '`FEAT` → frontier leaf `FEAT.9` (`pending`)'; git add -A
  commit_hooks 'DEMO-APP-0002 (leaf FEAT.1): rewrite main'; refused_by 'RESUME-POINTER'
}
arm_docs_only_commit_keeps_pointer() {
  # documentation-only: the pointer may stay as it is
  printf '\nA README line.\n' >> README.md; git add README.md; commit_hooks 'DEMO-DOC-0001: a docs line'; green
}
arm_handoff_refuses_dirty_tree() {
  printf 'fn main() {}\n' > crates/app/src/main.rs
  OUT="$(bash scripts/handoff 2>&1)"; RC=$?; [ "$RC" -ne 0 ] && has 'not clean'
}
arm_handoff_refuses_stale_pointer() {
  # a governed commit made with the hooks bypassed and a stale pointer: handoff must catch it
  code_change; good_leaf > docs/tasks/FEAT.md; git add -A; commit_nohooks 'DEMO-APP-0002 (leaf FEAT.1): rewrite main' || return 1
  OUT="$(bash scripts/handoff 2>&1)"; RC=$?; [ "$RC" -ne 0 ] && has 'stale'
}
arm_handoff_refuses_running_job() {
  ( exec 3< README.md; sleep 20 ) & job=$!
  sleep 1; OUT="$(bash scripts/handoff 2>&1)"; RC=$?
  kill "$job" 2>/dev/null; wait "$job" 2>/dev/null
  [ "$RC" -ne 0 ] && has 'STILL RUNNING'
}
arm_handoff_ok_then_resume_from_fresh_clone() {
  # the session ends: handoff is green on the base child; a NEW clone (a new session, any harness) resumes
  OUT="$(bash scripts/handoff 2>&1)"; RC=$?; green && has 'handoff: OK' || return 1
  rm -rf "$T/clone"; git clone -q . "$T/clone" || return 1
  cd "$T/clone" && git config core.hooksPath .githooks
  # resume by the read path: the pointer names a tree that exists, and the gate is green on the clone
  tree="$(grep '^- active_work_unit:' MEMORY.md | grep -oE '`[A-Z][A-Z0-9-]*`' | head -1 | tr -d '`')"
  [ -n "$tree" ] && [ -f "docs/tasks/$tree.md" ] || return 1
  grep -q '^- next_action: .' MEMORY.md || return 1
  gate; green
}

arm_bootstrap_rerun_same_name_idempotent() {
  # the base child is already 'demo': a rerun with the same name changes nothing and exits 0
  ./scripts/bootstrap.sh demo --yes > "$T/.boot.log" 2>&1; rc=$?
  [ "$rc" -eq 0 ] && [ -z "$(git status --porcelain --untracked-files=all)" ]
}
arm_bootstrap_rerun_other_name_refused() {
  ./scripts/bootstrap.sh other --yes > "$T/.boot.log" 2>&1; rc=$?
  [ "$rc" -eq 2 ] && [ -z "$(git status --porcelain --untracked-files=all)" ] && grep -q '^name = "demo"' crates/app/Cargo.toml
}
arm_bootstrap_dirty_tree_refused() {
  fresh_copy >/dev/null 2>&1 || return 1
  printf '\n- an uncommitted note\n' >> MEMORY.md
  ./scripts/bootstrap.sh demo --yes > "$T/.boot.log" 2>&1; rc=$?
  [ "$rc" -eq 2 ] && grep -q 'an uncommitted note' MEMORY.md && [ -f MAINTAINING.md ]
}
arm_bootstrap_contributor_mode() {
  git config --unset core.hooksPath 2>/dev/null
  ./scripts/bootstrap.sh --contributor > "$T/.boot.log" 2>&1; rc=$?
  [ "$rc" -eq 0 ] && [ "$(git config core.hooksPath)" = ".githooks" ] && [ -z "$(git status --porcelain --untracked-files=all)" ]
}
arm_bootstrap_identity_and_history_reset() {
  # the base child: identity recorded, no bedrock history in the live docs, no maintainer files
  grep -q '^name = demo$' .bedrock/project && grep -q '^prefix = DEMO$' .bedrock/project \
    && [ "$(grep -c 'BEDROCK-' CHANGELOG.md DEV_NOTES.md | awk -F: '{s+=$2} END{print s}')" = 0 ] \
    && [ ! -f MAINTAINING.md ] && [ ! -d docs/reviews ]
}
arm_bootstrap_evidence_truthful() {
  # the seeded leaf cites the gate verdict that bootstrap actually printed, and real counts
  grep -q 'crates/app/Cargo.toml` → `1` before, `0` after' docs/tasks/BOOTSTRAP.md \
    && grep -q '`=== all doctrines green ===` (`rc=0`)' docs/tasks/BOOTSTRAP.md \
    && grep -q '=== all doctrines green ===' "$WORK/bootstrap.log"
}
arm_bootstrap_fresh_git_init_allowed() {
  # cargo-generate leaves a repository with no commit: bootstrap must accept it and stage the whole tree
  rm -rf "$T"; mkdir -p "$T"
  ( cd "$SUITE_ROOT" && git ls-files -co --exclude-standard -z | tar --null -T - -cf - | tar -x -C "$T" )
  cd "$T" && git init -q -b main . && git config user.email t@example.invalid && git config user.name tester
  ./scripts/bootstrap.sh demo --lang rust --yes > "$T/.boot.log" 2>&1 || return 1
  printf '%s\n' 'DEMO-BOOTSTRAP-0001 (leaf BOOTSTRAP.1): bootstrapped from bedrock' > "$T/.m" && git commit -q -F "$T/.m" >/dev/null 2>&1
}

# ── updater arms: real children from bedrock's own history (maintainer-only: need that history) ──
old_child() { # $1 = bedrock revision → rebuild $T as a child created from that revision, bootstrapped and committed
  [ -f "$SUITE_ROOT/MAINTAINING.md" ] || return 3
  sed --version >/dev/null 2>&1 || return 3      # the OLD bootstrap used GNU-only `sed -i` (BR-10): no GNU sed, no old child
  git -C "$SRC_REPO" cat-file -e "$1^{commit}" 2>/dev/null || return 3
  rm -rf "$T"; mkdir -p "$T"
  git -C "$SRC_REPO" archive "$1" | tar -x -C "$T" || return 1
  cd "$T" && git init -q -b main . && git config user.email t@example.invalid && git config user.name tester \
    && chmod +x scripts/*.sh knowledge-map/scripts/*.sh .githooks/* 2>/dev/null \
    && git add -A && git -c core.hooksPath=/dev/null commit -qm "Initial commit" \
    && ./scripts/bootstrap.sh oldproj > "$T/.oldboot.log" 2>&1 \
    && git add -A && git -c core.hooksPath=/dev/null commit -qm "OLDPROJ-BOOT-0001 (leaf BOOTSTRAP.1): bootstrap" \
    && cp docs/tasks/TEMPLATE.md docs/tasks/STITCH.md \
    && printf '| [`STITCH`](tasks/STITCH.md) | `active` | `.1` | repo-local |\n' >> docs/TASK_TREE.md \
    && git add -A && git -c core.hooksPath=/dev/null commit -qm "OLDPROJ-TREE-0001: first tree" \
    && cp "$SRC_REPO/scripts/update_scaffold.sh" scripts/update_scaffold.sh   # the release note's one manual step
}
upgrade_and_commit() { # runs the updater against the suite root's worktree, then the printed commit through the hooks
  git -c core.hooksPath=/dev/null commit -qam "OLDPROJ-SYNC-0001: take the new updater" >/dev/null 2>&1
  ./scripts/update_scaffold.sh "$SRC_REPO" > "$T/.update.log" 2>&1 || return 1
  printed="$(awk '/^Commit the update/ { on=1; next } on && /^[[:space:]]*$/ { exit } on && /^[[:space:]]+(git|printf)/ { print }' "$T/.update.log")"
  [ -n "$printed" ] || return 1
  git config core.hooksPath .githooks
  OUT="$(bash -c "$printed" 2>&1)"; RC=$?
}
arm_updater_child_0_4_0_upgrades() {
  old_child 6cc8900; rc=$?; [ "$rc" -eq 3 ] && return 0; [ "$rc" -eq 0 ] || return 1
  grep -q 'Last updated' docs/tasks/STITCH.md || return 1            # the 0.4.0 template shipped the field
  upgrade_and_commit || return 1
  green && grep -q '^bedrock-scaffold ' DOCTRINE_VERSION && [ "$(cat DOCTRINE_VERSION)" = "$(cat "$SRC_REPO/DOCTRINE_VERSION")" ] \
    && ! grep -q 'Last updated' docs/tasks/STITCH.md \
    && grep -q 'tasks/STITCH.md' docs/TASK_TREE.md && grep -q 'tasks/UPDATE-' docs/TASK_TREE.md \
    && [ -f scripts/lib/spine.sh ] && [ -f scripts/check_resume_pointer.sh ] && [ -f .bedrock/project ] \
    && grep -q 'AGENTS.md' CLAUDE.md && grep -q 'updated ' "$T/.update.log"
}
arm_updater_child_0_6_1_upgrades() {
  old_child 340fe2f; rc=$?; [ "$rc" -eq 3 ] && return 0; [ "$rc" -eq 0 ] || return 1
  upgrade_and_commit || return 1
  green && [ "$(cat DOCTRINE_VERSION)" = "$(cat "$SRC_REPO/DOCTRINE_VERSION")" ] && grep -q 'source ' docs/tasks/UPDATE-*.md \
    && grep -q '^ci_range_since =$' .doctrine/config \
    && gate_ci HEAD && green
}
arm_updater_never_overwrites_modified() {
  # a spine file the project modified lands in .bedrock-incoming/, and the project's copy is byte-identical afterwards
  printf '\n# project customisation\n' >> scripts/check_docpaths.sh
  git -c core.hooksPath=/dev/null commit -qam "DEMO-CFG-0004: customise a check" >/dev/null 2>&1
  before="$(shasum -a 256 scripts/check_docpaths.sh 2>/dev/null || sha256sum scripts/check_docpaths.sh)"
  ./scripts/update_scaffold.sh "$SRC_REPO" > "$T/.update.log" 2>&1; rc=$?
  after="$(shasum -a 256 scripts/check_docpaths.sh 2>/dev/null || sha256sum scripts/check_docpaths.sh)"
  [ "$before" = "$after" ] && grep -q 'DIFFERS.*scripts/check_docpaths.sh' "$T/.update.log" && [ -f .bedrock-incoming/scripts/check_docpaths.sh ]
}
arm_updater_self_replaces() {
  printf '\n# an older or customised updater\n' >> scripts/update_scaffold.sh
  git -c core.hooksPath=/dev/null commit -qam "DEMO-CFG-0004: touch the updater" >/dev/null 2>&1
  ./scripts/update_scaffold.sh "$SRC_REPO" > "$T/.update.log" 2>&1
  grep -q 'step 0 — replaced scripts/update_scaffold.sh' "$T/.update.log" && [ -f .bedrock-incoming/scripts/update_scaffold.sh.previous ] \
    && cmp -s scripts/update_scaffold.sh "$SRC_REPO/scripts/update_scaffold.sh" && grep -q '^✓ update:' "$T/.update.log"
}
arm_updater_refuses_dirty_tree() {
  printf '\nnote\n' >> README.md
  ./scripts/update_scaffold.sh "$SRC_REPO" > "$T/.update.log" 2>&1; rc=$?
  [ "$rc" -eq 2 ] && grep -q 'not clean' "$T/.update.log" && [ "$(git status --porcelain | wc -l | tr -d ' ')" = 1 ]
}
arm_updater_refuses_downgrade() {
  [ -f "$SUITE_ROOT/MAINTAINING.md" ] || return 0
  git -C "$SRC_REPO" cat-file -e 340fe2f^{commit} 2>/dev/null || return 0
  ./scripts/update_scaffold.sh "$SRC_REPO" --ref 340fe2f > "$T/.update.log" 2>&1; rc=$?
  [ "$rc" -eq 2 ] && grep -qiE 'older|manifest' "$T/.update.log" && [ -z "$(git status --porcelain --untracked-files=all)" ]
}
arm_updater_plan_writes_nothing() {
  ./scripts/update_scaffold.sh "$SRC_REPO" --plan > "$T/.update.log" 2>&1; rc=$?
  [ "$rc" -eq 0 ] && grep -q 'nothing written' "$T/.update.log" && [ -z "$(git status --porcelain --untracked-files=all)" ]
}
arm_updater_same_version_is_noop_commitable() {
  # a child already current: the run seeds nothing, updates nothing, and its upgrade commit still passes the gate
  ./scripts/update_scaffold.sh "$SRC_REPO" > "$T/.update.log" 2>&1 || return 1
  grep -q '0 seeded, 0 updated, 0 differ' "$T/.update.log"
}

arm_waiver_owner_real_leaf_passes() {
  { good_leaf; printf '\n- the diagnosis-toolbox signatures do not apply to this defect class (gate gap owned by FEAT.1).\n'; } > docs/tasks/FEAT.md
  git add -A; bash scripts/check_waiver_routing.sh >/dev/null 2>&1
}
arm_waiver_historical_not_rejudged() {
  # an OLD unrouted waiver is history; adding a NEW, properly owned one must not re-judge it (BR-17)
  { good_leaf; printf '\n- old note: the diagnosis-toolbox signatures do not apply here.\n'; } > docs/tasks/FEAT.md
  git add -A; commit_nohooks 'DEMO-DOC-0001 (leaf FEAT.1): an old waiver' || return 1
  printf '\n- new note: the diagnosis-toolbox signatures do not apply to this class (gate gap owned by FEAT.1).\n' >> docs/tasks/FEAT.md
  git add -A; bash scripts/check_waiver_routing.sh >/dev/null 2>&1
}
arm_lesson_decline_per_lesson() {
  printf '\n## _(2026-09-30)_ — lesson one\n\n- a\n\n## _(2026-09-30)_ — lesson two\n\n- b\n' >> DEV_NOTES.md
  { good_leaf; printf '\n- promotion: declined (per-slice history)\n'; } > docs/tasks/FEAT.md
  git add -A; OUT="$(bash scripts/check_lesson_promotion.sh 2>&1)"; RC=$?; [ "$RC" -ne 0 ] || return 1
  printf -- '- promotion: declined (also per-slice history)\n' >> docs/tasks/FEAT.md
  git add -A; bash scripts/check_lesson_promotion.sh >/dev/null 2>&1
}
arm_lesson_promoted_via_knowledge() {
  printf '\n## _(2026-09-30)_ — a durable lesson\n\n- x\n' >> DEV_NOTES.md
  mkdir -p docs/knowledge; printf '# retries\n\nsome prose without a question\n' > docs/knowledge/retries.md
  git add -A; OUT="$(bash scripts/check_lesson_promotion.sh 2>&1)"; RC=$?; [ "$RC" -ne 0 ] || return 1
  printf 'answers: how many retries does the client make?\n\n# retries\n\nthree, with backoff.\n' > docs/knowledge/retries.md
  git add -A; bash scripts/check_lesson_promotion.sh >/dev/null 2>&1 || return 1
  bash knowledge-map/scripts/gen_knowledge_map.sh > "$T/.map" && grep -q 'retries.md' "$T/.map" && grep -q 'how many retries' "$T/.map"
}
arm_knowledge_map_shows_tree_status() {
  bash knowledge-map/scripts/gen_knowledge_map.sh > "$T/.map" && grep -qE 'BOOTSTRAP\.md\) — `done`' "$T/.map"
}

# ── pack and setup arms (REVIEW-2026-09.8) ────────────────────────────────────────────────────
arm_child_no_packs_bootstraps_and_gates() {
  fresh_copy >/dev/null 2>&1 || return 1
  ./scripts/bootstrap.sh plain --yes > "$T/.boot.log" 2>&1 || return 1
  printf '%s\n' 'PLAIN-BOOTSTRAP-0001 (leaf BOOTSTRAP.1): bootstrapped from bedrock' > "$T/.m" && git commit -q -F "$T/.m" >/dev/null 2>&1 || return 1
  [ ! -f Cargo.toml ] && [ ! -d packs ] && [ ! -f CLAUDE.md ] && [ ! -d docs/book ] && grep -q '^packs = $' .bedrock/project && gate_ci HEAD && green
}
arm_unselected_packs_not_copied() {
  [ ! -d packs ] && [ ! -d docs/book ] && [ ! -f GEMINI.md ] && grep -q '^packs = rust,claude$' .bedrock/project
}
arm_rust_pack_child_runs_check() {
  command -v cargo >/dev/null 2>&1 || return 0          # no toolchain here: nothing to run
  grep -q '^name = "demo"' crates/app/Cargo.toml && grep -q '^check = cargo' .doctrine/commands || return 1
  OUT="$(bash scripts/run check 2>&1)"; RC=$?; green
}
arm_run_refuses_undeclared_verb() {
  OUT="$(bash scripts/run deploy 2>&1)"; RC=$?; [ "$RC" -eq 2 ] && has "no 'deploy' verb"
}
arm_harness_adapters_point_to_agents() {
  fresh_copy >/dev/null 2>&1 || return 1
  ./scripts/bootstrap.sh multi --harness claude,codex,qwen --yes > "$T/.boot.log" 2>&1 || return 1
  grep -q AGENTS.md CLAUDE.md && grep -q AGENTS.md QWEN.md && [ ! -f CODEX.md ] && grep -q '^packs = claude,codex,qwen$' .bedrock/project \
    && grep -q 'shell-snapshots' .doctrine/handoff_ignore && grep -q '/.codex/' .doctrine/handoff_ignore
}
arm_mdbook_pack_child() {
  fresh_copy >/dev/null 2>&1 || return 1
  ./scripts/bootstrap.sh booky --title "Booky Docs" --docs mdbook --yes > "$T/.boot.log" 2>&1 || return 1
  grep -q '^title = "Booky Docs"' docs/book/book.toml && grep -q '^docs = mdbook' .doctrine/commands && grep -q '^\^docs/book/' .doctrine/docs_paths.txt || return 1
  # the pack's skeleton, not bedrock's own guide (maintainer-class) nor the workflow that publishes it
  [ ! -f docs/book/src/updating.md ] && [ ! -f .github/workflows/book.yml ] || return 1
  command -v mdbook >/dev/null 2>&1 || return 0
  OUT="$(bash scripts/run docs 2>&1)"; RC=$?; green
}
arm_wizard_answers_piped() {
  # the guided setup with answers piped in: name, title (default), prefix (default), visibility 2 (private),
  # language 2 (rust), docs 1 (none), harness "1,2" (claude, codex — the packs' declared order), confirm y
  fresh_copy >/dev/null 2>&1 || return 1
  printf 'wiz\n\n\n2\n2\n1\n1,2\ny\n' | ./scripts/bootstrap.sh --ask > "$T/.boot.log" 2>"$WORK/$name.err" || { tail -5 "$WORK/$name.err"; return 1; }
  grep -q '^name = wiz$' .bedrock/project && grep -q '^prefix = WIZ$' .bedrock/project && grep -q '^visibility = private$' .bedrock/project \
    && grep -q '^packs = rust,claude,codex$' .bedrock/project && grep -q 'Declared posture: PRIVATE' VISIBILITY.md \
    && grep -q '1/7  Project name \[' "$WORK/$name.err" && grep -q '(default)' "$WORK/$name.err"
}
arm_wizard_invalid_answer_reasked() {
  fresh_copy >/dev/null 2>&1 || return 1
  # the harness default is claude (declared by the pack): Enter on question 7 selects it
  printf 'bad name!\nok-name\n\n\n\n\n\n\ny\n' | ./scripts/bootstrap.sh --ask > "$T/.boot.log" 2>"$WORK/$name.err" || return 1
  grep -q '^name = ok-name$' .bedrock/project && grep -q 'try again' "$WORK/$name.err" && grep -q '^packs = claude$' .bedrock/project && [ -f CLAUDE.md ]
}
arm_wizard_decline_writes_nothing() {
  fresh_copy >/dev/null 2>&1 || return 1
  printf 'nope\n\n\n\n\n\n\nn\n' | ./scripts/bootstrap.sh --ask > "$T/.boot.log" 2>&1; rc=$?
  [ "$rc" -eq 2 ] && [ -f MAINTAINING.md ] && [ -z "$(git status --porcelain --untracked-files=all)" ]
}
arm_new_project_local() {
  # from bedrock itself (the source clone): questions answered by flags, a local repository, first commit made
  rm -rf "$T/np"
  ( cd "$SRC_REPO" && bash scripts/new_project.sh --name npdemo --dest "$T/np" --local --lang rust --harness claude --yes ) > "$T/.np.log" 2>&1 || { tail -5 "$T/.np.log"; return 1; }
  cd "$T/np" && [ -f .bedrock/project ] && git log --oneline -1 | grep -q 'NPDEMO-BOOTSTRAP-0001' && [ ! -d packs ] \
    && git config core.hooksPath | grep -q githooks && gate_ci HEAD && green && bash scripts/handoff >/dev/null 2>&1
}
arm_add_pack_later() {
  ./scripts/update_scaffold.sh "$SRC_REPO" --add-pack docs/mdbook > "$T/.update.log" 2>&1 || { tail -5 "$T/.update.log"; return 1; }
  [ -f docs/book/book.toml ] && grep -q '^packs = rust,claude,mdbook$' .bedrock/project && grep -q '^docs = mdbook' .doctrine/commands \
    && grep -q 'installed      pack docs/mdbook' "$T/.update.log"
}

arm_bedrock_itself_green_in_ci_mode() {
  # the template practises what it preaches: the tree under test (the suite's synthetic tip) passes its own
  # tree invariants — NEUTRALITY (no language or harness in spine logic), MANIFEST (every path classified,
  # every spine path present) and MEMORY-ARCH (the inventory) — judged as CI judges a commit
  ( cd "$SRC_REPO" && for c in scripts/check_neutrality.sh scripts/check_manifest.sh scripts/check_memory_architecture.sh scripts/check_book_coverage.sh; do
      SPINE_AFTER=HEAD SPINE_BEFORE=HEAD^ bash "$c" || exit 1; done ) > "$T/.self.log" 2>&1; rc=$?
  [ "$rc" -eq 0 ] && grep -q 'NEUTRALITY: OK' "$T/.self.log" && grep -q 'MANIFEST: OK' "$T/.self.log" && grep -q 'BOOK-COVERAGE: OK' "$T/.self.log"
}

arm_child_carries_no_book() {
  # bedrock's user guide and the workflow that publishes it are maintainer-class: bootstrap removes every
  # such path FROM THE MANIFEST, so a child never inherits a book about the template (the base child has
  # no docs pack); the coverage gate it does inherit says it does not apply there
  [ ! -e docs/book ] && [ ! -f .github/workflows/book.yml ] && [ ! -f MAINTAINING.md ] && [ -f scripts/check_book_coverage.sh ] || return 1
  OUT="$(bash scripts/check_book_coverage.sh 2>&1)"; RC=$?
  green && has 'not the template itself'
}
arm_book_coverage_refuses_dropped_doctrine() {
  # in the template: the guide intact is green; the same guide with one doctrine's name gone is a breach
  rm -rf "$T/src"; git clone -q "$SRC_REPO" "$T/src" 2>/dev/null || return 1
  cd "$T/src" || return 1
  OUT="$(SPINE_AFTER=HEAD SPINE_BEFORE=HEAD^ bash scripts/check_book_coverage.sh 2>&1)"; RC=$?
  green && has 'BOOK-COVERAGE: OK' || return 1
  for c in docs/book/src/*.md; do sed 's/TABLE-ARITY-RATCHET/TABLE-ARITY/g' "$c" > "$c.tmp" && mv "$c.tmp" "$c"; done
  git add docs/book/src
  OUT="$(bash scripts/check_book_coverage.sh 2>&1)"; RC=$?
  [ "$RC" -eq 1 ] && has 'never names the doctrine `TABLE-ARITY-RATCHET`'
}

arm_ci_range_respects_contract_epoch() {
  # a commit before the epoch is not re-judged; one after it is
  base="$(git rev-parse HEAD)"
  code_change; git add -A; commit_nohooks 'DEMO-APP-0002: unowned, pre-contract' || return 1
  pre="$(git rev-parse HEAD)"
  printf '\nci_range_since = %s\n' "$pre" >> .doctrine/config
  good_leaf > docs/tasks/FEAT.md; point_to DEMO-APP-0003 '`FEAT` → frontier leaf `FEAT.1` (`active`)'; git add -A
  commit_hooks 'DEMO-APP-0003 (leaf FEAT.1): record the epoch' || return 1
  OUT="$(bash scripts/check_doctrines.sh --range "$base..HEAD" 2>&1)"; RC=$?
  green && has '1 before the epoch' && has '1 commit(s) judged'
}

# ── the runner ────────────────────────────────────────────────────────────────────────────────
# The SOURCE the updater arms sync from: a clone of this repository (full history, for the merge
# base) with the WORKING TREE committed on top, so an uncommitted change is what gets tested.
build_source() {
  git clone -q "$SUITE_ROOT" "$WORK/src" 2>/dev/null || return 1
  ( cd "$WORK/src" && git ls-files -z | xargs -0 rm -f ) || return 1        # so a file the working tree DELETED is gone too
  git ls-files -co --exclude-standard -z | tar --null -T - -cf - | tar -x -C "$WORK/src" || return 1
  ( cd "$WORK/src" && git config user.email t@example.invalid && git config user.name tester \
    && git add -A && git -c core.hooksPath=/dev/null commit -q --allow-empty -m "SUITE-0000: the working tree under test" ) || return 1
  SRC_REPO="$WORK/src"; export SRC_REPO
}
build_source || { note "REFUSED — could not build the source clone"; exit 2; }
build_base || { note "REFUSED — could not build the base child (see $WORK/bootstrap.log and first_commit.log)"; [ "$KEEP" = 1 ] || cat "$WORK/bootstrap.log" 2>/dev/null | tail -5 >&2; exit 2; }

pass=0; fail=0; xfail=0; xpass=0; n=0
while read -r name expect id; do
  [ -n "$name" ] || continue
  [ -z "$ONLY" ] || [ "$name" = "$ONLY" ] || continue
  n=$((n+1))
  T="$WORK/$name"; rm -rf "$T"; cp -R "$BASE" "$T"
  ( cd "$T" && name="$name" "arm_$name"; rc=$?; printf '\n--- last captured output ---\n%s\n' "$OUT"; exit $rc ) > "$WORK/$name.log" 2>&1; ok=$?
  case "$expect:$ok" in
    req:0)   pass=$((pass+1));   printf '  ✓ pass   %-40s %s\n' "$name" "$id" ;;
    req:*)   fail=$((fail+1));   printf '  ✗ FAIL   %-40s %s — required, and the spine does not comply\n' "$name" "$id"
             tail -3 "$WORK/$name.log" | sed 's/^/           /' ;;
    xfail:0) xpass=$((xpass+1)); printf '  ! XPASS  %-40s %s — now passes: move it to req in the fixing leaf\n' "$name" "$id" ;;
    xfail:*) xfail=$((xfail+1)); printf '  ~ xfail  %-40s %s (open)\n' "$name" "$id" ;;
  esac
  [ "$KEEP" = 1 ] || rm -rf "$T"
done <<ARMS_EOF
$ARMS
ARMS_EOF

[ "$n" -gt 0 ] || { note "no arm named '$ONLY'"; exit 2; }
printf 'arms: %d pass / %d xfail / %d fail / %d xpass (of %d)\n' "$pass" "$xfail" "$fail" "$xpass" "$n"
[ "$KEEP" = 1 ] && printf 'children kept under %s\n' "$WORK"
[ "$fail" -eq 0 ] && [ "$xpass" -eq 0 ]
