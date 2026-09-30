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
bootstrap_first_commit_as_printed       xfail  BR-11
bootstrap_bad_names_refused             xfail  BK-04
bootstrap_no_name_uninitialised_exit2   xfail  BK-18
bootstrap_under_bsd_sed                 xfail  BR-10
ownership_dart_perl_julia_no_leaf       xfail  NT-03
spine_hook_and_workflow_no_leaf         xfail  BK-05
deletion_needs_leaf                     req    BR-08
evidence_reuse_done_leaf                xfail  BK-01
prose_evidence_refused                  xfail  BK-03
keyword_box_shadowing_refused           xfail  BK-03
bare_version_number_not_evidence        xfail  BK-03
stamped_evidence_line_accepted          xfail  NT-04
config_weakened_same_commit             req    BK-06
env_bypass_ignored                      xfail  BK-08
exception_trailer_honoured              xfail  BK-08
subdir_markdown_not_a_leaf              req    BK-15
spine_docs_deleted                      req    BK-13
child_without_claude_md_passes          req    NT-08
project_slot_not_executable             req    BK-14
git_failure_refused                     req    BK-17
unstaged_fix_hides_staged_defect        req    BR-03
ci_judges_each_commit                   req    BR-04
commit_msg_human_named_claude           xfail  BK-11
commit_msg_agent_co_developed_by        req    BK-11
commit_msg_leading_blank_line           req    BK-11
knowledge_map_single_line_comment       req    BK-12
census_make_sure_not_a_discharge        xfail  BK-16
waiver_owner_must_resolve               xfail  BK-16
scratch_stays_out_of_worktree           req    NT-07
rename_needs_leaf                       req    BR-08
python3_missing_refused                 req    BR-05
invalid_regex_refused                   req    BR-05
invalid_regex_repair_allowed            req    BR-05
ci_message_judged                       req    BR-21
subject_hello_refused                   xfail  BR-21
"

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
    && ./scripts/bootstrap.sh demo > "$WORK/bootstrap.log" 2>&1 \
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
gate()   { regen_map; OUT="$(bash scripts/check_doctrines.sh 2>&1)"; RC=$?; }
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
  code_change; good_leaf > docs/tasks/FEAT.md; git add -A
  commit_hooks 'DEMO-APP-0002 (leaf FEAT.1): rewrite main'; green
}
arm_bootstrap_first_commit_as_printed() {
  # a fresh, un-bootstrapped copy; run bootstrap; execute the printed commit block verbatim
  rm -rf "$T"; mkdir -p "$T"
  ( cd "$SUITE_ROOT" && git ls-files -co --exclude-standard -z | tar --null -T - -cf - | tar -x -C "$T" )
  git init -q -b main . && git config user.email t@example.invalid && git config user.name tester
  chmod +x scripts/*.sh knowledge-map/scripts/*.sh .githooks/* 2>/dev/null
  git add -A && git -c core.hooksPath=/dev/null commit -qm "Initial commit"
  ./scripts/bootstrap.sh demo > "$T/.boot.log" 2>&1 || return 1
  # the printed block: the lines between "Commit the bootstrap itself" and the next blank line
  printed="$(awk '/Commit the bootstrap itself/ { on=1; next } on && /^[[:space:]]*$/ { exit } on && /^[[:space:]]+(git|printf)/ { print }' "$T/.boot.log")"
  [ -n "$printed" ] || return 1
  OUT="$(bash -c "$printed" 2>&1)"; RC=$?
  green && git log -1 --format=%s | grep -qE '^[A-Z][A-Z0-9_]*-BOOTSTRAP-0001 '
}
arm_bootstrap_bad_names_refused() {
  local n ok=0
  for n in 'x&y' 'a/b' 'my.proj' 'Stitch CAD'; do
    rm -rf "$T"; mkdir -p "$T"
    ( cd "$SUITE_ROOT" && git ls-files -co --exclude-standard -z | tar --null -T - -cf - | tar -x -C "$T" )
    ( git init -q -b main . && git add -A && git -c core.hooksPath=/dev/null commit -qm "Initial commit" ) >/dev/null 2>&1
    before="$(git status --porcelain | wc -l | tr -d ' ')"
    ./scripts/bootstrap.sh "$n" >/dev/null 2>&1; rc=$?
    after="$(git status --porcelain | wc -l | tr -d ' ')"
    # refused with exit 2 and NOTHING written
    if [ "$rc" -eq 2 ] && [ "$after" = "$before" ]; then ok=$((ok+1)); fi
  done
  [ "$ok" -eq 4 ]
}
arm_bootstrap_no_name_uninitialised_exit2() {
  rm -rf "$T"; mkdir -p "$T"
  ( cd "$SUITE_ROOT" && git ls-files -co --exclude-standard -z | tar --null -T - -cf - | tar -x -C "$T" )
  ( git init -q -b main . && git add -A && git -c core.hooksPath=/dev/null commit -qm "Initial commit" ) >/dev/null 2>&1
  ./scripts/bootstrap.sh >/dev/null 2>&1; rc=$?
  [ "$rc" -eq 2 ] && [ -f MAINTAINING.md ]
}
arm_bootstrap_under_bsd_sed() {
  # meaningful only where a BSD sed exists at /usr/bin/sed; elsewhere the arm is vacuously required
  if /usr/bin/sed --version >/dev/null 2>&1; then return 0; fi   # GNU sed there: nothing to test
  [ -x /usr/bin/sed ] || return 0
  rm -rf "$T"; mkdir -p "$T"
  ( cd "$SUITE_ROOT" && git ls-files -co --exclude-standard -z | tar --null -T - -cf - | tar -x -C "$T" )
  ( git init -q -b main . && git config user.email t@example.invalid && git config user.name tester \
    && git add -A && git -c core.hooksPath=/dev/null commit -qm "Initial commit" ) >/dev/null 2>&1
  PATH="/usr/bin:/bin:/usr/sbin:/sbin" ./scripts/bootstrap.sh demo >/dev/null 2>&1; rc=$?
  [ "$rc" -eq 0 ] && grep -q '^name = "demo"' crates/app/Cargo.toml && ! ls docs/TASK_TREE.md-e >/dev/null 2>&1
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
  git add -A; commit_hooks 'DEMO-APP-0002 (leaf FEAT.1): x'; green
}
arm_config_weakened_same_commit() {
  printf '^nothing-matches-this$\n' > .doctrine/code_paths.txt
  printf 'echo hi\n' > scripts/new_tool.sh
  git add -A; gate; refused_by 'TASK-TREE-OWNERSHIP' || refused_by 'TASK-ACCEPTANCE'
}
arm_env_bypass_ignored() {
  code_change; git add -A
  OUT="$(SPINE_ALLOW_UNOWNED=1 bash scripts/check_task_tree_ownership.sh 2>&1)"; RC=$?
  [ "$RC" -ne 0 ]
}
arm_exception_trailer_honoured() {
  code_change; git add -A
  commit_hooks 'DEMO-APP-0002: vendored change

Spine-Exception: vendored third-party sources, no leaf applies'
  green
}
arm_subdir_markdown_not_a_leaf() {
  mkdir -p docs/tasks/artifacts/perf; printf '# perf notes\n' > docs/tasks/artifacts/perf/README.md
  code_change; good_leaf > docs/tasks/FEAT.md; git add -A
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
arm_python3_missing_refused() {
  # a PATH with everything the spine needs except python3: the check must REFUSE, not pass
  mkdir -p "$T/bin"
  for t in bash sh git awk sed grep head tail cut tr wc sort uniq mktemp dirname basename cat diff cmp mv rm mkdir seq paste date ls cp chmod tar env comm; do
    p="$(command -v "$t" 2>/dev/null)"; [ -n "$p" ] && ln -s "$p" "$T/bin/$t"
  done
  printf '\nA README line.\n' >> README.md; git add README.md
  OUT="$(PATH="$T/bin" bash scripts/check_doctrines.sh 2>&1)"; RC=$?
  refused_by 'TABLE-ARITY-RATCHET'
}
arm_invalid_regex_refused() {
  mkdir -p .doctrine; printf '[\n' > .doctrine/code_paths.txt; git add .doctrine/code_paths.txt
  commit_nohooks 'DEMO-CFG-0003: broken code paths' || return 1
  code_change; good_leaf > docs/tasks/FEAT.md; git add -A; gate; refused_by 'TASK-ACCEPTANCE'
}
arm_invalid_regex_repair_allowed() {
  mkdir -p .doctrine; printf '[\n' > .doctrine/code_paths.txt; git add .doctrine/code_paths.txt
  commit_nohooks 'DEMO-CFG-0003: broken code paths' || return 1
  printf '\\.rs$\n' > .doctrine/code_paths.txt; good_leaf > docs/tasks/FEAT.md; git add -A; gate; green
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

# ── the runner ────────────────────────────────────────────────────────────────────────────────
build_base || { note "REFUSED — could not build the base child (see $WORK/bootstrap.log and first_commit.log)"; [ "$KEEP" = 1 ] || cat "$WORK/bootstrap.log" 2>/dev/null | tail -5 >&2; exit 2; }

pass=0; fail=0; xfail=0; xpass=0; n=0
while read -r name expect id; do
  [ -n "$name" ] || continue
  [ -z "$ONLY" ] || [ "$name" = "$ONLY" ] || continue
  n=$((n+1))
  T="$WORK/$name"; rm -rf "$T"; cp -R "$BASE" "$T"
  ( cd "$T" && "arm_$name"; rc=$?; printf '\n--- last captured output ---\n%s\n' "$OUT"; exit $rc ) > "$WORK/$name.log" 2>&1; ok=$?
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
