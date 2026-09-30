#!/usr/bin/env bash
# docs/tasks/artifacts/task_acceptance/run_task_acceptance_probes.sh
# BEDROCK-MAINTENANCE.2.4 — RED / GREEN / CONTROL probes for scripts/check_task_acceptance.sh.
#
# ⭐⭐ CTRL-1 AND CTRL-2 ARE THE POINT. They are the arms that prove BOX-SCOPING, which is the
# soundness property this check exists for. Both replay measured leakage holes from the project
# this was distilled from:
#   CTRL-1  the evidence is in the FILE but OUTSIDE the box's bullet -> must REJECT.
#           A whole-file grep would PASS this, which is precisely how the looser form gave green
#           on evidence it had never tied to a claim.
#   CTRL-2  the evidence lives in a CO-STAGED, UNRELATED leaf -> must REJECT.
#           That is exactly how one real leaf passed: on tokens belonging to a different tree.
# Without these two, "box-scoped" is a word in a comment rather than a property of the check.
#
# Each probe builds a throwaway git repository, because the check reads the STAGED diff.
#
# REVIEW-2026-09.4: the check is now MESSAGE-TIME and binds to the leaf the subject names, the
# checklist lives INSIDE the leaf's section, labels are anchored, and evidence must sit in a code
# span. The fixtures below are in that shape; every probe supplies the subject
# `PROBE-0001 (leaf TREE.1): …` through SPINE_COMMIT_MSG, as the commit-msg hook and CI do.
set -uo pipefail
ROOT="$(git rev-parse --show-toplevel)" || exit 2; cd "$ROOT" || exit 2
GUARD="$ROOT/scripts/check_task_acceptance.sh"
[ -f "$GUARD" ] || { echo "probe: REFUSED — $GUARD not found" >&2; exit 2; }

pass=0; fail=0
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

mkrepo() { # $1 = name -> repo dir
  local d="$WORK/$1"
  rm -rf "$d"; mkdir -p "$d/scripts/lib" "$d/docs/tasks" "$d/crates/app/src"
  cp "$GUARD" "$d/scripts/check_task_acceptance.sh"
  cp "$ROOT/scripts/lib/spine.sh" "$d/scripts/lib/spine.sh"   # the check sources the library
  git -C "$d" init -q .
  git -C "$d" config user.email probe@example.invalid
  git -C "$d" config user.name  probe
  printf '# seed\n' > "$d/docs/tasks/SEED.md"
  printf 'fn main() {}\n' > "$d/crates/app/src/main.rs"
  git -C "$d" add -A >/dev/null 2>&1
  git -C "$d" commit -qm "SEED-0001: seed" >/dev/null 2>&1
  printf '%s' "$d"
}

