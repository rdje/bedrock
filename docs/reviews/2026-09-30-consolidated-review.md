# bedrock — consolidated review and enhancement list

- **Repository:** <https://github.com/rdje/bedrock>
- **Reviewed commit:** `340fe2faeb543c3cecd91187e0838f1ddc89b12b` (`bedrock-scaffold 0.6.1`, the default-branch tip on the review date)
- **Review date:** 2026-09-30
- **Inputs:** an independent executed review (items `BK-xx`, new in this document) and the ChatGPT review supplied by the maintainer (items `BR-xx`, kept with their original IDs so the two documents cross-reference).
- **Revision 2 (same day):** adds §5, a neutrality audit against the maintainer's contract that bedrock be project-, harness- and language-neutral (items `NT-xx`), an interim language-neutral ownership backstop for existing children (§2.1), and the resulting changes to earlier items.
- **Scope:** template generation, bootstrap, the doctrine driver and every check, hooks, CI, the scaffold updater, and the documentation that describes them. Nothing was modified or pushed upstream.

---

## 0. Method and evidence labels

Every `BK` finding marked **Executed** was reproduced by running bedrock's own scripts and hooks in a disposable repository that simulates GitHub's *Use this template* (the reviewed tree imported as a single `Initial commit`), bootstrapped with `./scripts/bootstrap.sh demo`, and committed with a valid subject. Section 10 contains the harness and the exact commands, so the implementing agent can re-run each finding before and after its fix.

- **Executed** — observed by running the current code.
- **Inspection** — follows from reading the code; not run.
- **Reported (ChatGPT)** — from the ChatGPT review. The status column says whether this review re-observed it.

Environment: Ubuntu 24, bash, GNU sed and grep, mawk, git 2.43, shellcheck 0.11.

Not covered: real macOS/BSD execution, real GitHub-hosted child repositories and Actions runs, repository settings (the GitHub API was rate-limited during the review, so the *Template repository* flag and branch protection could not be read), and Rust builds (no Rust toolchain in the environment).

---

## 1. Verdict