# A complete, correctly-evidenced leaf (new shape: the checklist INSIDE the leaf's section).
leaf_with() { # $1 $2 $3 = the three box bodies
  cat <<EOF
# TREE

- ID: \`TREE.1\`
  Status: \`active\`
  Goal: a change

  ### Acceptance Checklist

  - [x] **ROOT CAUSE (WHY + WHERE)** — $1
  - [x] **ADDRESSED (verified)** — $2
  - [x] **NO REGRESSION** — $3
EOF
}
good_leaf() {
  leaf_with '`cargo build` → `error[E0432]` at crates/app/src/main.rs:4.' \
            'before: `test result: FAILED`; after: `test result: ok`.' \
            '`cargo test` → `test result: ok. 42 passed; 0 failed`.'
}
MSG="$WORK/subject.txt"; printf 'PROBE-0001 (leaf TREE.1): a change\n' > "$MSG"; export SPINE_COMMIT_MSG="$MSG"

codechange() { printf 'fn main() { println!("changed"); }\n' > "$1/crates/app/src/main.rs"; }

probe() { # label · repo · expected exit (or nonzero) · expected substring
  local label="$1" d="$2" want="$3" want_txt="${4:-}" out rc ok=1
  out="$(cd "$d" && bash scripts/check_task_acceptance.sh 2>&1)"; rc=$?
  case "$want" in nonzero) [ "$rc" -ne 0 ] || ok=0 ;; *) [ "$rc" -eq "$want" ] || ok=0 ;; esac
  [ -n "$want_txt" ] && { printf '%s' "$out" | grep -qF "$want_txt" || ok=0; }
  if [ "$ok" -eq 1 ]; then
    printf '  ✓ %-10s exit=%s  %s\n' "$label" "$rc" "${want_txt:-<any>}"; pass=$((pass+1))
  else
    printf '  ✗ %-10s exit=%s (wanted %s / %s)\n' "$label" "$rc" "$want" "${want_txt:-<any>}"
    printf '%s\n' "$out" | sed 's/^/        /'; fail=$((fail+1))
  fi
}

echo "== TASK-ACCEPTANCE probes =="

# ---------------------------------------------------------------- GREEN-1: the compliant case
d="$(mkrepo green1)"; codechange "$d"; good_leaf > "$d/docs/tasks/TREE.md"
git -C "$d" add -A >/dev/null
probe GREEN-1 "$d" 0 "TASK-ACCEPTANCE: OK"

# ---------------------------------------------------------------- RED-1: code, no owning leaf
d="$(mkrepo red1)"; codechange "$d"
git -C "$d" add -A >/dev/null
probe RED-1 "$d" nonzero "is not in this change's snapshot"

# ---------------------------------------------------------------- RED-2: a box left unticked
d="$(mkrepo red2)"; codechange "$d"
good_leaf | sed 's/- \[x\] \*\*NO REGRESSION\*\*/- [ ] **NO REGRESSION**/' > "$d/docs/tasks/TREE.md"
git -C "$d" add -A >/dev/null
probe RED-2 "$d" nonzero "is present but NOT ticked"

# ---------------------------------------------------------------- RED-3: ticked, no evidence
d="$(mkrepo red3)"; codechange "$d"
leaf_with 'I looked at it and worked out what was wrong.' 'it works now.' 'nothing else broke.' > "$d/docs/tasks/TREE.md"
git -C "$d" add -A >/dev/null
probe RED-3 "$d" nonzero "no tool output sits INSIDE a code span"

# ---------------------------------------------------------------- ⭐⭐ CTRL-1: outside the box
# The evidence IS in the file, just not in the bullet it is supposed to back. A whole-file grep
# passes this; a box-scoped check must not.
d="$(mkrepo ctrl1)"; codechange "$d"
{ printf '# TREE\n\nEarlier in this file, unrelated prose mentioning `cargo test` and `test result: ok. 9 passed`.\n\n'
  leaf_with 'I looked at it and worked out what was wrong.' 'it works now.' 'nothing else broke.' | sed '1,2d'; } > "$d/docs/tasks/TREE.md"
git -C "$d" add -A >/dev/null
whole_file_would_pass=0
grep -qE 'test result: (ok|FAILED)' "$d/docs/tasks/TREE.md" && whole_file_would_pass=1
out="$(cd "$d" && bash scripts/check_task_acceptance.sh 2>&1)"; rc=$?
if [ "$whole_file_would_pass" -eq 1 ] && [ "$rc" -ne 0 ]; then
  printf '  ✓ %-10s a whole-file grep PASSES this leaf; the box-scoped check REJECTS it ⇒ scoping is real\n' "CTRL-1"
  pass=$((pass+1))
else
  printf '  ✗ %-10s wholefile=%s exit=%s — fixture does not isolate box-scoping\n' "CTRL-1" "$whole_file_would_pass" "$rc"
  fail=$((fail+1))
fi

# ---------------------------------------------------------------- ⭐ CTRL-2: cross-file leakage
# A co-staged, unrelated leaf carries the tokens; the leaf under test carries none.
d="$(mkrepo ctrl2)"; codechange "$d"
leaf_with 'I looked at it and worked out what was wrong.' 'it works now.' 'nothing else broke.' > "$d/docs/tasks/TREE.md"
good_leaf > "$d/docs/tasks/OTHER.md"
git -C "$d" add -A >/dev/null
probe CTRL-2 "$d" nonzero "no tool output sits INSIDE a code span"

# ---------------------------------------------------------------- CTRL-3: does not block docs
# A pure-docs change is not governed by this doctrine and must pass untouched.
d="$(mkrepo ctrl3)"
printf '# notes\nsome documentation edit\n' > "$d/docs/tasks/TREE.md"
git -C "$d" add -A >/dev/null
probe CTRL-3 "$d" 0 ""

# ---------------------------------------------------------------- ⭐ CTRL-4: the project seam
# A project declares its OWN tool's signature; a box evidenced only by that token must pass.
# This is what keeps the check neutral instead of hardcoding one project's vocabulary.
d="$(mkrepo ctrl4)"
# ⛔ The seam is read AS OF THE LAST COMMIT (BK-06: a commit cannot loosen the gate that judges it),
#    so the declaration is committed first and the evidenced leaf is judged in the NEXT change.
mkdir -p "$d/.doctrine"
printf '# our own tools\nWIDGET-COVERAGE:\n' > "$d/.doctrine/evidence_tokens.txt"
git -C "$d" add -A >/dev/null 2>&1; git -C "$d" commit -qm "SEED-0002: declare the seam" >/dev/null 2>&1
codechange "$d"
leaf_with '`WIDGET-COVERAGE: missing=3` located it.' '`WIDGET-COVERAGE: missing=0` after the fix.' '`WIDGET-COVERAGE: missing=0` across all suites.' > "$d/docs/tasks/TREE.md"
git -C "$d" add -A >/dev/null
probe CTRL-4 "$d" 0 "TASK-ACCEPTANCE: OK"

# and the same leaf WITHOUT the declaration must fail — proving the seam did the work
d2="$(mkrepo ctrl4b)"; codechange "$d2"
cp "$d/docs/tasks/TREE.md" "$d2/docs/tasks/TREE.md"
git -C "$d2" add -A >/dev/null
probe CTRL-4b "$d2" nonzero "no tool output sits INSIDE a code span"

# ---------------------------------------------------------------- CTRL-5: the blank form
# TEMPLATE.md is the form authors COPY; its boxes are deliberately unticked. Treating it as a
# leaf would block every commit that touches the template. This arm was added because the check
# did exactly that on its own first commit -- a FALSE POSITIVE, unlike the refusals before it.
d="$(mkrepo ctrl5)"; codechange "$d"; good_leaf > "$d/docs/tasks/TREE.md"
cat > "$d/docs/tasks/TEMPLATE.md" <<'EOF'
# <TREE-ID>

- ID: `<TREE-ID>.1`
  - [ ] **ROOT CAUSE (WHY + WHERE)** — <tool output>
  - [ ] **ADDRESSED (verified)** — <before -> after>
  - [ ] **NO REGRESSION** — <suite re-run>
EOF
git -C "$d" add -A >/dev/null
probe CTRL-5 "$d" 0 "TASK-ACCEPTANCE: OK"

echo
printf 'probes: %d pass / %d fail\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