The design is worth keeping. The four-layer memory model, task trees, a single doctrine driver with a project slot, evidence-carrying checklists and the hook + CI layering are sound, and several checks are carefully built (the README line-and-byte cap, the gap-claim census's added-line arithmetic, the waiver fail-open fix).

The problem is that enforcement is considerably weaker than the documentation claims, and the failure is almost always the same: **a gate reports green without having judged the change it exists to judge.** Four themes cover most findings.

1. **Ownership and evidence are not bound to the change.** Any old ticked checklist in any staged tree file satisfies the gate for any new code change (BK-01). Prose satisfies the evidence test (BK-03). The gate's own configuration, the hooks and the CI workflow can all be changed with no leaf (BK-05, BK-06). Bedrock's own last five code commits were checked against the wrong leaf (BK-02).
2. **Errors and absences turn into green.** Git failures, a lost executable bit, deleted mandatory documents and invalid configuration all produce passes (BK-13, BK-14, BK-17, BR-05).
3. **Creating and upgrading projects is not safe.** Bootstrap writes evidence that contradicts itself and accepts names that break the project (BK-04). A child bootstrapped without a name believes it *is* bedrock (BK-18). The updater's file list is frozen inside each child, so upstream fixes to it never arrive and new checks arrive half-installed (BK-09, BK-10, BR-01).
4. **The spine is Rust- and Claude-shaped, while its contract is project-, harness- and language-neutral.** Every child receives a Rust project. Dart, Perl and Julia code in ordinary locations passes the ownership gates with no leaf. The evidence test matches none of eight non-Rust ecosystems' test output. `CLAUDE.md` is mandatory. §5 audits this in full (NT-01 to NT-14, with BK-07, BR-07 and BR-19).

Fixing these is worth more than adding doctrines, and none of it requires abandoning the architecture.

---

## 2. Act now — protecting existing children (StitchCAD and others)

Interim steps for projects already spawned. They do not replace the upstream fixes.

1. **Do not run a child's existing `scripts/update_scaffold.sh`.** Its overwrite list lives in the child's own copy (BK-09). Even after D17 is fixed upstream, that copy will keep overwriting `docs/TASK_TREE.md`, `TOOLBOX.md`, `README_POLICY.md` and `docs/tasks/TEMPLATE.md`, and will re-insert a `BEDROCK-MAINTENANCE` row linking to a file that does not exist in the child. Replace the updater by hand from the fixed release first, then run it.
2. **If an update has already run,** compare those four files with the last commit before the update (`git diff <commit> -- <file>`) and restore project content with `git checkout <commit> -- <file>`.
3. **Review code commits by hand for real ownership** until BK-01 is fixed: check that the leaf named in the subject gained its checklist and evidence in that same commit (`git show <sha> -- docs/tasks/`). A commit whose only task-file change is unrelated to the code is not owned, whatever the gate says. The shipped `docs/tasks/BOOTSTRAP.md` is the easiest accidental donor.
4. **Activate hooks on every clone:** `git config core.hooksPath .githooks` (or `make hooks`). A second clone of a child has none (BR-21).
5. **For any non-Rust child (C, Julia, Dart, Perl, …), the gates do not see most of your code today** (NT-03). Two interim measures, both in files the updater does not overwrite:
   - install the language-neutral ownership backstop in §2.1 as `scripts/check_doctrines.project.sh`;
   - if you also want TASK-ACCEPTANCE to judge your code, write `.doctrine/code_paths.txt` as **extended regular expressions, not globs**, e.g. `\.(c|h)$`, `\.jl$`, `\.dart$`, `\.(pm|pl|t)$`, `(^|/)CMakeLists\.txt$`, `(^|/)\.githooks/`, `(^|/)\.github/workflows/`. `TASK-TREE-OWNERSHIP` ignores this file (its patterns are hardcoded Rust globs), which is why the backstop is needed.
6. **Protect the default branch** with a required status check on the `doctrines` workflow and restricted direct pushes. A failing Actions run does not block a merge by itself (BR-04).
7. **Always bootstrap with a name** (`./scripts/bootstrap.sh <name>`, never `make bootstrap`, BK-18), and in the printed commit command replace `<NAME>` with the project name in capitals before running it (BR-11).

### 2.1 Interim language-neutral ownership backstop

A project-slot version of NT-03's rule: any staged path that is not Markdown (or `.gitignore`, `LICENSE*`) needs a staged top-level task-tree file. It covers every language, deletions and renames, and fails closed if git fails.

It was tested in a bootstrapped child:

- a staged `lib/app.dart` with no task file is refused;
- a README-only change passes;
- a staged deletion of `crates/app/src/main.rs` with no task file is refused.

It does **not** fix BK-01, because any staged tree file still satisfies it. It is a backstop until the upstream redesign, not a replacement.

```bash
#!/usr/bin/env bash
# scripts/check_doctrines.project.sh — INTERIM language-neutral ownership backstop (deny-by-default).
# Project-owned: the scaffold updater does not overwrite this file.
# Any staged path that is not documentation needs a staged top-level task-tree file.
set -uo pipefail
ROOT="$(git rev-parse --show-toplevel)" || { echo "PROJECT: git failed — REFUSED" >&2; exit 2; }
cd "$ROOT" || exit 2
staged="$(git diff --cached --name-only --diff-filter=ACDMRT)" || { echo "PROJECT: git diff failed — REFUSED" >&2; exit 2; }
[ -n "$staged" ] || exit 0
governed="$(printf '%s\n' "$staged" | grep -vE '\.md$|^\.gitignore$|^LICENSE' || true)"
trees="$(printf '%s\n' "$staged" | grep -E '^docs/tasks/[^/]+\.md$' | grep -vx 'docs/tasks/TEMPLATE.md' || true)"
if [ -n "$governed" ] && [ -z "$trees" ]; then
  echo "PROJECT (neutral ownership backstop): non-documentation files are staged with no task-tree file:" >&2
  printf '%s\n' "$governed" | sed 's/^/    /' >&2
  exit 1
fi
exit 0
```

Keep any project checks you already have in this file; append them after the backstop's logic rather than replacing it. Make sure the file stays executable (BK-14).

---

## 3. Consolidated list

Priorities follow the ChatGPT review. **P0:** project data can be lost, or a binding gate reports success without judging the change. **P1:** creation, upgrade or normal workflows break or mislead. **P2:** narrower gaps, documentation and hygiene.

| ID | P | Enhancement | Area | Status |
| --- | --- | --- | --- | --- |
| BK-01 | P0 | Require evidence to be new in the commit; today a done leaf's old checklist owns any later change | Gate | Executed |
| BK-02 | P1 | Replay the gate over bedrock's own history; its last five code commits were judged against leaf .2.4 | Gate | Executed |
| BK-03 | P0 | Stop accepting prose as evidence; match boxes by label, not keyword | Gate | Executed |
| BK-04 | P0 | Bootstrap must validate names and generate only truthful evidence | Bootstrap | Executed |
| BK-05 | P0 | Govern changes to hooks, CI workflows and doctrine config | Gate | Executed |
| BK-06 | P0 | Read gate configuration from the before-snapshot so a commit cannot weaken its own gate | Gate | Executed |
| BK-07 | P1 | One documented, validated format for code paths; non-Rust presets | Neutrality | Executed |
| BK-08 | P1 | Make the unowned-change exception consistent and durable, or remove it | Gate | Executed |
| BK-09 | P0 | Ship the updater manifest with the source; updater replaces itself first | Updater | Executed |
| BK-10 | P1 | Ship migrations; make upgrade commits pass the project's own gates | Updater | Executed |
| BK-11 | P1 | Fix the commit-msg trailer rule (blocks humans, misses agents) | Hooks | Executed |
| BK-12 | P1 | Fix Knowledge Map comment stripping that silently deletes content | Map | Executed |
| BK-13 | P1 | MEMORY-ARCH must check the documents the spine depends on | Gate | Executed |
| BK-14 | P1 | Fail when the project slot exists but is not executable | Driver | Executed |
| BK-15 | P2 | One definition of a tree file across all checks | Gate | Executed |
| BK-16 | P2 | Census and waiver-owner tests must not accept ordinary English | Doctrines | Executed |
| BK-17 | P0 | Fail closed when git itself fails | Driver | Executed |
| BK-18 | P1 | Explicit bootstrap modes; detect an uninitialised child | Bootstrap | Executed |
| BK-19 | P1 | Run the enforcer's own self-tests, probes and shellcheck in CI | CI | Executed and Inspection |
| BK-20 | P2 | Move caps from environment variables to tracked config | Config | Inspection |
| BK-21 | P2 | Correct documentation that contradicts the implementation | Docs | Inspection |
| BK-22 | P2 | Rust starter hygiene: toolchain pin, lockfile, flags (applies to the Rust pack, NT-01) | Rust | Inspection |
| BK-23 | P2 | CI workflow hygiene and documented repository settings | CI | Inspection |
| NT-01 | P1 | Default child contains no language; the Rust starter becomes a pack | Neutrality | Inspection |
| NT-02 | P1 | Bootstrap core does neutral steps only; packs bring install hooks and their own evidence | Neutrality | Executed |
| NT-03 | P0 | Govern everything except declared documentation (deny-by-default classification) | Neutrality | Executed |
| NT-04 | P1 | Tool-independent evidence shape; native signatures only via packs | Neutrality | Executed |
| NT-05 | P1 | Project-declared commands; cargo and make out of the spine | Neutrality | Inspection |
| NT-06 | P2 | Declared docs surface; mdBook becomes a docs pack | Neutrality | Inspection |
| NT-07 | P2 | Scratch files outside the worktree, not in Rust's target/ | Neutrality | Executed |
| NT-08 | P1 | AGENTS.md canonical and the only required agent file | Neutrality | Executed |
| NT-09 | P2 | Harness identities and exclusions as data, not code | Neutrality | Inspection |
| NT-10 | P2 | Remove originating-project residue from shipped files | Neutrality | Inspection |
| NT-11 | P1 | Restate bedrock's admission test for all three axes | Neutrality | Inspection |
| NT-12 | P1 | Minimal declared runtime; no Python requirement; POSIX regex classes | Neutrality | Inspection |
| NT-13 | P2 | Language CI in packs; spine CI on Linux and macOS | Neutrality | Inspection |
| NT-14 | P1 | Test neutrality mechanically in bedrock's CI | Neutrality | Inspection |
| BR-01 | P0 | D17: updater overwrites consumer-owned files | Updater | Confirmed, Executed |
| BR-02 | P0 | D15: file-scoped evidence is not leaf ownership | Gate | Confirmed via BK-02 |
| BR-03 | P0 | Checks read the worktree instead of the index | Gate | Reported; inspection agrees |
| BR-04 | P0 | CI judges an empty index; no per-commit coverage | CI | Reported; inspection agrees |
| BR-05 | P0 | Operational errors reported as green | Driver | Reported; extended by BK-17 |
| BR-06 | P0 | Bootstrap has no preflight or safe retry | Bootstrap | Reported; consistent with BK-04 |
| BR-07 | P1 | D25: inconsistent code classification across checks | Gate | Reported; extended by BK-07 |
| BR-08 | P0 | Deletions and renames escape ownership | Gate | Reported; inspection agrees |
| BR-09 | P1 | Updater resolves the caller's repository; source not pinned | Updater | Reported; inspection agrees |
| BR-10 | P1 | GNU-only `sed -i`; portable, mode-preserving edits | Bootstrap | Reported; inspection agrees |
| BR-11 | P1 | Printed bootstrap commit command fails as printed | Bootstrap | Confirmed, Executed |
| BR-12 | P1 | Child keeps bedrock history; rerun contract undefined | Bootstrap | Reported; inspection agrees |
| BR-13 | P1 | AGENTS.md should carry the canonical instructions | Docs | Reported; inspection agrees |
| BR-14 | P1 | Pre-commit stages a map built from untracked files | Map | Reported |
| BR-15 | P1 | Table checker disagrees with GFM on pipes in code spans | Doctrines | Reported |
| BR-16 | P1 | Hermetic fixtures and end-to-end child and upgrade tests | Tests | Reported |
| BR-17 | P2 | Waiver check re-judges historical waivers | Doctrines | Reported; inspection agrees |
| BR-18 | P2 | Lesson promotion promises retrieval the map does not provide | Doctrines | Reported; inspection agrees |
| BR-19 | P1 | Separate the neutral spine from optional Rust, mdBook and harness packs | Neutrality | Reported; inspection agrees |
| BR-20 | P1 | No licence files despite `MIT OR Apache-2.0` metadata | Legal | Confirmed, Inspection |
| BR-21 | P2 | Precise commit-validation, hook-installation and CI guarantees | Hooks | Confirmed in part, Executed |
| BR-22 | P2 | Documentation consolidation, path handling, optional packs | Docs | Reported |

---

## 4. Detailed findings

### A. The acceptance and ownership gate

#### BK-01 — Evidence is never required to be new: any old ticked checklist owns any new change (P0, Executed)

**Observed.** In a bootstrapped child whose bootstrap commit had landed, I replaced `crates/app/src/main.rs` entirely (17 lines to 1, test module deleted) and staged it with a one-character edit to the shipped, `done` leaf `docs/tasks/BOOTSTRAP.md` (a trailing space after `Owner: repo-local workflow`). `TASK-TREE-OWNERSHIP` exited 0, `TASK-ACCEPTANCE` exited 0, and `git commit -F` through the real hooks exited 0 with the subject `DEMO-APP-0002 (leaf BOOTSTRAP.1): rewrite main`.

**Root cause.** `scripts/check_task_acceptance.sh` reads each staged `docs/tasks/*.md` in full and looks for ticked boxes carrying signature tokens anywhere in the file. It never asks whether the checklist or its evidence was written *in this commit*, whether the leaf is the one the commit names, or whether the leaf is still open. `TASK-TREE-OWNERSHIP` only requires that some task file be touched.

The shipped `docs/tasks/TEMPLATE.md` makes this structural: it has a single file-level `## Acceptance Checklist` for a multi-leaf tree. Once a tree's first code leaf ticks those boxes, every later code change that touches the tree file passes.

This is a larger hole than D15 (BR-02). D15 lets one leaf's evidence answer for another leaf. BK-01 lets yesterday's evidence answer for today's change, even in a single-leaf tree.

**Required change.** Bind evidence to the change (the full contract is in §6):

- the commit message names the leaf (`(leaf <ID>)`), checked at `commit-msg` time locally and against the real messages in CI;
- the named leaf exists in a staged tree file and its section changes in this commit (status transition or commit-log row);
- the three hard-gated boxes of that leaf are ticked **and** their evidence lines are among the lines added or modified by this commit (`check_gap_claims.sh` already contains the added-line arithmetic, `added_line_numbers`, needed for this);
- a leaf already `done` with a recorded commit cannot own a new code commit; reopen it or add a child leaf.

Move the checklist inside each leaf in `TEMPLATE.md` (as `BOOTSTRAP.md` and the maintenance tree already do) and remove the file-level checklist.

**Tests.** The BK-01 scenario must be refused. A leaf that adds its own evidence in the same commit must pass. A second commit re-using the first commit's evidence must be refused.

#### BK-02 — Bedrock's own recent code commits were judged against the wrong leaf (P1, Executed)

**Observed.** Running the check's own box extractor over `docs/tasks/BEDROCK-MAINTENANCE.md` returns lines 261, 265 and 267: the `ROOT CAUSE`, `ADDRESSED` and `NO REGRESSION` boxes of leaf `.2.4`. The five code commits since then (`e6cea33`, `ec3982b`, `c769113`, `f210a96`, `340fe2f`, all touching `scripts/*.sh`) were therefore validated against `.2.4`'s evidence. The checklists of `.2.5`, `.2.6` and `.2.7` were never judged by the gate.

**Why it matters.** It is a concrete in-repository instance of D15, and it means the self-hosting claim (bedrock practises what it preaches) was vacuous for the releases that introduced most of the current doctrines.

**Required change.** After BK-01 and BR-02 land, replay the new acceptance contract over bedrock's own history (a CI job or a one-off maintenance leaf) and record the result, including any commit that would now fail. Do not rewrite history; record the finding in the maintenance tree and the CHANGELOG.

#### BK-03 — Prose passes as tool evidence, and boxes are found by keyword (P0, Executed)

**Observed.** A new tree file with these boxes, staged with a code change, passes `TASK-ACCEPTANCE`:

```markdown
- [x] **ROOT CAUSE (WHY + WHERE)** — I believe it is the parser, see section 1.2.3.
- [x] **ADDRESSED (verified)** — should exit 0 now.
- [x] **NO REGRESSION** — will run cargo test later.
```

This checklist, with the real `ADDRESSED` box **unticked**, also passes, because the extractor takes the first box whose text contains `addressed`:

```markdown
- [x] **ROOT CAUSE (WHY + WHERE)** — `cargo test` → `test result: FAILED`, rc=101 at main.rs:1.
- [x] **FIX** — addressed by rewriting main (`rc=0`).
- [ ] **ADDRESSED (verified)** — TODO
- [x] **NO REGRESSION** — `cargo test` → `test result: ok`.
```

**Root cause.** The default signature list accepts any version-shaped number (`[0-9]+\.[0-9]+\.[0-9]+`), `exit 0` inside a sentence, the phrase `cargo test` without output, and bare words such as `flamegraph`, `self-time` and `call-graph`. `rc=0` can simply be typed. The label matcher runs `match(tolower(line), kw)` over the whole box line, so any earlier box mentioning the keyword is taken as the labelled box.

**Required change.**

- Anchor labels: a box is `- [x] **ROOT CAUSE`, bold label at the start, exactly one per label per leaf; duplicate or missing labels are errors.
- Require evidence in a recognisable form (a command and an output line, in an inline code span or a fenced block) and remove bare version numbers and bare tool names from the default signatures. Project-specific signatures stay in `.doctrine/evidence_tokens.txt`.
- Keep the honest limit visible in the docs, as the check's header already does: the gate proves something re-runnable was cited, not that it is true. Offer the "un-fakeable leg" that header mentions as an optional CI step: `evidence-cmd:` lines whose commands CI re-runs from an allow-list.

#### BK-05 — The enforcement layer itself can be changed with no owning leaf (P0, Executed)

**Observed.** Replacing `.githooks/pre-commit` with `exit 0` and deleting `.github/workflows/doctrines.yml` in one commit, with no task file staged: all 13 checks green.

**Root cause.** Neither code classification covers `.githooks/` (hook files have no `.sh` extension), `.github/workflows/` or `.doctrine/`, and the ownership check also misses `scripts/` and `knowledge-map/scripts/`.

**Required change.** Define a built-in "spine" set that projects cannot remove: `.githooks/**`, `.github/workflows/**`, `.doctrine/**`, `scripts/check_*.sh`, `knowledge-map/scripts/**`, `Makefile`. Changes to it always require an owning leaf, in bedrock and in every child. Because a deleted workflow cannot fail itself, document that the default branch must require the `doctrines` status check (a required check that never reports blocks the merge) and restrict direct pushes.

#### BK-06 — A commit can weaken its own gate (P0, Executed)

**Observed.** Setting `.doctrine/code_paths.txt` to `^nothing-matches-this$` in the same commit as a code change makes `TASK-ACCEPTANCE` pass. (Ownership still refuses a `.rs` file only because its patterns are hardcoded.) With a new `scripts/new_tool.sh` instead of a `.rs` file, the whole driver is green.

**Root cause.** Configuration is read from the working tree at evaluation time, so the commit being judged supplies its own rules. ChatGPT's BR-03 says configuration should come from "the same snapshot"; that is necessary but not sufficient, because reading the new configuration from the index still lets a commit loosen its own gate.

**Required change.** Read gate-defining configuration (`.doctrine/*`, caps) from the **before** snapshot: `HEAD` locally, the parent commit in CI, built-in defaults for the first commit. A configuration change takes effect from the next commit and is itself a governed change under BK-05.

#### BK-07 — Code paths are documented as globs and as regexes; non-Rust projects are misclassified (P1, Executed)

**Observed.** The header of `scripts/check_task_acceptance.sh` says "one glob per line"; `.doctrine/README.md` says "one extended regular expression per line". A C project following the script header writes `*.c`, `*.h` and `CMakeLists.txt`. GNU grep warns `* at start of expression` (the warning goes to `/dev/null`) and effectively matches any character followed by `c`. A one-line typo fix in `docs/TASK_TREE_README.md` (it contains "oc") was then refused as an unowned code change. Another grep implementation could reject the pattern instead, which the `|| true` would turn into an empty code list and a silent pass (not tested here).

`TASK-TREE-OWNERSHIP` has no configuration at all. Its `case` patterns are Rust-only (`*.rs`, `crates/*`, `src/*`, `build.rs`, `Cargo.toml`, `Cargo.lock`), so C sources are invisible to it whatever the project declares.

**Required change.** One declaration, one format, used by every check and validated at load (exit 2 on an invalid entry). The recommended format is **git pathspecs** (`:(glob)**/*.c`, `:(glob)src/**`) evaluated by git itself with `git diff --cached --name-only -z -- <pathspecs>`: no hand-written matcher, glob semantics users already know, identical behaviour on every platform. Ship commented presets for Rust, C/C++, Python, Go and TypeScript, and have bootstrap require a preset choice so a new child is never silently unclassified. This absorbs BR-07 (D25). *Revision 2:* NT-03 supersedes the preset approach with a deny-by-default rule (everything except declared documentation is governed), so presets become unnecessary for correctness; the one-format, validated, before-snapshot requirements here still apply to the exemption list.

#### BK-08 — The documented bypass works for one check and not the other (P1, Executed)

**Observed.** With a staged `.rs` change and no leaf, `SPINE_ALLOW_UNOWNED=1 scripts/check_doctrines.sh` gives `TASK-TREE-OWNERSHIP` ✅ and `TASK-ACCEPTANCE` ❌; the commit is blocked. The ownership check's own error message recommends the variable.

**Required change.** Remove the bypass, or replace it with a durable, reviewable mechanism honoured by every check and visible in CI, such as a `Spine-Exception: <reason>` commit trailer that CI reports and counts. An environment variable leaves no record and never reaches CI.

#### BK-15 — Markdown in `docs/tasks/` subdirectories is treated as a leaf (P2, Executed)

**Observed.** Staging `docs/tasks/artifacts/perf/README.md` next to a correctly evidenced leaf and a code change: `TASK-ACCEPTANCE` fails with "has no 'ROOT CAUSE' box" for the README.

**Root cause.** Checks disagree on what a tree file is. Acceptance, waiver and lesson checks use `^docs/tasks/.*\.md$` (any depth); routing and gap-claim checks use `^docs/tasks/[^/]*\.md$` (top level only).

**Required change.** One shared definition: top-level `docs/tasks/*.md`, excluding `TEMPLATE.md`.

### B. Silent greens: errors, absences and CI

#### BK-17 — When git itself fails, the ownership gates report green (P0, Executed)

**Observed.** With an unowned `.rs` change staged, the driver fails as expected. After making git refuse the repository (`fatal: detected dubious ownership`, the `safe.directory` protection that fires routinely in containers and CI runners when the checkout owner differs from the running user), the same staged change gives `TASK-TREE-OWNERSHIP` ✅ and `TASK-ACCEPTANCE` ✅. The run still failed, but only because `KNOWLEDGE-MAP` happened to break as well; the two gates that exist to catch this change reported it as fine.

**Root cause.** Every check starts with `ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"` with no `set -e` and no check (shellcheck SC2164, 10 occurrences). A failed `rev-parse` leaves `ROOT` empty and `cd ""` succeeds. Staged files are listed with `git diff --cached … 2>/dev/null || true`, so a git error becomes "nothing staged", which passes.

**Required change.** This extends BR-05. Use a shared prelude that fails closed (`ROOT=$(git rev-parse --show-toplevel) || exit 2; cd "$ROOT" || exit 2`) and check every git read. Adopt one exit contract for all checks (0 pass, 1 breach, 2 cannot evaluate) and have the driver report 2 as `REFUSED` and fail. Never put `|| true` after a read that the verdict depends on.

#### BK-14 — The project slot is silently skipped when it is not executable (P1, Executed)

**Observed.** A `scripts/check_doctrines.project.sh` that always exits 1 blocks the commit. The same file without its executable bit is dropped silently (the driver runs 12 checks) and everything is green. The bit is easily lost: `core.fileMode=false` (the default on Windows), a zip download, an editor that recreates files.

**Required change.** Treat "present but not executable" as a failure for both optional entries (`PROJECT-SPECIFIC`, `KNOWLEDGE-MAP`), or invoke them with `bash <path>` so the bit does not matter. Reserve "skip" for a deliberately absent subsystem, and print that it was skipped. CI's `chmod +x … || true` hides the problem there, so it bites locally only.

#### BK-13 — MEMORY-ARCH does not protect the documents the spine depends on (P1, Executed)

**Observed.** Deleting `MEMORY_ARCHITECTURE.md`, `AGENTS.md`, `DOCTRINE_ENFORCEMENT.md`, `TOOLBOX.md` and `COMMIT.md` in one commit: all 13 checks green. The shipped check only tests `MEMORY.md`, `docs/decisions/`, `docs/TASK_TREE.md`, `docs/tasks/`, `README.md` and `CLAUDE.md`. The reference script printed in `MEMORY_ARCHITECTURE.md` §9 is stricter than the shipped one: it checks `MEMORY_ARCHITECTURE.md`, `AGENTS.md`, and that both bootstrap files point at the architecture document.

`MEMORY_ARCHITECTURE.md` §9 also states that CI validates every commit subject on the branch and that a non-compliant branch cannot merge. Neither is implemented: `doctrines.yml` runs the driver only, and blocking a merge needs repository settings.

**Required change.** Check the existence of every spine document in the maintained inventory (`MAINTAINING.md`, "File inventory") and that entry files point at the canonical instructions (BR-13). Either implement CI subject validation (BR-21) or correct §9, and state the repository settings needed for "cannot merge".

#### BK-19 — CI never tests the enforcer itself (P1, Executed and Inspection)

`doctrines.yml` runs the driver only. These are never run in CI, so a regression in a check is caught only if a maintainer remembers to run it by hand:

- the checks' own `--self-test` arms (TABLE-ARITY 8, LESSON-PROMOTION 9, LIVE-DOC-CURRENCY 3, ROUTING-EVIDENCE 5, GAP-CLAIM-CENSUS 10);
- the two probe drivers under `docs/tasks/artifacts/`;
- `bash -n` and shellcheck.

Shellcheck 0.11 reports 45 findings: SC2016 ×18, SC2015 ×11, SC2164 ×10 (the unchecked `cd` behind BK-17), SC2034 ×2, SC2012 ×2, SC2221 and SC2222 (overlapping `case` patterns in the ownership check). The SC2034 pair is meaningful: the waiver probe driver's `CTRL-1` captures `out_fix` and `out_unf` but asserts exit codes only, so a RED arm can pass for the wrong reason.

**Required change.** Add an `enforcer-selftest` job: every `--self-test`, both probe drivers, `bash -n`, shellcheck (with a checked-in baseline so existing notes do not block), and the end-to-end "generate a child, bootstrap, run the printed commit" test from BR-16. Ship it to children as well; they benefit from knowing their synced enforcer works.

### C. Creating a project (bootstrap)

#### BK-04 — Bootstrap writes evidence that contradicts itself, and accepts names that break the project (P0, Executed)

**Observed.**

- The generated `ROOT CAUSE` box contains the literal text `` (`rc=0`) `` after the crate-name count, hardcoded in `scripts/bootstrap.sh` (line 136). It is not the exit status of anything; it is the token that makes the box pass the evidence test. The real `grep -c` that finds zero remaining matches exits 1.
- With the name `a/b`, both `sed` substitutions fail ("unknown option to s"), the `… || true` swallows the failure, the script prints `✓ project name set to 'a/b'`, and the generated leaf records "1 before the run, 1 after" next to a ticked `ADDRESSED — crate renamed to a/b`. The crate is still named `app`. Exit 0.
- With `x&y`, `sed` interprets `&` and writes `name = "xname = "app"y"`, which is invalid TOML. Exit 0.
- `my.proj` and `Stitch CAD` are written as the crate name although Cargo rejects both. Exit 0.
- The "enforcer run inside this bootstrap", cited as ADDRESSED and NO REGRESSION evidence, ran with **nothing staged**, so the ownership and acceptance checks judged nothing.

**Required change.**

- Validate the name before any write, per use: a crate name (lower-case letters, digits, `-`, `_`, starting with a letter, or derived from the repository name), a display title (free text, escaped where written), and the work-unit prefix (an upper-case derivation, printed back). Refuse with exit 2 and a clear message.
- Stop interpolating user text into `sed` replacements. Do literal replacements (a small helper that receives the value as data), check that each edit changed exactly what it should, and fail otherwise.
- Generate evidence from real measurements only: capture actual exit codes and report the before and after counts as measured.
- Stage the bootstrap's own changes as an explicit file list and run the enforcer **against that index**, so the leaf's evidence is a real verdict. Otherwise say plainly that the pre-commit hook will judge the first commit, and do not cite the empty run.
- *Revision 2:* under the neutrality contract, the crate rename and its validation belong to the Rust pack's install hook (NT-02); the spine validates only the project name, title and work-unit prefix.

#### BK-18 — Bootstrap without a name leaves a child that believes it is bedrock (P1, Executed)

**Observed.** In a fresh one-commit child, `make bootstrap` exits 0 and leaves `MAINTAINING.md`, the `BEDROCK-MAINTENANCE` tree and bedrock's own `MEMORY.md` in place. `CLAUDE.md` then tells any agent that this *is* the bedrock template and that its job is to improve the template. The same happens when a user follows `CLAUDE.md`'s "First time in a fresh clone: run `scripts/bootstrap.sh` once", which shows no name argument. The Makefile's `bootstrap` target passes no name either.

**Required change.**

- Make the modes explicit. `bootstrap.sh <name>` initialises a new project. `bootstrap.sh --contributor` (or no argument **in an already initialised project**) only installs hooks. `bootstrap.sh --maintainer` is for bedrock itself. With no argument in an uninitialised copy, print usage and exit 2.
- Makefile: `make bootstrap NAME=<name>`, refusing an empty `NAME`.
- Give agents an identity check that does not depend on a copied file: the maintainer note in `CLAUDE.md` should tell the agent to compare `git remote get-url origin` with `rdje/bedrock` and, if it differs, to stop and run bootstrap with the project name.
- Add a guard to the shipped `doctrines.yml` so an uninitialised child is flagged on its first push:

```yaml
      - name: Refuse an uninitialised copy of the template
        if: github.repository != 'rdje/bedrock'
        run: |
          if [ -f MAINTAINING.md ]; then
            echo "::error::Created from the bedrock template but never initialised. Run ./scripts/bootstrap.sh <project-name> and commit."
            exit 1
          fi
```

GitHub's own `Initial commit` in a new child will fail this step until the bootstrap commit lands. That is the intended signal; use `::warning::` instead if a red first run is unwanted.

#### Creation notes confirming ChatGPT, and your documented workflow

- **BR-11 confirmed.** The printed commit with the literal `<NAME>` subject is rejected (exit 1); replacing it with `DEMO` succeeds. The 0.6.1 CHANGELOG entry says the printed commit was proven; as printed, it fails.
- **BR-21 confirmed.** A second `git clone` of an initialised child has no `core.hooksPath`, and `hello` passes as a commit subject.
- **Your documented creation workflow** (GitHub *Use this template*, clone, `./scripts/bootstrap.sh <name>`, run the printed commit, `git push`) has the right shape. Once BR-11 is fixed the printed command can be pasted as is. Two additions belong in the README: with `gh repo create <name> --template rdje/bedrock --clone` there is no separate `git clone` step (just `cd <name>`), and anyone who later clones the project only runs `git config core.hooksPath .githooks` (or `make hooks`), never the naming bootstrap.

### D. Upgrading children (the scaffold updater)

#### BK-09 — The updater's file list is frozen inside each child (P0, Executed)

**Observed.** A child created from bedrock 0.4.0 (`6cc8900`), bootstrapped, with its own tree `STITCH.md` registered in `docs/TASK_TREE.md`, ran **its own** `scripts/update_scaffold.sh` against current bedrock.

- It printed `✓ 23 scaffold file(s) synced to bedrock-scaffold 0.6.1.`
- The synced driver registers 13 checks, but the child's 0.4.0 list does not contain the five scripts added since. The gate showed `LIVE-DOC-CURRENCY`, `LESSON-PROMOTION`, `ROUTING-EVIDENCE`, `GAP-CLAIM-CENSUS` and `TABLE-ARITY-RATCHET` as missing, plus `KNOWLEDGE-MAP` failing.
- `docs/TASK_TREE.md` lost the project's `STITCH` row and gained bedrock's `BEDROCK-MAINTENANCE` row, linking to `tasks/BEDROCK-MAINTENANCE.md`, which does not exist in the child. No check detects the dead link.

**Root cause.** The `NEUTRAL` array lives in the child's copy of `update_scaffold.sh`, and the updater never updates itself (nor `bootstrap.sh`, the workflows or the Makefile). A child therefore always upgrades with the file list of the version it was **created** from. The same mechanism means that when D17 is fixed upstream by removing the four files from the list, existing children will keep overwriting them.

**Required change.**

- Ship the manifest **with the source**, for example `.bedrock/manifest`, listing each path, its ownership class (spine-owned, seed-once, project-owned) and the version that added or removed it. The updater reads the manifest from the fetched source, never from its own copy.
- Step 0 of every update: replace `update_scaffold.sh` from the fetched source and re-execute it.
- After syncing, verify that every script the driver registers exists and is executable, and do not write `DOCTRINE_VERSION` until the gate passes on the synced tree.
- In the first fixed release's notes, tell existing children to copy the new updater by hand once before running it.

#### BK-10 — Upgrades are blocked by content the old template created, and by the gate itself (P1, Executed)

**Observed.** Continuing BK-09 after restoring the missing scripts and regenerating the map, committing the upgrade through the hooks fails twice. `TASK-ACCEPTANCE` refuses because `scripts/*.sh` changed with no owning leaf. `LIVE-DOC-CURRENCY` refuses because `docs/tasks/STITCH.md` line 9 contains `` - Last updated: `YYYY-MM-DD` ``, a field the 0.4.0 task template shipped. Because LIVE-DOC-CURRENCY scans the whole repository, after the upgrade every tree created from the old template blocks every commit.

**Required change.**

- Ship **migrations** with releases. When a template changes shape, provide a scripted, reviewable migration for content generated from the earlier shape (here, removing the field from existing trees), run as part of the updater's plan.
- Introduce new whole-repository doctrines as ratchets (staged scope first, `--all` advisory), as the other checks already do, or bundle each with its migration.
- Have the updater seed an `UPDATE-<version>` leaf, the way bootstrap seeds `BOOTSTRAP`, with truthful evidence, and print the exact commit command, so an upgrade commit passes the project's own gates. The current instruction ("review `git diff`, run `make gate`, then commit") does not mention the leaf.

#### BR-01 and BR-09, confirmed and extended

BR-01's result (four project files overwritten) matches BK-09, and the `TASK_TREE.md` case is worse than data loss because it also injects a dead link. BR-09 stands: resolve the repository from the script's location and verify it with git (linked worktrees have a `.git` file, not a directory, which also defeats `bootstrap.sh`'s `[ -d .git ]` test), and fetch a named tag or commit rather than whatever the default branch holds. Local-path mode copies the entire source checkout, including `.git` and build output; export a commit instead.

### E. Other checks and hooks

#### BK-11 — The commit-msg trailer rule blocks humans and misses agents (P1, Executed)

| Trailer in the message | Hook today | Should be |
| --- | --- | --- |
| `Co-Authored-By: Claude Martin <claude.martin@example.fr>` | rejected | accepted (a human) |
| `Co-authored-by: Ana Souza <ana@cursor-labs.example>` | rejected | accepted (a human) |
| `Co-Developed-By: Claude <noreply@anthropic.com>` | accepted | rejected (an agent) |
| `Assisted-by: GitHub Copilot` | accepted | rejected (an agent) |

"Claude" is a common first name, notably in French. In addition:

- the pattern contains a duplicated alternative, `(co-authored-by|co-authored-by)`, probably meant to cover a second key;
- it scans every non-`#` line of the message rather than the trailer block, so body text is matched too;
- the subject check reads line 1 before git's cleanup, so a message whose first line is blank (which git strips) is rejected.

**Required change.** Parse trailers with `git interpret-trailers --parse`. Identify agents primarily by known bot addresses (such as `noreply@anthropic.com`), and by product name only as an exact full-name match, across every attribution key (`Co-Authored-By`, `Co-Developed-By`, `Assisted-By`, `Generated-By`). Run the subject check on `git stripspace --strip-comments` output. Add the four cases above as fixtures.

#### BK-12 — One-line HTML comments silently delete Knowledge Map content (P1, Executed)

**Observed.** With this `knowledge-map/subsystems.md`:

```markdown
<!-- curated input -->
- `crates/demo/` — the CLI entry point.
<!-- TODO: add the storage layer -->
- `crates/store/` — persistence.
- `crates/net/` — networking.
```

the generated map's "Key subsystems" section lists only `crates/store/` and `crates/net/`. The CLI entry point has disappeared.

**Root cause.** `sed '/^<!--/,/-->/d'`: a `sed` range looks for its end on the lines *after* its start, so a comment that opens and closes on one line starts a deletion that runs to the next `-->`, or to the end of the file.

**Required change.** Strip comments with a real parser (or an awk loop that handles same-line closure), add fixtures for single-line, multi-line and end-of-file comments, and warn when the curated section shrinks. Separately, the "Active task-trees" heading lists every tree file including `done` ones such as `BOOTSTRAP.md`; show status or rename the heading.

#### BK-16 — The census and waiver-owner tests are satisfied by ordinary English (P2, Executed)

**Observed.** A staged tree line "nothing checks the retry budget." is refused by GAP-CLAIM-CENSUS; the same line with "; make sure we revisit." appended passes, because `make ` is one of the census tokens (as are `cargo `, `a search of` and `searched the`). A WAIVER-ROUTING waiver with no owner is refused; the same waiver mentioning "this V1.2 migration" passes, because `V1.2` matches the leaf-ID owner pattern.

**Required change.** Accept census commands only inside code spans or fenced blocks. Accept a waiver owner only if the cited ID resolves to an existing leaf in `docs/tasks/`; that is checkable, and it turns "an owner was named" into "an owner exists". Add both cases as RED fixtures.

#### BK-20 — Caps can only be tuned by environment variables (P2, Inspection)

`README_LINE_CAP`, `README_BYTE_CAP`, `MEMORY_POINTER_LINE_CAP` and `MEMORY_POINTER_BYTE_CAP` are read from the environment. The comments say this lets a project ratchet without editing the spine, but an environment variable is not tracked: it reaches neither teammates' hooks nor CI, and any contributor can loosen a cap for one local commit. The only durable way to tighten a cap today is editing a spine file, which the updater then overwrites.

**Required change.** Read caps from a tracked `.doctrine/config`, taken from the before-snapshot (BK-06). Keep environment overrides, if at all, as a local convenience that CI ignores.

### F. Documentation, Rust starter and CI hygiene

#### BK-21 — Documentation contradicts the implementation (P2, Inspection)

- The acceptance checklist has six items in `DOCTRINE_ENFORCEMENT.md` (which says a leaf must record all six), five in `docs/tasks/TEMPLATE.md`, and three are gated. Keep one list and say which items are gated.
- `TEMPLATE.md` has one checklist per file; `BOOTSTRAP.md` and the maintenance tree have one per leaf. Standardise on per-leaf (BK-01).
- `CLAUDE.md` (bootstrap "seeds the first task-tree from ROADMAP.md"), `ROADMAP.md` ("run scripts/bootstrap.sh to seed the first task-tree(s)") and `LIVE_STATUS.md` promise something bootstrap explicitly does not do; its own header says it does not invent a task tree from the roadmap.
- The 0.6.1 CHANGELOG entry claims the printed commit was proven; as printed it fails (BR-11).
- `MEMORY_ARCHITECTURE.md` §7 says harness files are one-line pointers and the system of record is `README.md` plus that file. In bedrock, `CLAUDE.md` is the canonical body and `README.md` is a capped landing page (BR-13). The §9 CI claims are covered in BK-13.
- `docs/TASK_TREE.md` says ownership of "generated artifacts, or anything altering behavior" is enforced by `check_task_tree_ownership.sh`, which only matches Rust paths.
- `DEV_NOTES.md` puts bedrock's own dated lessons above the file's introduction and above the child's bootstrap entry, so every child inherits them (BR-12).
- `docs/decisions/TEMPLATE.md` recommends `[[slug]]` links, which GitHub does not render.
- `docs/book/book.toml` ships `git-repository-url = ""` and the title "Project Book"; bootstrap could fill both from `origin` and the project name.
- The `Cargo.toml` comments say cargo-generate substitutes `{{project-name}}`, but no field uses that placeholder (BR-22).

#### BK-22 — Rust starter hygiene (P2, Inspection)

*Revision 2:* under the neutrality contract all of this applies to the Rust language pack, not to the spine (NT-01).

- `rust-toolchain.toml` pins `channel = "stable"` while CI and `make check` deny every Clippy warning, so a new Rust release can turn CI red with no code change. Pin a version and bump it through a leaf.
- `.gitignore` says `Cargo.lock` is deliberately tracked for this binary starter, but none is committed; the first `cargo build` creates an untracked file. Commit it and build with `--locked` in CI.
- `cargo test --all` is the old spelling of `--workspace`. `COMMIT.md` step 2 omits `--all-features`, which CI and `make check` use.
- `rust.yml` runs in every child, including non-Rust ones (BR-19).

#### BK-23 — CI workflow hygiene and repository settings (P2, Inspection)

- Add `permissions: contents: read` to both workflows, `concurrency` to cancel superseded runs, a branch filter so a pull-request branch does not run twice (push and pull_request), commit-SHA pins for third-party actions such as `dtolnay/rust-toolchain`, and `workflow_dispatch`.
- Remove `chmod +x … || true` from CI; track and verify executable modes instead (BR-22).
- Document the settings a child must enable for the stated guarantees to hold: required status checks on the default branch and restricted direct pushes. Confirm bedrock itself has the *Template repository* flag set (not checked here).

### G. ChatGPT items in brief

Kept so this document stands alone. See the ChatGPT review for its full reproduction detail.

- **BR-01 (D17).** The updater copies whole files that projects fill in: `docs/TASK_TREE.md`, `TOOLBOX.md`, `README_POLICY.md`, `docs/tasks/TEMPLATE.md`. Fix with ownership classes, seed-once files, three-way merge or explicit conflicts for spine files, a dry run, a pinned source, unique sidecar files, and the version written only after validation.
- **BR-02 (D15).** Acceptance takes the first box per label per file, so in a multi-leaf tree one leaf's evidence answers for another's change. Bind the leaf named by the real commit message; define unambiguous sections; reject missing or duplicate boxes.
- **BR-03.** Checks read the worktree, so an unstaged fix hides a staged defect and a file deleted only from the worktree is skipped. Read the index locally and the committed tree in CI.
- **BR-04.** In CI the index is empty, so the driver judges nothing. A `HEAD^..HEAD` range only sees the last commit of a push; pull requests check out a synthetic merge commit; TABLE-ARITY compares a file with itself in CI; GAP-CLAIM needs hunk headers. Build a change context with before and after revisions for every introduced commit.
- **BR-05.** An invalid regex such as `[` in `code_paths.txt`, or a missing `python3` for the table check, produces green. Distinguish "no match" from "cannot evaluate".
- **BR-06.** Bootstrap deletes files before checking anything, discards an uncommitted `MEMORY.md` edit, and after a mid-way failure a retry skips the de-template step and leaves an obsolete tree index. Add preflight, staged application and a completion marker.
- **BR-07 (D25).** The acceptance default `(^|/)src/` classifies mdBook chapters under `docs/book/src/` as code, while ownership disagrees. One declaration for all checks (BK-07).
- **BR-08.** Every `--diff-filter=ACM` drops deletions and renames, so deleting or renaming source needs no leaf. Enumerate with status and NUL delimiters and classify both sides of a rename.
- **BR-09.** The updater resolves the repository from the caller's directory (running a child's updater from a parent repository overwrote the parent's file) and fetches an unpinned source.
- **BR-10.** Bootstrap's `sed -i` is GNU-only and fails on macOS. Portable edits need sibling temporary files, preserved modes, cleanup on failure, and separate validation of the repository name, crate name, title and work-unit prefix.
- **BR-11.** The printed commit command contains an unresolved `<NAME>` placeholder and fails as printed; it also uses `git add -A`, which can include unrelated files.
- **BR-12.** A child keeps bedrock's CHANGELOG and development history; rerunning bootstrap with another name exits 0 but renames nothing. Persist the project identity and define rerun behaviour.
- **BR-13.** `AGENTS.md` is only a pointer to `CLAUDE.md`. Put the complete shared instructions in `AGENTS.md` (or a neutral document it references) and make harness files simple pointers to it.
- **BR-14.** The pre-commit hook regenerates the Knowledge Map from the worktree and stages it, so the commit can link a file that is not tracked. Generate from the index and fail if generation fails.
- **BR-15.** The table checker treats a pipe inside a code span as protected; GFM splits cells on it unless it is escaped, and the self-test encodes the wrong expectation. Also missing: tables without outer pipes and header/delimiter mismatches.
- **BR-16.** Probe fixtures copy only one script and will break as dependencies are added; CI context variables could leak into fixture repositories. Make fixtures hermetic and add end-to-end generate-bootstrap-commit and upgrade tests.
- **BR-17.** Adding one properly owned waiver makes WAIVER-ROUTING re-judge every old waiver in the file.
- **BR-18.** LESSON-PROMOTION accepts a `docs/knowledge/` file that the Knowledge Map never lists, and one old decline token can discharge many new lessons.
- **BR-19.** Rust files, Cargo commands, an mdBook skeleton and a vendor-named agent file ship in every child. Separate a neutral spine from opt-in packs, with manifests, collision rules and tests of each generated combination.
- **BR-20.** No licence files exist while Cargo metadata declares `MIT OR Apache-2.0`. Add them per the owner's intent and state what applies to child projects.
- **BR-21.** The commit-msg subject rule is permissive by design and CI does not validate messages; every clone needs hook activation; `SPINE_ALLOW_UNOWNED` should be consistent (BK-08).
- **BR-22.** Consolidate the creation instructions; remove or fix cargo-generate claims; use NUL-delimited paths instead of word splitting; make the decision-index check literal; clarify the README date rule and DOCPATH's scope; declare `lsof` for the handoff census; track executable modes; align Rust CI flags; build-test the optional mdBook; add a spine-defect issue template and a release/migration note format.

---

## 5. Neutrality audit — project, harness and language

**The contract (maintainer, 2026-09-30):** bedrock shall be project-neutral, harness-neutral (Codex, Claude Code, Pi, …) and language-neutral (Rust, Julia, Dart, Perl, …). This section measures the reviewed tree against that contract. A fourth axis follows from the other three: the tools the spine itself needs to run must not impose a language ecosystem on the project.

### 5.1 Measured census

Counted over every tracked file of a freshly bootstrapped child, which is exactly what every new project receives. Terms matched: language (rust, cargo, crate, clippy, rustfmt, `.rs`, mdbook, `target/`, `error[E`, toolchain), harness (claude, codex, cursor, gemini, copilot, aider, windsurf, anthropic, openai) and originating project (pgen, ebnf, parser, grammar, "originating project"). *Logic* means executable lines of scripts, hooks, workflows, manifests and the Makefile; *prose* means documentation and comments.

| Axis | Logic lines | Prose lines | Where the logic lines are |
| --- | --- | --- | --- |
| Language (Rust, mdBook) | 49 | 52 | Makefile 14, bootstrap.sh 8, rust.yml 7, task-acceptance probe driver 6, Cargo.toml 2, rust-toolchain.toml 2, main.rs 2, check_task_acceptance.sh 2, check_gap_claims.sh 2, and one each in book.toml, cargo-generate.toml, check_task_tree_ownership.sh, check_live_doc_currency.sh |
| Harness | 5 | 29 | check_memory_architecture.sh (requires CLAUDE.md), bootstrap.sh (edits CLAUDE.md), check_no_background_jobs.sh (exclusions for three named harnesses), commit-msg (vendor list), and a main.rs doc comment |
| Originating project | 0 | 8 | none in logic; comments, the project-slot template and inherited dev notes |

Reading: **project neutrality is essentially met in logic** (the remaining work is prose and inherited history). **Language and harness neutrality are not**: they are wired into the checks, bootstrap, the build entry points and CI. One piece of good news: no bash-4-only features were found (no associative arrays, `mapfile`, case-changing expansions), so macOS's stock bash 3.2 is not a blocker once the GNU-only `sed -i` (BR-10) is fixed.

### 5.2 Findings

#### NT-01 — Every child receives a Rust project (P1, Inspection)

Every child gets `Cargo.toml`, `crates/app/`, `rust-toolchain.toml`, `cargo-generate.toml`, `.github/workflows/rust.yml`, the Rust lines of `.gitignore`, the Makefile's `check`/`fmt`/`clippy`/`test` targets (all cargo) and an mdBook skeleton. The README's title calls bedrock "a Rust project discipline-spine template" and `MAINTAINING.md` says it is "for new Rust projects". A Julia, Dart or Perl project must delete all of this by hand, and `rust.yml` keeps running cargo on every push until it does.

There is also a direct collision: Perl's standard `ExtUtils::MakeMaker` workflow (`perl Makefile.PL`) writes a root `Makefile`, overwriting the spine's.

**Required change.** The default child contains no language at all. Rust becomes one language pack among several (see §5.3), and so does everything in BK-22.

#### NT-02 — The neutral bootstrap performs a Rust step and records Rust evidence (P1, Executed)

`bootstrap.sh` renames the package in `crates/app/Cargo.toml`. The generated `BOOTSTRAP` leaf's goal is "rename the crate", and its ROOT CAUSE evidence is a `grep` on that file. In a child without Rust this step and its evidence are meaningless, and BK-04 shows the evidence is not truthful even for Rust.

**Required change.** The bootstrap core does only neutral steps: project identity, de-templating, hooks, map, and recording the selection. Each selected pack brings an install hook (the Rust pack renames its crate) that reports its own measured evidence into the bootstrap leaf.

#### NT-03 — Code classification is an allow-list of Rust paths, so non-Rust code is ungoverned (P0, Executed)

**Observed.** Staging `lib/app.dart` (Dart), `lib/Foo.pm`, `t/basic.t`, `bin/tool.pl` (Perl) and `test/runtests.jl` (Julia) with no task file: all 13 checks green. Julia's `src/*.jl` happens to be covered only because the Rust defaults include `src/`. For every non-Rust child this is a gate reporting success without judging the change, which is P0 by this report's definition.

**Required change.** Invert the default: **everything is governed except declared documentation.** Markdown and a short list of project-declared exemptions (images, a docs site's assets) are documentation; everything else — `.jl`, `.dart`, `.pm`, `.t`, `.c`, build files, hooks, workflows, `.doctrine/`, and any language invented next year — is governed with zero configuration. Projects may also declare extra governed paths (for example literate Markdown that is really code). This rule:

- is language-neutral by construction, so packs need no code-path presets;
- absorbs BK-05 (spine files are not documentation, so they are governed automatically; projects cannot exempt them);
- replaces the two diverging classifications (BR-07, D25) with one rule;
- shrinks BK-07's format question to a short exemption list, which should still be one validated format read from the before-snapshot (BK-06).

An interim version of this rule, in the project slot, is in §2.1.

#### NT-04 — The evidence test fits only Rust (P1, Executed)

**Observed.** The default signature list was run against representative summary lines of eight other ecosystems (written from each tool's usual output format, not captured from runs). None matched, while both Rust lines did, and a bare version string matched:

| Ecosystem | Sample output lines | Matched |
| --- | --- | --- |
| Rust (cargo test) | `test result: ok. 12 passed; 0 failed`, `error[E0432]` | 2 of 2 |
| Julia (Pkg.test) | `Test Summary:` table header and row, `Testing MyPkg tests passed` | 0 of 3 |
| Dart (dart test) | `00:02 +12: All tests passed!`, `Some tests failed.` | 0 of 2 |
| Perl (prove) | `All tests successful.`, `Files=3, Tests=42`, `Result: PASS` | 0 of 3 |
| Python (pytest) | `12 passed in 0.34s`, `1 failed, 11 passed` | 0 of 2 |
| Go (go test) | `ok example.com/pkg 0.012s`, `--- FAIL: TestParse`, `PASS` | 0 of 3 |
| JavaScript (jest) | `Tests: 12 passed, 12 total`, `1 failed, 11 passed` | 0 of 2 |
| C/C++ (ctest) | `100% tests passed, 0 tests failed out of 12`, `The following tests FAILED:` | 0 of 2 |
| Java (surefire) | `Tests run: 12, Failures: 0, Errors: 0`, `BUILD SUCCESS` | 0 of 2 |
| Prose | `Julia 1.10.4` | matched (version-number token) |

So in a non-Rust project, genuine test output is refused while prose and version numbers pass (BK-03). The check's own header warns that a signature family that does not fit the real corpus becomes a gate authors learn to waive.

**Required change.** Make the default evidence shape independent of any tool. For example, a neutral wrapper `scripts/evidence -- <command…>` runs any command and prints one stamped line such as `evidence: rc=0 cmd="prove -lr t" out-sha256=3f2a9c…`, followed by the tail of the output. The gate accepts that line shape in any language, and CI can re-run `cmd` and compare `rc`. Language packs may add native signatures (`Test Summary:`, `All tests passed!`, `Result: PASS`) as conveniences, never as requirements. Honest limit: a stamped line can be typed by hand. Its value is a single shape for every language plus CI re-runnability.

#### NT-05 — Commands and entry points assume cargo and make (P1, Inspection)

`COMMIT.md` step 2 is "Run the Rust checks when Rust files changed: `make check`" (cargo fmt, clippy, test). The Makefile's targets are cargo and mdbook commands, and `make gate` is the documented entry point, printed by both bootstrap and the updater.

**Required change.** Projects declare their verbs (`check`, `test`, `lint`, `fmt`, `docs`) in `.doctrine/commands`, run through a neutral `scripts/run <verb>`. `COMMIT.md` step 2 becomes "run the project's declared `check` command". The entry point is a plain script (`scripts/gate`); a Makefile becomes an optional convenience provided by packs that want one, which also removes the Perl collision in NT-01.

#### NT-06 — The documentation surface is mdBook (P2, Inspection)

`docs/book/` (with `book.toml` and `SUMMARY.md`), `make book`, and the lockstep rule in `COMMIT.md` all name mdBook, a Rust-ecosystem tool.

**Required change.** The spine keeps the lockstep rule generic and names a *declared* public-docs location and build command. mdBook becomes a docs pack, alongside equivalents such as Documenter.jl for Julia, dartdoc for Dart and POD for Perl.

#### NT-07 — Checks write scratch files into Rust's build directory (P2, Executed)

GAP-CLAIM-CENSUS writes `target/doctrine_scratch/…` on every hook run that has a staged tree file, and so does LIVE-DOC-CURRENCY's self-test. Only the Rust `.gitignore` line `/target` hides it.

**Observed.** With that line removed, as a non-Rust project would, one run left `?? target/`. The repository is dirty after a commit attempt, which the pivot rule forbids.

**Required change.** Write scratch files under `$(git rev-parse --git-path bedrock)` or a `mktemp -d` directory with cleanup, never inside the worktree.

#### NT-08 — CLAUDE.md is mandatory and canonical (P1, Executed)

**Observed.** A project that does not use Claude Code deletes `CLAUDE.md`, and MEMORY-ARCH fails with "CLAUDE.md (agent bootstrap) is missing". Meanwhile `AGENTS.md`, the cross-harness convention read by Codex, Pi and a growing list of tools, is only a pointer to that vendor-named file. Bootstrap also edits `CLAUDE.md`.

**Required change** (with BR-13).

- `AGENTS.md` is the canonical, complete instruction file and the only required one.
- Harness adapters are optional, minimal files generated on request (`bootstrap.sh --harness claude,gemini`). A `CLAUDE.md` adapter, for instance, contains only a pointer to or import of `AGENTS.md`; verify each adapter's form against the harness's current documentation.
- MEMORY-ARCH requires `AGENTS.md` and checks that every adapter present points to it. No check names a vendor file as mandatory.

#### NT-09 — Harness knowledge is hardcoded in check logic (P2, Inspection)

`check_no_background_jobs.sh` excludes processes matching `.claude/shell-snapshots`, `/.codex/` and `/.cursor/` by name. A Pi, Aider or other harness gets no exclusion, so its own session processes can be reported as blocking. The commit-msg hook hardcodes vendor names (BK-11).

**Required change.** Treat harness knowledge as data, not code: `.doctrine/agent_identities` (bot addresses and product names) and `.doctrine/handoff_ignore` (process patterns), with defaults shipped by each harness adapter. Adding a harness should never require editing a spine script.

#### NT-10 — Originating-project residue in shipped files (P2, Inspection)

Logic is clean, with zero hits. In prose, the shipped project-slot template (`scripts/check_doctrines.project.sh`) describes itself as the equivalent of PGEN's grammar and regex gates. Check headers cite measurements from "the originating project". `DEV_NOTES.md` and `CHANGELOG.md` carry bedrock's own history into every child (BR-12).

**Required change.** Keep provenance in bedrock-only files. Shipped comments state what a check prevents, with no project names.

#### NT-11 — Bedrock's own admission test is Rust-scoped (P1, Inspection)

`MAINTAINING.md` gives the porting litmus test as "would it help a brand-new, unrelated **Rust** project?". The provenance record says the spine exists "so any Rust project gets them". `check_task_acceptance.sh` justifies its defaults with "this template is a Rust scaffold". The maintainer's later Q1 says "any project", but the older litmus line contradicts it and admits Rust-only doctrines through the front door.

**Required change.** Restate the admission test against all three axes: *would it help a new project in any language, driven by any harness or by a human?* Add a gate before Q1: *does its logic name a language, tool or harness? If so it belongs in a pack, not the spine.* This is cheap, and it steers every later decision, so it belongs in phase 0.

#### NT-12 — The spine's own runtime imposes tools the project may not have (P1, Inspection)

The checks need:

- bash, git, awk, sed and grep, with two portability problems: GNU `sed -i` in bootstrap (BR-10), and `\s` inside `grep -E` in `check_task_acceptance.sh` (lines 41 and 88), a GNU extension where POSIX uses `[[:space:]]`;
- **python3**, for TABLE-ARITY only; a Perl, Julia or Dart project should not need Python;
- lsof and ps, for the handoff census;
- make, for the entry points.

**Required change.**

- Declare a minimal runtime (bash 3.2+, git, POSIX awk, sed and grep) and check it in bootstrap's preflight.
- Rewrite TABLE-ARITY in awk, or make python3 optional with an explicit `REFUSED` when it is missing, never green (BR-05).
- Use POSIX character classes instead of `\s`.
- Document Windows support as Git Bash or WSL.

#### NT-13 — CI assumes Rust and Linux (P2, Inspection)

`rust.yml` ships to every child, and the doctrine workflow runs on `ubuntu-latest` only.

**Required change.** Language packs ship their own CI workflow, and the doctrine workflow stays neutral. Bedrock's own CI runs the spine on both Linux and macOS runners, since macOS is where the GNU-only assumptions break.

#### NT-14 — Neutrality is claimed but never tested (P1, Inspection)

**Required change.** Add two mechanical checks to bedrock's own CI, in bedrock's "mechanical, not remembered" spirit.

- **A neutrality lint.** Spine files outside `packs/` may not contain language, tool or harness names in logic lines. This is the §5.1 census as a check, with a small reviewed allow-list; prose hits are reported, not blocked.
- **A generation matrix.** Create children with no language pack and with each shipped pack (at least Rust and one non-Rust pack), with each harness adapter and with none. Each child must bootstrap, run the printed commit, pass the gate, and refuse a change in its own language that has no leaf, then accept it once a leaf owns it.

### 5.3 Target shape

```text
spine (every child)
  AGENTS.md                    canonical agent instructions, complete and harness-neutral
  README.md  README_POLICY.md  ROADMAP.md  MEMORY.md  MEMORY_ARCHITECTURE.md
  COMMIT.md  DOCTRINE_ENFORCEMENT.md  TOOLBOX.md
  docs/TASK_TREE.md  docs/tasks/  docs/decisions/
  scripts/                     gate, run, evidence, bootstrap, update, check_*.sh
                               (bash 3.2+, git, POSIX awk/sed/grep only)
  .githooks/                   pre-commit, commit-msg
  .github/workflows/doctrines.yml
  .doctrine/                   doc exemptions, commands, evidence tokens, caps,
                               agent identities, handoff ignore list
  .bedrock/                    project identity, selected packs, source version

packs (live in bedrock; copied into a child only when selected)
  packs/lang/rust/             Cargo.toml, crates/, rust-toolchain.toml, rust.yml, Makefile,
                               .gitignore fragment, commands, evidence tokens, install hook
  packs/lang/julia/            starter, commands (test via Pkg.test), evidence tokens, CI
  packs/lang/dart/             starter, commands (dart format / analyze / test), evidence tokens, CI
  packs/lang/perl/             starter, commands (prove), evidence tokens, CI
  packs/docs/mdbook/           docs/book/, docs command
  packs/harness/claude/        CLAUDE.md adapter, agent identities, handoff ignore patterns
  packs/harness/<other>/       the same, per harness
```

- **Bootstrap:** `./scripts/bootstrap.sh <name> [--lang rust|julia|dart|perl|none] [--harness <list>|none] [--docs mdbook|none]`, defaulting to `none` everywhere (AGENTS.md only). The selection is recorded in `.bedrock/`.
- **Updates:** the updater refreshes the spine plus installed packs only.
- **Adding a pack later** is its own operation (`--add-pack`) with collision checks (BR-12, BR-19).
- **Pack manifests:** use a plain `key = value` format readable with POSIX tools, so reading a manifest never requires a TOML or JSON parser.
- **Decision to record:** whether unselected packs are removed from a child. Recommended: removed, so a child carries no inactive language payload; the updater fetches pack updates from the pinned source.

### 5.4 Effect on earlier items

- **BK-07 and BR-07:** superseded in approach by NT-03's deny-by-default rule. Their single-declaration, validation and before-snapshot requirements still apply to the exemption list.
- **BK-05:** absorbed by NT-03, with the added rule that projects cannot exempt spine paths.
- **BK-04:** crate-name validation moves into the Rust pack's install hook. The spine validates only the project name, title and work-unit prefix.
- **BK-22:** applies to the Rust pack, not the spine.
- **BK-11:** vendor names move to data (NT-09).
- **BR-13:** required rather than optional under this contract (NT-08).
- **BR-19:** its exact layout remains a design choice, as ChatGPT says, but the contract makes neutral defaults mandatory, and NT-03 and NT-04 make parts of it correctness issues rather than packaging.

---

## 6. One acceptance contract instead of a series of patches

BK-01, BK-03, BK-05, BK-06, BK-08 and BR-02, BR-03, BR-04, BR-08 are facets of one design question. Implement them as a single contract:

1. **Change context.** Every check receives `before` and `after`. Locally, `before` is `HEAD` (or the empty tree) and `after` is the index. In CI, for each commit the push or pull request introduces, `before` is its parent and `after` is the commit. All reads go through `git show <rev>:<path>`; changes are enumerated with `git diff -z --name-status <before> <after>`, including deletions, both paths of renames, copies and type changes.
2. **Classification.** One declaration of governed paths (git pathspecs), read from `before`, plus a built-in spine set projects cannot remove. The same classification in every check.
3. **Binding.** A governed change names exactly one leaf in its commit subject. That leaf exists in a tree file, its section changes in this commit, it was not already `done` in an earlier commit, and it holds exactly one ticked box per gated label whose evidence lines are added or modified in this commit.
4. **Evidence shape.** Label anchored at the start of the box; evidence as a command plus output in a code span or fenced block; optional CI re-run of `evidence-cmd:` lines.
5. **Exceptions.** A `Spine-Exception: <reason>` trailer, honoured by every check and reported by CI.
6. **Errors.** Exit 2 means "cannot evaluate"; the driver reports it as `REFUSED` and fails.
7. **Where each part runs.** Pre-commit: structure and index checks. `commit-msg`: binding, because the message and the index are both available at that point. CI: everything, per introduced commit, plus final-tree invariants.
8. **Special commits.** Define the GitHub template import, the bootstrap commit, the upgrade commit, merges and reverts explicitly.

This keeps ChatGPT's amendments to the Grok implementation spec and adds three things they do not cover: evidence must be new in the commit (BK-01), configuration comes from the before-snapshot (BK-06), and spine files are always governed (BK-05).

---

## 7. Where this review adds to or qualifies the ChatGPT review

- **Agreed:** its verdict, its priorities, and its conclusion that the Grok spec should not be executed unchanged.
- **BR-02** (bind the leaf through the commit message) is necessary but does not close BK-01: a message can name a `done` leaf whose old evidence is still ticked. The evidence must be in the commit's diff.
- **BR-03** ("configuration from the same snapshot") should read *gate-defining* configuration from the before-snapshot (BK-06).
- **BR-01** (an ownership manifest) must live in the upstream source, and the updater must replace itself first; otherwise the fix never reaches existing children (BK-09).
- **BR-05** should also cover git's own failures (BK-17) and lost executable bits (BK-14), not only regex and dependency errors.
- **BR-16** (end-to-end tests) should begin by wiring the tests bedrock already has into CI (BK-19).
- **BR-19** treats language packs as a design choice. Under the maintainer's neutrality contract, parts of it are correctness issues: NT-03 is P0, because non-Rust code passes the gates unjudged.
- **Not re-run by this review:** BR-03, BR-04, the BR-05 dependency fault injection, BR-06, BR-08, BR-10, BR-14, BR-15, BR-17 and BR-18. Reading the code agrees with each where §3 says so.

---

## 8. Recommended implementation order

| Phase | Scope | Exit criterion |
| --- | --- | --- |
| 0 | Advisory for existing children (§2, including the §2.1 backstop); draft the release note; restate the admission test (NT-11) | Children know not to run their current updater; non-Rust children have an ownership backstop |
| 1 | Stop silent greens: BK-17, BR-05, BK-14, BK-13; wire existing self-tests, probes and shellcheck into CI (BK-19) | Git failure, invalid config, a lost exec bit and deleted docs all fail; CI runs the enforcer's own tests |
| 2 | Updater: BK-09, BR-01, BR-09, BK-10 | Customised 0.4.0 and 0.6.1 children upgrade without losing content, every registered check is present, and the upgrade commit passes |
| 3 | Bootstrap: BK-04, BK-18, BR-06, BR-10, BR-11, BR-12, BR-21 | Named, unnamed, invalid-name, macOS and retry cases behave explicitly; the printed command works as printed |
| 4 | Gate redesign per §6: BR-03, BR-04, BR-08, NT-03 (absorbing BK-05, BK-07, BR-07), BK-06, BR-02, BK-01, BK-03, NT-04, BK-08, BK-15; then the BK-02 history replay | Every RED case in §9 is refused with the expected reason and every GREEN control passes |
| 5 | Other checks: BK-11, BK-12, BR-14, BR-15, BR-17, BK-16, BR-18, BK-20, NT-07, NT-12 | The corresponding §9 fixtures pass |
| 6 | Neutral spine and packs: NT-01, NT-02, NT-05, NT-06, NT-08, NT-09, NT-10, NT-13, NT-14, BR-19, BR-13, BR-20, BR-22, BK-21, BK-22, BK-23 | A child with no language pack and no harness adapter initialises and passes; every pack is generated and tested in the CI matrix; the neutrality lint is green |

Each phase becomes leaves under `BEDROCK-MAINTENANCE`; each release bumps `DOCTRINE_VERSION` and ships a migration note. Phases 1 to 3 are small and independent of the larger redesign, so there is no reason to hold them back for phase 4.

---

## 9. Test matrix additions

To add to ChatGPT's acceptance matrix (its §7). Every RED case needs its expected reason, not only a non-zero exit.

| Area | New cases |
| --- | --- |
| Evidence freshness | Code change plus a trivial edit of a done leaf (BK-01); a second commit re-using the first commit's evidence; a leaf adding its own evidence in the same commit (GREEN) |
| Evidence shape | Prose-only boxes (BK-03); a FIX box mentioning the ADDRESSED keyword above an unticked ADDRESSED box; duplicate labels |
| Governed paths | Hook replaced with exit 0; workflow deleted; `.doctrine` edited alongside code; a new script plus weakened config |
| Classification | Glob-style entries refused with exit 2; the C preset classifies `.c` and `.h`; a docs typo is never classified as code |
| Exceptions | The exception trailer is honoured by every check and visible in CI; the environment variable is ignored in CI |
| Tree files | Markdown under `docs/tasks/artifacts/` is not a leaf |
| Fail-closed | Git refusing the repository (safe.directory); project slot without exec bit; spine documents deleted |
| Bootstrap | Names `a/b`, `x&y`, `my.proj`, `Stitch CAD` refused before any write; generated evidence matches reality; a no-name run in an uninitialised copy exits 2; the CI guard fires on an uninitialised child |
| Upgrade | Children from 0.4.0 and 0.6.1 upgraded by the new updater; the old updater is replaced first; legacy `Last updated` fields migrated; the upgrade commit passes with its seeded leaf |
| commit-msg | The four trailer cases in BK-11; a leading blank line |
| Knowledge Map | Single-line, multi-line and end-of-file comments |
| Census and waiver | "make sure" does not discharge a claim; "V1.2" does not discharge a waiver; a real leaf ID does |
| History replay | The new acceptance contract run over bedrock's own commits, results recorded |
| Neutrality | Dart, Perl, Julia and C sources staged with no leaf are refused with zero configuration; a docs-only change passes; non-Rust test output is accepted through the neutral evidence line; a child without `CLAUDE.md` passes when `AGENTS.md` is complete; no file appears in the worktree after any check runs; the neutrality lint finds no language or harness names in spine logic |
| Generation matrix | Child with no packs; each language pack; each harness adapter; combinations. Each bootstraps, runs its printed commit, and refuses an unowned change in its own language |

---

## 10. Reproduction appendix

Run from a scratch directory, with `BEDROCK` pointing at a clone of bedrock at `340fe2f`. Unless stated otherwise, each scenario starts from a fresh copy of the committed base child: `rm -rf tN && cp -a demo.base tN && cd tN`.

### 10.1 Harness

```bash
# mkchild.sh <dir> [rev] — simulate GitHub "Use this template": a one-commit copy of bedrock@rev
set -e
d="$1"; rev="${2:-HEAD}"
rm -rf "$d"; mkdir -p "$d"
git -C "$BEDROCK" archive "$rev" | tar -x -C "$d"
cd "$d"; git init -q -b main .
git config user.email t@example.invalid; git config user.name tester
git add -A; git -c core.hooksPath=/dev/null commit -qm "Initial commit"
```

```bash
# the committed base child used by most scenarios
./mkchild.sh demo && cd demo
./scripts/bootstrap.sh demo
git add -A
printf '%s\n' 'DEMO-BOOTSTRAP-0001 (leaf BOOTSTRAP.1): bootstrapped from bedrock' > git_message_brief.txt
git commit -q -F git_message_brief.txt && : > git_message_brief.txt
cd .. && cp -a demo demo.base
```

### 10.2 Scenarios (current result, then required result)

**BR-11** (from a freshly bootstrapped, uncommitted child)

```bash
git add -A
printf '%s\n' '<NAME>-BOOTSTRAP-0001 (leaf BOOTSTRAP.1): bootstrapped from bedrock' > git_message_brief.txt
git commit -q -F git_message_brief.txt; echo $?   # now 1 (commit-msg)   required: the printed command succeeds
```

**BK-01**

```bash
printf 'fn main() { std::process::exit(3); }\n' > crates/app/src/main.rs
sed -i 's/^- Owner: repo-local workflow$/- Owner: repo-local workflow /' docs/tasks/BOOTSTRAP.md
git add crates/app/src/main.rs docs/tasks/BOOTSTRAP.md
printf 'DEMO-APP-0002 (leaf BOOTSTRAP.1): rewrite main\n' > m.txt
git commit -q -F m.txt; echo $?   # now 0   required: refused (evidence not new; leaf already done)
```

**BK-02** (in the bedrock clone)

```bash
for kw in 'root.?cause' 'addressed' 'no.?regress'; do
  awk -v kw="$kw" '/^[[:space:]]*-[[:space:]]*\[[xX ]\]/ { if (match(tolower($0), kw)) { print kw" -> line "NR; exit } }' \
    docs/tasks/BEDROCK-MAINTENANCE.md
done   # now: 261, 265, 267 (leaf .2.4) for every code commit after 6cc8900
```

**BK-03** — write either checklist from §4 BK-03 into `docs/tasks/FEAT.md` under `# FEAT` and `## Acceptance Checklist`, change `crates/app/src/main.rs`, `git add -A`, then run `bash scripts/check_task_acceptance.sh`. Now: exit 0 for both. Required: refused.

**BK-05**

```bash
printf '#!/usr/bin/env bash\nexit 0\n' > .githooks/pre-commit
git rm -q .github/workflows/doctrines.yml
git add -A; bash scripts/check_doctrines.sh | tail -1   # now: all doctrines green   required: refused (spine change, no leaf)
```

**BK-06**

```bash
printf '^nothing-matches-this$\n' > .doctrine/code_paths.txt
printf 'echo hi\n' > scripts/new_tool.sh
git add -A; bash scripts/check_doctrines.sh | tail -1   # now: all doctrines green   required: refused
```

**BK-07**

```bash
printf '*.c\n*.h\nCMakeLists.txt\n' > .doctrine/code_paths.txt
git add .doctrine/code_paths.txt; git -c core.hooksPath=/dev/null commit -qm "DEMO-CFG-0001: code paths"
printf 'typo fix\n' >> docs/TASK_TREE_README.md; git add docs/TASK_TREE_README.md
bash scripts/check_task_acceptance.sh; echo $?   # now 1, the docs file listed as "staged code"   required: config refused (exit 2)
```

**BK-08**

```bash
printf 'fn main(){}\n' > crates/app/src/main.rs; git add -A
SPINE_ALLOW_UNOWNED=1 bash scripts/check_doctrines.sh   # now: OWNERSHIP passes, ACCEPTANCE fails   required: consistent
```

**BK-09 and BK-10**

```bash
./mkchild.sh old 6cc8900 && cd old
./scripts/bootstrap.sh oldproj
git add -A; git -c core.hooksPath=/dev/null commit -qm "OLDPROJ-BOOT-0001: bootstrap"
cp docs/tasks/TEMPLATE.md docs/tasks/STITCH.md
printf '| [`STITCH`](tasks/STITCH.md) | `active` | `.1` | repo-local |\n' >> docs/TASK_TREE.md
git add -A; git -c core.hooksPath=/dev/null commit -qm "OLDPROJ-TREE-0001: first tree"
./scripts/update_scaffold.sh "$BEDROCK"    # prints: 23 scaffold file(s) synced to bedrock-scaffold 0.6.1
bash scripts/check_doctrines.sh           # now: 5 registered checks missing, KNOWLEDGE-MAP failing
grep BEDROCK-MAINTENANCE docs/TASK_TREE.md # now: injected row; the STITCH row is gone
# BK-10: copy the 5 missing check scripts from $BEDROCK, regenerate the map, commit through the hooks
#   now: TASK-ACCEPTANCE fails (no leaf) and LIVE-DOC-CURRENCY fails (docs/tasks/STITCH.md:9 "- Last updated:")
```

**BK-11**

```bash
f=$(mktemp)
printf 'DEMO-APP-0003 (leaf X.1): pair session\n\nCo-Authored-By: Claude Martin <claude.martin@example.fr>\n' > "$f"
bash .githooks/commit-msg "$f"; echo $?   # now 1   required: 0
printf 'DEMO-APP-0003: x\n\nCo-Developed-By: Claude <noreply@anthropic.com>\n' > "$f"
bash .githooks/commit-msg "$f"; echo $?   # now 0   required: 1
printf '\nDEMO-APP-0003 (leaf X.1): subject on line 2\n' > "$f"
bash .githooks/commit-msg "$f"; echo $?   # now 1   required: 0 (git strips the blank line)
```

**BK-12** — write the `subsystems.md` shown in §4 BK-12, then run `knowledge-map/scripts/gen_knowledge_map.sh | sed -n '/Key subsystems/,/Active task/p'`. Now: the `crates/demo/` line is missing.

**BK-13**

```bash
git rm -q MEMORY_ARCHITECTURE.md AGENTS.md DOCTRINE_ENFORCEMENT.md TOOLBOX.md COMMIT.md
bash scripts/check_doctrines.sh | tail -1   # now: all doctrines green   required: refused
```

**BK-14**

```bash
printf '#!/usr/bin/env bash\necho "PROJECT: always fails" >&2; exit 1\n' > scripts/check_doctrines.project.sh
bash scripts/check_doctrines.sh; echo $?   # 1 (correct)
chmod -x scripts/check_doctrines.project.sh
bash scripts/check_doctrines.sh; echo $?   # now 0 with "12 checks"   required: failure
```

**BK-15** — stage `docs/tasks/artifacts/perf/README.md` (any content), a correctly evidenced `docs/tasks/FEAT.md` and a change to `crates/app/src/main.rs`, then run `bash scripts/check_task_acceptance.sh`. Now: fails on the README. Required: the README is ignored.

**BK-16**

```bash
printf '# FEAT\n\n### `.3` — gap\n- **THE GAP** — nothing checks the retry budget; make sure we revisit.\n' > docs/tasks/FEAT.md
git add -A; bash scripts/check_gap_claims.sh; echo $?     # now 0   required: 1
printf '# FEAT\n\n- the diagnosis-toolbox signatures do not apply to this V1.2 migration.\n' > docs/tasks/FEAT.md
git add -A; bash scripts/check_waiver_routing.sh; echo $?  # now 0   required: 1
```

**BK-17** (run as a user other than the checkout's owner, e.g. as root after `chown -R nobody .`)

```bash
printf 'fn main(){ panic!() }\n' > crates/app/src/main.rs; git add -A
bash scripts/check_doctrines.sh; echo $?   # 1: OWNERSHIP and ACCEPTANCE fail (correct)
chown -R nobody .                          # git now reports "detected dubious ownership"
bash scripts/check_doctrines.sh            # now: OWNERSHIP and ACCEPTANCE pass; only KNOWLEDGE-MAP fails   required: REFUSED
```

**BK-18**

```bash
./mkchild.sh fresh && cd fresh
make bootstrap; echo $?                              # 0
ls MAINTAINING.md docs/tasks/BEDROCK-MAINTENANCE.md  # both still present; CLAUDE.md still says this is the template
```

**BK-04**

```bash
for n in 'x&y' 'a/b' 'my.proj' 'Stitch CAD'; do
  ./mkchild.sh t >/dev/null && (cd t && ./scripts/bootstrap.sh "$n" >/dev/null 2>&1; echo "$n rc=$? $(grep '^name' crates/app/Cargo.toml)")
done
# now: every rc=0; crate lines: name = "xname = "app"y" / name = "app" / name = "my.proj" / name = "Stitch CAD"
```

**BR-21**

```bash
git clone -q demo.base clone2 && git -C clone2 config core.hooksPath; echo $?   # now: empty, 1
```

**Shellcheck census (BK-19)**

```bash
shellcheck -f gcc $(git ls-files '*.sh') .githooks/pre-commit .githooks/commit-msg \
  | grep -oE '\[SC[0-9]+\]' | sort | uniq -c | sort -rn   # now: 45 findings
```

### 10.3 Neutrality scenarios (revision 2)

**NT-03** (from the base child)

```bash
mkdir -p lib t test bin
printf 'void main() {}\n' > lib/app.dart; printf 'package Foo; 1;\n' > lib/Foo.pm
printf 'use Test::More; ok(1); done_testing;\n' > t/basic.t
printf 'using Test\n@test true\n' > test/runtests.jl; printf 'print "hi\\n";\n' > bin/tool.pl
git add -A; bash scripts/check_doctrines.sh | tail -1   # now: all doctrines green   required: refused (no leaf)
```

**NT-08**

```bash
git rm -q CLAUDE.md; bash scripts/check_doctrines.sh   # now: MEMORY-ARCH fails, "CLAUDE.md (agent bootstrap) is missing"
```

**NT-07**

```bash
sed -i '/^\/target$/d' .gitignore; git add .gitignore; git -c core.hooksPath=/dev/null commit -qm "DEMO-CFG-0002: non-Rust gitignore"
printf '\n- a note\n' >> docs/tasks/BOOTSTRAP.md; git add docs/tasks/BOOTSTRAP.md
bash scripts/check_gap_claims.sh >/dev/null 2>&1; git status --short   # now: "?? target/"   required: clean
```

**§2.1 backstop** — install the script from §2.1 as `scripts/check_doctrines.project.sh` (executable) and commit it; then a staged `lib/app.dart` with no task file makes the driver fail on `PROJECT-SPECIFIC`, a README-only change passes, and `git rm --cached crates/app/src/main.rs` with no task file is refused.

**NT-04** (in the bedrock clone)

```bash
python3 - <<'EOF'
import re
src = open('scripts/check_task_acceptance.sh').read()
sig = re.search(r"^DEFAULT_SIG='(.*)'$", src, re.M).group(1)
for line in ['test result: ok. 12 passed; 0 failed', 'Test Summary: | Pass  Total  Time',
             '00:02 +12: All tests passed!', 'All tests successful.', 'Result: PASS',
             '====== 12 passed in 0.34s ======', 'Tests:       12 passed, 12 total',
             '100% tests passed, 0 tests failed out of 12', 'Julia 1.10.4']:
    m = re.search(sig, line); print(f'{line!r:48} -> {m.group(0) if m else "no match"}')
EOF
```

**§5.1 census** — for every tracked file of the base child, count lines matching the three term lists in §5.1, splitting executable lines of scripts, hooks, workflows, manifests and the Makefile ("logic") from documentation and comment lines ("prose").
