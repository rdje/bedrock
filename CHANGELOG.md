# CHANGELOG.md

## 1.1.0 — 2026-09-30 — the bedrock Guide: an mdBook for the person, and a gate that keeps it complete

`BEDROCK-MAINTENANCE-0018` (leaf `BEDROCK-MAINTENANCE.4.1`). The root documents are rules and reference for
agents and maintainers; a person creating a project had nothing to read in order. **The bedrock Guide**,
<https://rdje.github.io/bedrock/> (source `docs/book/`, 17 chapters), walks through the concepts, creating a
project, the bootstrap step by step, the daily loop, commits and evidence, memory, hand-off, every gate and
how to satisfy it, configuration, packs, the updater step by step on a real 0.6.1 → 1.0.3 upgrade, CI and
repository settings, extending, troubleshooting and a reference — with transcripts captured from the scripts.

- ✅ **`BOOK-COVERAGE`** (`scripts/check_book_coverage.sh`), in bedrock itself only: the guide must name every
  registered doctrine, every entry-point script, every `.doctrine/` seam, every pack and every migration, so a
  new one cannot land undocumented. Two suite arms: a child carries neither the book nor its workflow (and
  gets the docs pack's skeleton when it selects it); the gate refuses the guide with one doctrine's name gone.
- ✅ **`.github/workflows/book.yml`** (maintainer-class) builds the book with a pinned mdBook on every push and
  pull request and publishes it on GitHub Pages from `main`.
- ✅ **`scripts/bootstrap.sh` de-templates from the manifest**: every `maintainer`-class path is removed, so a
  new bedrock-only file (the book, its workflow) cannot reach a child by being forgotten in a hand-kept list.
- 🔧 Three small things the captured transcripts showed: the updater printed a migration's `since` version
  with its trailing comment; migration 0004 announced a move it had not made when `AGENTS.md` was already
  canonical; the bootstrap still mentioned `make` targets the spine no longer ships.

**For existing children:** nothing to run. `scripts/update_scaffold.sh <bedrock> --ref v1.1.0` brings the
corrected scripts and the new gate, which reports `OK — not the template itself` in a project. No migration.

## 1.0.3 — 2026-09-30 — the macOS self-test leg runs in the template only

`BEDROCK-REVIEW-0013` (leaf `REVIEW-2026-09.9.3`). A project created from bedrock inherited the Linux + macOS
matrix; macOS minutes cost ten times the Linux rate in a private repository, and outside the template that
leg runs no suite. The matrix is now Linux and macOS in a repository named `bedrock`, Linux only elsewhere.

## 1.0.2 — 2026-09-30 — a child's CI is green on its first push

`BEDROCK-REVIEW-0012` (leaf `REVIEW-2026-09.9.2`). 1.0.1 was the first fully green run on GitHub (`enforce`,
the Linux and the macOS self-test).

- 🔴 The conformance suite builds children from the pristine template, so inside a project created from
  bedrock it failed (`no such pack: lang/rust`), and the workflow every child inherits ran it. ✅ Outside the
  template the suite now says `NOT APPLICABLE` and exits 0, and the workflow's suite and toolchain steps run
  only where `MAINTAINING.md` exists. A child's CI still runs the enforcer per commit, every `--self-test`,
  the probe drivers, the syntax pass and shellcheck.
- Conformance suite (in bedrock): `arms: 86 pass / 0 xfail / 0 fail / 0 xpass (of 86)`.

## 1.0.1 — 2026-09-30 — what the first push showed: CI judges from the contract epoch on

`BEDROCK-REVIEW-0011` (leaf `REVIEW-2026-09.9.1`). The first GitHub run of 1.0.0 was red in two jobs, both
for reasons the local runs could not show.

- 🔴 **`enforce` re-judged fifteen pre-contract commits** with the 1.0.0 gate and refused them all. ✅ The
  driver's `--range` now honours a **contract epoch**, `ci_range_since` in the tip's `.doctrine/config`:
  commits at or before it were judged by the gate they shipped with. bedrock's epoch is the 1.0.0 commit.
- ✅ **A child never inherits that epoch**: bootstrap empties it, migration 0007 empties it in an upgraded
  child — caught by the suite before the push (a child's CI range refused an epoch it could not resolve).
- 🔴 **The macOS self-test failed two arms** that bootstrap children from bedrock's 0.4.0 and 0.6.1: their old
  bootstrap is GNU-sed-only. ✅ Those arms run only where GNU sed exists; everything else on macOS was green.
- `docs/REPOSITORY_SETTINGS.md` gives the exact branch-protection command and how to push afterwards.
- Conformance suite: `arms: 86 pass / 0 xfail / 0 fail / 0 xpass (of 86)`.
- For children: nothing to do; `ci_range_since` stays empty unless you adopt a stricter contract later and
  want CI to start judging from that commit.

## 1.0.0 — 2026-09-30 — the review is closed: the maintainer's guide, the NEUTRALITY gate, CI on Linux and macOS

`BEDROCK-REVIEW-0010` (leaf `REVIEW-2026-09.9`, the last of the tree). Every item of the consolidated review
of 2026-09-30 (59 items) is closed; the conformance suite runs 85 arms, all required, all passing under bash
5.3 and stock bash 3.2.

- ✅ **`MAINTAINING.md` is the maintainer's guide**: the architecture in one screen, and recipes to add a
  doctrine, a pack, a migration, cut a release, port an improvement, run everything — so the next agent, any
  model, any harness, can keep enhancing bedrock. `BEDROCK-MAINTENANCE.4` lists twelve ranked candidates.
- ✅ **`NEUTRALITY` gate** (NT-14): no spine logic file names a language, a tool or a harness; terms and
  reviewed exceptions are data (`.doctrine/neutrality_terms`, `.doctrine/neutrality_allow`).
- ✅ **CI**: actions pinned by commit, the self-test job on Linux **and macOS** (NT-13, BK-23); the platform
  settings a child must enable — required checks, branch protection, the template flag — are in
  `docs/REPOSITORY_SETTINGS.md`.
- ✅ **Documents reconciled** (BK-21, BR-13, BR-22): `MEMORY_ARCHITECTURE.md` §7 (`AGENTS.md` canonical, adapters
  from packs) and §9 (CI per commit, merge blocking through settings) describe what exists; `ROADMAP.md` and
  `LIVE_STATUS.md` no longer promise a seeded tree; `DOCTRINE_ENFORCEMENT.md` says which three checklist items
  are gated; the decision template uses links that render; bedrock's `DEV_NOTES.md` starts with its intro.
- Conformance suite: `arms: 85 pass / 0 xfail / 0 fail / 0 xpass (of 85)`.
- ⚠️ **For existing children upgrading across 0.11 → 1.0.0:** copy `scripts/update_scaffold.sh` once, then
  `scripts/update_scaffold.sh <bedrock> --ref v1.0.0 --plan`, read the plan, run it without `--plan`, review
  `.bedrock-incoming/`, commit with the printed command, set the repository settings, and run `scripts/handoff`.
  Each release from 0.11.0 to 0.19.0 lists what changed for you; the migrations 0001–0006 do the mechanical part.

## 0.19.0 — 2026-09-30 — the neutral spine and the packs; the guided setup; new_project.sh

`BEDROCK-REVIEW-0009` (leaf `REVIEW-2026-09.8`), per `docs/decisions/decision_neutral_spine_and_packs.md`.

- ✅ **The default child contains no language, no docs tool and no harness file** (NT-01). Rust
  (`packs/lang/rust`: workspace, starter crate named after the project, rustfmt, clippy, tests, a pinned
  toolchain, `rust.yml`, a `Makefile`), mdBook (`packs/docs/mdbook`) and six harnesses
  (`packs/harness/claude` — the default — `codex`, `pi`, `kimi`, `qwen`, `gemini`) are opt-in packs.
  Codex, Pi and Kimi read `AGENTS.md` natively and ship only their hand-off exclusions; Claude, Qwen and
  Gemini get a one-line `@AGENTS.md` adapter. Unselected packs are never copied (BR-19).
- ✅ **Entry points are scripts** (NT-05): `scripts/gate` (the enforcer), `scripts/run <verb>` (the project's
  verbs from `.doctrine/commands`; a pack appends its own; an undeclared verb is refused), `scripts/handoff`.
  `cargo-generate.toml` is gone (BR-22).
- ✅ **No language or harness in spine logic** (NT-09): result signatures, agent identities, harness adapter
  files and hand-off exclusions are data under `.doctrine/`, appended by packs.
- ✅ **The guided setup**: `scripts/bootstrap.sh` on a terminal asks name, title, prefix, visibility, language
  pack, docs pack and harness packs — every choice listed, a default accepted with Enter (harness default:
  claude), invalid input re-asked, a summary and a confirmation before anything is written; flags and
  `--yes` are the non-interactive path.
- ✅ **`scripts/new_project.sh`**, run from a clone of bedrock: the same questions, then the repository is
  created — on GitHub through `gh` from this template, or locally — cloned, bootstrapped with the answers,
  committed through the hooks, and pushed if wanted. Nobody types `gh repo create`.
- ✅ The updater syncs installed packs (`sync` files fast-forward, `seed` files are the project's) and
  `--add-pack <kind/name>` installs one later; migration 0006 records the packs an older child already has.
- Conformance suite: `arms: 84 pass / 0 xfail / 0 fail / 0 xpass (of 84)` under bash 5.3 and 3.2.
- ⚠️ **For existing children:** your Rust files, `Makefile` and `docs/book/` stay yours (the manifest no
  longer lists them; migration 0006 records `packs = rust,…` in `.bedrock/project`); `.doctrine/commands`,
  `handoff_ignore` and `harness_adapters` are seeded; `make gate` becomes `scripts/gate` and `make check`
  becomes `scripts/run check` (add your verbs to `.doctrine/commands`). If your `CLAUDE.md` is still the
  full instruction body, migration 0004 moves it to `AGENTS.md`.

## 0.18.0 — 2026-09-30 — the remaining check defects; no review scenario is open

`BEDROCK-REVIEW-0008` (leaf `REVIEW-2026-09.7`).

- ✅ **`TABLE-ARITY-RATCHET` in POSIX awk, by GFM's rules** (BR-15, NT-12): an unescaped pipe splits a cell even
  inside a code span (the first cut protected it, and its self-test pinned that wrong rule), an escaped pipe
  never does, outer pipes are optional, a header/delimiter mismatch is not a table, a prose line right after a
  table is a one-cell row. python3 is no longer needed by any check; 13 self-test arms.
- ✅ **A census counts only inside a code span or fenced block** (BK-16): "make sure we revisit" no longer
  discharges a claim.
- ✅ **A waiver's owner must exist** (BK-16) — a leaf of an existing tree, `.n` of this tree, or a work-unit id a
  tree cites — and **only waivers added in the change are judged** (BR-17).
- ✅ **One decline per lesson, and a knowledge file promotes only with `answers:`** (BR-18); the Knowledge Map
  lists `docs/knowledge/` by question, shows each tree's status, and warns when the curated section shrinks.
- Conformance suite: `arms: 73 pass / 0 xfail / 0 fail / 0 xpass (of 73)` — every scenario of the review's §9
  and §10 is now a required, passing arm.

## 0.17.0 — 2026-09-30 — the updater's manifest lives with the source; unmodified spine files fast-forward, modified ones are never touched

`BEDROCK-REVIEW-0007` (leaf `REVIEW-2026-09.6`), per `docs/decisions/decision_updater_ownership_classes.md`.

- ✅ **`.bedrock/manifest`** classifies every shipped path (`spine` / `seed` / `project` / `maintainer`) and the
  new `MANIFEST` gate keeps it complete in bedrock and verifies every spine path exists in a child (BR-01, BK-09).
- ✅ **The updater reads the manifest from the source it fetches and replaces itself first** (BK-09), resolves
  its repository from its own location, exports a pinned `--ref` with `git archive` (BR-09), refuses a dirty
  tree and a downgrade, and `--plan` writes nothing.
- ✅ **Fast-forward for a spine file the project never modified** — identical to that path at any commit that
  carried the project's recorded version — and **never for one it changed** (`.bedrock-incoming/`, `--merge`).
- ✅ **Migrations** (`migrations/NNNN-<slug>.sh`, `# since: <version>`) run for every version newer than the
  project's: 0001 removes `Last updated` fields, 0002 retires `.doctrine/code_paths.txt`, 0003 backfills
  `.bedrock/project`, 0004 makes `AGENTS.md` canonical, 0005 renames the pointer's fields (BK-10).
- ✅ **The upgrade commit passes the project's own gates**: every registered check verified present, an
  `UPDATE-<version>` leaf with measured evidence, the index row and the pointer edited and printed,
  `DOCTRINE_VERSION` written only after the enforcer passes over the staged upgrade, the commit printed.
- 📊 Proven on real children built from bedrock's own `0.4.0` and `0.6.1` commits: `26 seeded, 20 updated, 0
  differ, 5 migration(s)`, the legacy field gone, their own trees intact, the upgrade committed through the new
  hooks and green in CI mode. Conformance suite: `arms: 66 pass / 2 xfail / 0 fail / 0 xpass (of 68)`.
- ⚠️ **Existing children — one manual step, once:** your copy of the updater predates this release and knows
  nothing of the manifest. Copy `scripts/update_scaffold.sh` from bedrock at this version into your project by
  hand, commit it, then run it (`./scripts/update_scaffold.sh <bedrock> --plan` first). From then on it replaces
  itself. Review `.bedrock-incoming/` after the run: anything you modified is there, untouched.

## 0.16.0 — 2026-09-30 — a bootstrap that cannot lie or break the project

`BEDROCK-REVIEW-0006` (leaf `REVIEW-2026-09.5`).

- ✅ **Validation before any write** (BK-04): the project name (`[A-Za-z][A-Za-z0-9_-]{0,63}`), the display
  title (`--title`) and the work-unit prefix (`--prefix`, derived otherwise) are checked first; `x&y`, `a/b`,
  `my.proj` and `Stitch CAD` are refused with exit 2 and nothing written.
- ✅ **Literal, mode-preserving edits, no `sed -i`** (BR-10): every edit must change exactly one occurrence
  or the run stops. The whole bootstrap runs under BSD `sed`/`awk` and bash 3.2 (the suite proves it).
- ✅ **Evidence that is measured** (BK-04): the seeded `BOOTSTRAP` leaf cites real counts and the verdict of
  the enforcer run **over the staged index with the first commit's subject** — the same judgement the hook
  repeats. Bootstrap now stages everything itself.
- ✅ **Explicit modes** (BK-18): `bootstrap.sh <name>` initialises; `--contributor` installs the hooks only
  (what a later clone runs); `--maintainer` is for bedrock itself; no name in a pristine copy prints usage
  and exits 2; `make bootstrap NAME=<name>` refuses an empty name. CI fails an uninitialised child.
- ✅ **Preflight and a defined rerun** (BR-06, BR-12): a dirty tree is refused (a fresh `git init` with no
  commit is allowed); the identity lives in `.bedrock/project`; a rerun with the same name is idempotent,
  another name is refused. The child's `CHANGELOG.md`, `DEV_NOTES.md` and `LIVE_STATUS.md` start clean.
- ✅ **The printed commit works as printed** (BR-11), and the README says what a later clone runs (BR-21).
- Conformance suite: `arms: 58 pass / 2 xfail / 0 fail / 0 xpass (of 60)`.

## 0.15.0 — 2026-09-30 — context continuity as a guaranteed property: the pointer is true, and handoff proves it

`BEDROCK-REVIEW-0005` (leaf `REVIEW-2026-09.10`), for the maintainer's requirement of 2026-09-30
(`docs/decisions/decision_context_continuity.md`): a project spawned from bedrock can switch harness and
model at any handoff-ready state, and resumes with full context after any `/exit`, `/clear` or crash.

- ✅ **`RESUME-POINTER` gate**: in every governed commit `MEMORY.md` names that commit in `latest_commit`,
  `active_work_unit` names an existing tree, the frontier leaf exists and is open, `next_action` is set.
  A stale pointer, or a leaf that no longer exists, is refused at `commit-msg` time and per commit in CI.
- ✅ **`scripts/handoff`**, the last command of every session: the background-job census, a clean working
  tree (uncommitted content survives nothing, so it is refused, not warned about), the pointer true against
  the latest governed commit, and unpushed commits listed. Green means any agent, in any harness, on any
  machine, resumes from the repository alone.
- ✅ **Proven by the suite**: seven continuity arms, including a hook-bypassed commit caught by handoff, a
  process holding a repository file open, and a fresh clone that resumes by the read path with a green gate.
- `AGENTS.md` non-negotiables updated: end every session with `scripts/handoff`; the pointer is true in
  every commit; the harness and the model are transparent to the project. The bootstrap seeds a true
  `latest_commit`.
- Conformance suite: `arms: 47 pass / 6 xfail / 0 fail / 0 xpass (of 53)`.
- ⚠️ **For every child:** governed commits must now update `MEMORY.md`'s `latest_commit`; run
  `scripts/handoff` before ending a session.

## 0.14.0 — 2026-09-30 — the ownership contract as code: a leaf owns a commit only if that commit's evidence is in it

`BEDROCK-REVIEW-0004` (leaf `REVIEW-2026-09.4`). The contract in `docs/decisions/decision_ownership_contract.md`,
implemented and enforced at `commit-msg` time and per commit in CI.

- ✅ **Deny-by-default governance** (NT-03, BK-05, BK-07, BR-07): every path is governed except documentation
  (Markdown/text, licence files, images, `.gitignore`, and what `.doctrine/docs_paths.txt` declares); the spine
  set — hooks, workflows, `.doctrine/`, `scripts/check_*`, `scripts/lib`, `DOCTRINE_VERSION` — is governed
  whatever a project declares. Dart, Perl, Julia, C, a hook, a workflow: all refused without a leaf, with zero
  configuration. `.doctrine/code_paths.txt` is retired and refused if present.
- ✅ **The leaf is bound by the subject** (BR-02, BK-01): a governed commit names exactly one `(leaf <TREE>.<n>)`;
  the tree file is in the commit; the leaf's section gains lines; a leaf already `done` may own nothing — open
  a child leaf. An open leaf may own several commits.
- ✅ **Evidence is new and in a code span** (BK-03, NT-04): labels anchored (`- [x] **ROOT CAUSE…`), one per
  leaf; each box gains a line in this commit; a result signature (`rc=0`, `exit 1`, `12 passed / 0 failed`, a
  declared token) sits inside backticks. Prose, a bare version number or a tool's name is not evidence.
  `scripts/evidence -- <command>` prints a tool-neutral `evidence: rc=N cmd="…"` line for any ecosystem.
- ✅ **Exceptions are trailers** (BK-08): `Spine-Exception: <reason>` is the only bypass, honoured by every check,
  stored in history, listed and counted by CI. `SPINE_ALLOW_UNOWNED` is gone.
- ✅ **Agents are data** (BK-11, NT-09): trailers are read with `git interpret-trailers`; an agent is recognised by
  `.doctrine/agent_identities` (addresses, exact product names), never by a human's first name. The subject must
  start with a work-unit id (`PROJ-AREA-0007`); `hello` no longer passes (BR-21). Merge subjects are exempt.
- 📊 **The replay** (BK-02): the contract over this repository's 19 commits → 18 fail it (11 on evidence shape,
  4 on the done-leaf rule, 18 on inventory documents that did not exist yet); `7b6d898` onward is green.
  Recorded in the leaf; nothing rewritten.
- ⚠️ **Shape change for every child** (a migration ships with `REVIEW-2026-09.6`):
  1. the acceptance checklist moves **inside each leaf** (`docs/tasks/TEMPLATE.md`), labels first in the bold;
  2. a governed commit's subject **must** carry `(leaf <TREE>.<n>)` and start with a work-unit id;
  3. evidence goes inside backticks; declare your tools' result shapes in `.doctrine/evidence_tokens.txt`;
  4. delete `.doctrine/code_paths.txt`; declare extra documentation in `.doctrine/docs_paths.txt`;
  5. a follow-up to a done leaf is a child leaf.
- Conformance suite: `arms: 40 pass / 6 xfail / 0 fail / 0 xpass (of 46)`; probe fixtures rewritten to the new shape.

## 0.13.0 — 2026-09-30 — every check reads the change through one library, and an error is never a pass

`BEDROCK-REVIEW-0003` (leaf `REVIEW-2026-09.3`).

- ✅ **`scripts/lib/spine.sh`**: a fail-closed prelude (a git failure is `REFUSED`, exit 2, never "nothing
  staged"), the exit contract `0 holds · 1 breach · 2 REFUSED` that the driver reports and fails on, and a
  change context — `before`/`after` revisions, reads through `git show`, changes enumerated with
  `--name-status -z` including deletions and both sides of a rename. Every check converted (BK-17, BR-05,
  BR-03, BR-08). Scratch files leave the worktree (NT-07).
- ✅ **CI judges every commit** the push or pull request introduces, each against its parent with its real
  message (`check_doctrines.sh --commit <rev>` / `--range <a>..<b>`, BR-04). A `--no-verify`'d subject or
  agent trailer is now refused in CI (`COMMIT-MESSAGE`, BR-21).
- ✅ **Configuration comes from the last commit**: `.doctrine/` is read from `before`, so a commit cannot
  loosen the gate judging it (BK-06); an invalid pattern is refused, with a repair path (BR-05). Caps move to
  `.doctrine/config` (BK-20). A tree file is top-level `docs/tasks/<TREE>.md` only (BK-15).
- ✅ **`MEMORY-ARCH` checks the spine's own documents** (BK-13) and **`AGENTS.md` is canonical**: the complete
  instructions live there; `CLAUDE.md` is an optional adapter; no vendor file is mandatory (NT-08, BR-13).
- ✅ The project slot and every check run through `bash`, so a lost executable bit cannot drop a check (BK-14);
  the Knowledge Map is generated from the index with a comment stripper that handles same-line comments
  (BK-12, BR-14); `\s` replaced by POSIX classes; `check_table_arity.sh` now parses under bash 3.2.
- ⚠️ **Two defects in the new library were caught by the suite before shipping**: a NUL-delimited stream
  captured in a variable (every check saw "no change"), and a refusal inside `$( )` that ended only the
  subshell (an invalid pattern became an empty one and passed). Recorded in the leaf.
- 📌 **New requirement recorded** (`docs/decisions/decision_context_continuity.md`): harness/agent transparency
  and guaranteed context continuity across session ends, with a `RESUME-POINTER` check and a `scripts/handoff`
  command to come in `REVIEW-2026-09.10`.
- Conformance suite: `arms: 20 pass / 17 xfail / 0 fail / 0 xpass (of 37)`.
- ⚠️ **For existing children:** the library is a new file your copy of the updater does not know about; wait
  for `REVIEW-2026-09.6` (the self-replacing updater) or copy `scripts/lib/spine.sh`, `scripts/check_*.sh`,
  `scripts/check_doctrines.sh`, the hooks, `.doctrine/config` and `.github/workflows/doctrines.yml` by hand.

## 0.12.0 — 2026-09-30 — the conformance suite: the review's scenarios as arms, and CI tests the enforcer

`BEDROCK-REVIEW-0002` (leaf `REVIEW-2026-09.2`).

- ✅ **`scripts/tests/spine_tests.sh`** builds a child from the working tree the way a user would (one-commit
  copy, `bootstrap.sh demo`, the printed first commit) and runs 31 arms: the review's §10 reproductions and
  §9 additions. A RED arm must be refused **by the named check**; a GREEN control must pass.
- ⭐ **Open items are `xfail`, never deleted.** The run is green while they fail as expected and turns red the
  moment one starts passing (`XPASS`), so the leaf that fixes an item has to promote its arm to `req` in the
  same commit. Today: `arms: 2 pass / 29 xfail / 0 fail / 0 xpass`.
- ✅ **CI gains `enforcer-selftest`** (BK-19): a syntax pass over every script, the five `--self-test`s, both
  probe drivers, the suite, and shellcheck (errors block; the full report is advisory until a baseline is
  checked in). `permissions: contents: read`, `concurrency` and `workflow_dispatch` added while there.
- ⚠️ The harness reported one `XPASS` on its first run and it was the harness's own defect: the driver names
  every check on its ✅ line, so "refused by X" matched any failure. Fixed; recorded in the leaf.
- Portability: the suite runs identically under bash 5.3 and stock macOS `/bin/bash` 3.2.

## 0.11.0 — 2026-09-30 — the consolidated review: decisions, licence, and the tree that closes it

`BEDROCK-REVIEW-0001` (leaf `REVIEW-2026-09.1`, phase 0 of `BEDROCK-MAINTENANCE.3`). An external
review of `0.6.1` (59 items, re-verified against `0.10.0`: every executed finding reproduces) is
checked in at `docs/reviews/2026-09-30-consolidated-review.md`, and the work that closes it is the
tree `docs/tasks/REVIEW-2026-09.md`.

- **Three decisions recorded** (`docs/decisions/`): the spine is project-, harness- and
  language-neutral with Rust, mdBook and harness files as opt-in packs and `AGENTS.md` the only
  required agent file; a leaf owns a commit only if that commit's evidence is in it (deny-by-default
  governance, leaf bound by the subject, evidence new in the diff, configuration from the
  before-snapshot, exceptions as trailers, exit 2 = `REFUSED`); the spine is LGPL-2.1-or-later.
- **Licence files** (`LICENSE`, `NOTICE`): LGPL-2.1-or-later for the spine, 0BSD for seed files, a
  child's own work not covered. The Cargo `MIT OR Apache-2.0` field, which no licence file backed, is
  removed from the starter (BR-20).
- **The admission test has three axes** (`MAINTAINING.md`): a pack gate (Q0) before Q1, and Q1 asked
  about a project in any language, under any harness (NT-11).
- **Bootstrap removes every bedrock-only file**, not three: the review directory, both maintainer
  trees, and every decision record. Measured before the change: a child inheriting a record failed
  `MEMORY-ARCH` on its first gate run, because the reset index lists none.
- ⚠️ **For existing children:** nothing to do yet. Read the review's §2 before running your copy of
  `update_scaffold.sh`; the updater that replaces itself first arrives with `REVIEW-2026-09.6`.

## 0.10.0 — 2026-09-21 — never overwrite is now auditable, and the merge is asked for and never applied

`BEDROCK-MAINTENANCE-0016` (leaf `.2.11`). **Maintainer instruction:** *"shall not update files that are
different. Worst case it shall ask to merge, never overwrite, never."*

- 🔴 **A blanket `chmod +x` was still a mutation.** `0.9.0` removed the overwrite path, but the run still
  ended with `chmod +x scripts/*.sh knowledge-map/scripts/*.sh .githooks/…` over every matching file —
  including files it never looked at. A mode change is a change: it shows in `git status` and lands in a
  commit. It is now scoped to the paths this run actually seeded.
- ✅ **`--merge`: ask, then merge into a COPY.** Interactive and per file. On an explicit yes it computes a
  **three-way** merge and writes the result to `.bedrock-incoming/<path>.merged`. Your file is not
  read-modified-written, renamed or deleted; taking the result is a `cp` you run after reading it. A
  conflicted merge is reported with its count and keeps its `<<<<<<<` markers in the side file.
- ⭐ **The merge is a real three-way, which is what makes offering it honest.** The base is the template
  version the project last synced from, resolved from its own `DOCTRINE_VERSION` through the upstream
  commit that introduced it. ⛔ Without a base, two files cannot be merged — only diffed with opinions —
  so an unresolvable version is reported and the diff offered instead.
- ✅ **Proven, not asserted:** every write in the script enumerated (all land in `$tmp` or
  `.bedrock-incoming/`, except a seed `cp` inside an absence guard and the now-scoped `chmod`), then a
  clean clone of a real project run against this template — **310 tracked files, CONTENT changed 0,
  MODE changed 0**. Only `.bedrock-incoming/` and a genuinely new file appear.
- ⚠️ The first proof run was refused by the dirty-tree guard, because its own baselines were written
  inside the repository. The control working on its author.
- `--force` is documented as skipping the dirty-tree check **only**: nothing can make this tool overwrite.

## 0.9.0 — 2026-09-21 — update_scaffold.sh never overwrites anything

`BEDROCK-MAINTENANCE-0015` (leaf `.2.10`). **Maintainer instruction:** *"`update_scaffold.sh` shall
absolutely not touch files that were modified, that's way too dangerous."*

- 🔴 **It happened.** A run in a project created from this template wiped `docs/TASK_TREE.md`'s index of
  **11 registered task trees**, `DOCTRINE_ENFORCEMENT.md`'s **four project doctrine rows**, `TOOLBOX.md`'s
  **entire tool registry** (replaced by `<your-probe>` placeholders) and `COMMIT.md`'s **tiered workflow**.
  Recoverable only because nothing had been committed.
- 🔴 **And `make gate` passed on the wreck** — which the tool itself advises running. It cannot see this
  class: the files written are the TEMPLATE's, and template files satisfy template checks.
- **The premise was measurably false.** `NEUTRAL` was documented as *"safe to overwrite because it never
  carries project content"*. Divergence from the template across the three projects created from it:
  `docs/TASK_TREE.md` 25/30/20 lines, `TOOLBOX.md` 27/48/**616**, `COMMIT.md` 16/27/61,
  `check_task_acceptance.sh` 0/79/**447**, `check_readme_stability.sh` 0/0/**217**,
  `check_gap_claims.sh` 0/0/**212**. ⛔ The most mature project would have lost the most — its hardened
  checks are exactly what this template exists to receive.
- ✅ **The tool now has no overwrite path at all.** Identical → counted, untouched. Absent → seeded.
  Different → the template's version is copied into `.bedrock-incoming/<path>` and reported by name,
  while **yours is not modified, renamed or deleted**. One directory to review, one `rm -rf` to clean,
  and it cannot be committed beside the original by a careless `git add -A`.
- ✅ **A dirty tree is REFUSED** (`--force` overrides, having read why): recovery is
  `git checkout -- <file>`, and that is only simple when the tree was clean to begin with.
- Verified against a clean clone of the affected project: **23 already current, 1 seeded, 6 differ**;
  all four previously-destroyed files **SHA-256 unchanged** and its 11 trees intact.

## 0.8.1 — 2026-09-21 — a spine file that carries a project decision can now reach an existing project

`BEDROCK-MAINTENANCE-0014` (leaf `.2.9`, follow-up). 0.8.0 added `VISIBILITY.md` and it could reach only
projects created afterwards.

- 🔴 **The gap:** `update_scaffold.sh` had ONE category — `NEUTRAL`, which blind-overwrites. That is right
  for a file which never carries project content and **wrong** for `VISIBILITY.md`, which a project is
  meant to edit: re-syncing would silently revert a deliberate decision. With no other category, the file
  had no route into a project that predates it.
- ✅ **`SEED_ONCE`:** copied when ABSENT, left alone when PRESENT, counted separately in the run summary.
  Proven both ways on a trial clone — absent → seeded; present and edited to `Declared posture: PRIVATE`
  → kept, **byte-identical**, posture intact.
- ⭐ The general rule, which is the part worth keeping: **a spine file that carries a project decision
  needs a reach mechanism that is not an overwrite.** The category is now there for the next one.
- ⛔ `MEMORY_ARCHITECTURE.md` needed none — it is already in `NEUTRAL`, so 0.7.0's §6 rule reaches every
  project that runs the updater.

## 0.8.0 — 2026-09-21 — the template states its visibility posture, and what it means for confidential material

`BEDROCK-MAINTENANCE-0013` (leaf `.2.9`). **Maintainer instruction:** *"make sure BEDROCK explicitly states
that GH projects created or spawned out of it are public and not confidential."* Nothing in this template
said anything about visibility — no statement, no file, no check.

- **`VISIBILITY.md`** at the root: a **declared posture** line (**PUBLIC**), the rule that nothing
  confidential enters the repository through any mechanism — source, docs, commits, trees, fixtures,
  issues, CI logs, history, or a branch that is never merged — where confidential material goes instead,
  and the procedure for a project that must be private.
- **Why a file and not the remote setting:** visibility is a property of the hosting platform and is
  invisible from inside a clone, so every contributor infers it. The two wrong inferences are not
  symmetric — treating a private repository as public costs inconvenience; confidential material in a
  public one **cannot be un-published**, because no later git operation retracts what was already
  fetched, forked, mirrored, cached or indexed.
- ⛔ **It states what the posture does NOT establish**: name/crate/domain clearance, licence selection,
  release qualification and deployment security each keep their own gate — in both directions.
- **It reaches a new project before its first push:** `bootstrap.sh` prints reading `VISIBILITY.md` and
  deciding as step **0**, ahead of the roadmap, with *"do it before the first push, not after"*.
- ⛔ **The upstream mechanical checker is deliberately NOT ported.** It refuses tracked sentences
  instructing private visibility — right for a public project, backwards for a private one, therefore
  conditional and failing Q1 as-is. The neutral form (*no document contradicts the DECLARED posture,
  whichever it is*) is on the backlog with the census it owes, rather than half-built here.
- Admission test: **Q1 passes unconditionally** for *state your posture explicitly*; the value *public* is
  this template's declared default, editable in place with a recorded reason. **Q2:** no domain nouns.

## 0.7.0 — 2026-09-21 — the resume pointer answers one question, and its growth is the signal

`BEDROCK-MAINTENANCE-0012` (leaf `.2.8`). `MEMORY_ARCHITECTURE.md` §6 defined the layer-A contract by its
MECHANICS — overwrite, no history, two caps, demote on breach — and never by its PURPOSE. A rule about how
to write a file does not tell a reader what does not belong in it, so every addition gets judged on its own
merit and the file accumulates while each step looks correct.

- **§6 gains a first hard rule:** the pointer **answers one question, *what is next?*, and nothing else**,
  and **it shall not grow** — *"if it grows, that is the signal that something is being written into it that
  does not belong, not a signal that the cap is tight"*. Raising the cap stays available for a genuinely
  larger next action and is explicitly not the answer to accumulation.
- **The worked instance ships with it**, measured on a project running this spine: the pointer reached
  **26 standing warnings weighing 5,184 of 6,412 bytes — 81%** — with the pointer proper at 19%, its guard
  green throughout. Eviction took it to 425 bytes and no cap changed.
- **The template now practises what it ships.** This repository's own `MEMORY.md`: **3,263 → 672 bytes,
  46 → 13 lines**, with every evicted item checked in its durable home first — the completed-leaf history is
  this tree's Current Frontier and Commit Log, the neutrality bar is `MAINTAINING.md`, the provenance is its
  decision record.
- **And the seed, which is the part that propagates.** `scripts/bootstrap.sh` wrote a first `MEMORY.md`
  carrying a "How to resume" block duplicating `CLAUDE.md` and a framing note that invites prose. The seed is
  now the five pointer fields under the one-question heading.
- **Trial-proven, not read:** clone → `bootstrap.sh trialproj` → seeded pointer **713 bytes / 13 lines**,
  `make gate` green in the new project. 🔴 The trial earned its keep: renaming the seed's fields silently
  broke the two `sed -i` lines that fill them after bootstrap, because they matched the old names and a
  `sed` that matches nothing exits 0.
- Admission test: **Q1 passes unconditionally** — the rule is a property of the layer-A contract this
  template already ships, needs no *"any project that …"* qualifier, and a brand-new project is better off
  with it on day one. **Q2:** no domain nouns.

## bedrock-scaffold 0.6.1 — creating a project is foolproof through its first commit

`BEDROCK-MAINTENANCE.2.7`.

- ⛔ **Measured on a fresh clone of 0.6.0:** `bootstrap.sh` left the crate rename — a CODE change — with no owning
  leaf, so the new project's FIRST commit was refused by `TASK-TREE-OWNERSHIP` and `TASK-ACCEPTANCE`. A new user's
  first contact with the discipline was a refusal about a rename the tool made.
- **`bootstrap.sh` now seeds `docs/tasks/BOOTSTRAP.md`** on a fresh de-template: a done leaf that owns the bootstrap,
  its ticked checklist carrying the evidence of that very run (crate-name count before/after, hooks path, the
  enforcer's summary and verdict with `rc=0`), registered in `docs/TASK_TREE.md`, pointed to by `MEMORY.md`; and it
  prints the exact first-commit command as step 0. Idempotent.
- Proven: clone → `bootstrap.sh <name>` → the printed commit → hooks green → `make gate` green → `make check` green,
  with no hand edits. Two defects in the fix were caught by the trial itself (an enforcer run before the map
  existed; a `grep -c` fallback that split a checklist bullet).

## bedrock-scaffold 0.6.0 — four evidence and ratchet doctrines: lessons reach the retrievable layer, routings carry evidence, gap claims carry their census, tables keep their columns

`BEDROCK-MAINTENANCE.2.6`.

- **Added `LESSON-PROMOTION`**: a new dated lesson heading staged in `DEV_NOTES.md` must be promoted (a
  `docs/knowledge/` change or a `docs/decisions/` record gaining `answers:`) or explicitly declined
  (`promotion: declined (<reason>)` in the owning leaf). Pure verdict with 9 controls at import.
- **Added `ROUTING-EVIDENCE`**: a leaf that routes a finding out to another tree carries a `ROUTING EVIDENCE`
  section. Keyed on the semantics of leaving the tree; 5-arm `--self-test`.
- **Added `GAP-CLAIM-CENSUS`**: a leaf that ADDS a "nothing checks X" claim records the census it rests on in
  the same section (or `census: not run (<why>)`). Staged-diff-scoped; `--all` reports the backlog; 10-arm
  `--self-test` pinning the founding active and passive sentences.
- **Added `TABLE-ARITY-RATCHET`** (a fresh minimal implementation): a staged `.md` may not raise the number of
  table rows whose cell count disagrees with their header; code spans and escaped pipes respected; 8-arm
  `--self-test`.
- ⛔ Two defects in the ports were caught by their own RED arms before the gate ran: a heredoc that consumed
  the table detector's stdin (every arm read 0), and a `pipefail` control in lesson promotion.
- All four scripts join the `NEUTRAL` allow-list of `scripts/update_scaffold.sh`. Backlog notes record the
  input-bound principles (`BASELINE-IDENTITY`, `IDENTITY-CARRIER-CURRENCY`, `SCRATCH-SLOT-HEADER`, the full
  `LIVE-DOC-CURRENCY` instrument) for a future seam.

## bedrock-scaffold 0.5.0 — the day-one batch: no agent trailers, a handoff census, no self-reported dates

`BEDROCK-MAINTENANCE.2.5`.

- ⛔ **`COMMIT.md` had the trailer rule backwards.** It told every generated project to *end commit
  messages with the project's co-authorship trailer*; the upstream maintainer ruled the opposite on
  2026-08-22 (a commit message ends with its own last line — no agent/tool attribution trailers,
  harness-agnostic). The rule is rewritten and `.githooks/commit-msg` now refuses the known
  agent-attribution shapes mechanically; a human co-author's `Co-Authored-By:` still passes.
- **Added `scripts/check_no_background_jobs.sh`**, the handoff census: pattern-free (`lsof` over the
  caller's uid — an open handle under the repo, or a command line naming the checkout), run before
  a session ends; deliberately not a commit gate. Named in `CLAUDE.md`'s non-negotiables.
- **Added the `LIVE-DOC-CURRENCY` doctrine** (principle): no tracked `.md` reports its own currency
  (`Last updated:` and kin) — git carries it, a hand-kept date is false the day after. The field is
  deleted from `docs/tasks/TEMPLATE.md` and the maintenance tree; `scripts/check_live_doc_currency.sh`
  is structural over `git ls-files '*.md'` with a 3-arm `--self-test`.
- Both scripts join the `NEUTRAL` allow-list of `scripts/update_scaffold.sh`.
- Part 2 of the same transfer (`LESSON-PROMOTION`, `ROUTING-EVIDENCE`, `GAP-CLAIM-CENSUS`, a fresh
  `TABLE-ARITY-RATCHET`) is classified in the `.2.5` leaf and queued as `.2.6`, paused by the maintainer.

## bedrock-scaffold 0.4.0 — TASK-ACCEPTANCE: a change lands with evidence, not with a claim

`BEDROCK-MAINTENANCE.2.4`.

- **Added the `TASK-ACCEPTANCE` doctrine**: a staged CODE change must be owned by a task-tree leaf
  whose checklist has ROOT CAUSE / ADDRESSED / NO REGRESSION **ticked**, each backed by output from
  a tool that was actually run — **inside that box's own bullet**.
- ⭐⭐ **Box-scoping is the soundness property**, not a nicety. It closes two measured leakage
  holes: a co-staged, unrelated leaf supplying the evidence, and a token matched anywhere in the
  file rather than in the box it backs. `CTRL-1` demonstrates it directly — a whole-file grep
  PASSES the fixture that the shipped check REJECTS.
- **Neutral by seam, not by rename.** Default signatures are universal to any Rust project
  (`error[E1234]`, `could not compile`, `clippy::…`, `test result: ok`, panics, profilers) plus any
  project's build-flow forensics (`git log -S`, `shellcheck`, `bash -n`, `make -n`, `ENOSPC`…).
  Project-specific tooling is declared in `.doctrine/evidence_tokens.txt`, and what counts as a
  code change in `.doctrine/code_paths.txt` — both optional, both defaulted, both documented in
  `.doctrine/README.md`. ⭐ `CTRL-4`/`CTRL-4b` prove the seam is load-bearing: the same leaf passes
  WITH the declaration and fails WITHOUT it.
- ⛔ **Fixed a portability defect the probes caught**: the box extractor used `IGNORECASE`, a gawk
  extension that BSD awk silently ignores — every leaf would have been reported as having no
  checklist. Rewritten with POSIX `tolower()`.
- ⚠️ Honest limit, stated in the check itself: it proves the author cited something re-runnable,
  never that the output is true. The un-fakeable leg is re-running the cited command in CI.
- Probes 9/0; `make gate` 8/8.

## unreleased — the admission test asks about VALUE first, not vocabulary

`BEDROCK-MAINTENANCE.2.3`. Process only; no check changed, so `DOCTRINE_VERSION` is unmoved
(`MAINTAINING.md` and the maintenance tree are maintainer-only, not re-syncable spine files).

- **The admission test is now two ordered questions.** Q1 (primary, about VALUE): *does this
  objectively benefit any present and any future project?* — answered by stating what the check
  prevents using no project's nouns, then asking whether a brand-new project is better off with it
  on day one. Q2 (secondary, a filter): *can it be expressed without domain nouns?*
- ⛔ **Q2 cannot substitute for Q1.** A check can score 0 domain nouns and still encode a workflow
  only one project needs — neutral vocabulary, project-shaped substance. Q2 measures whether a
  thing CAN be neutralized; Q1 asks whether it SHOULD be. Running Q2 first waves impostors through.
- ⭐ **Measured worked example, which changed a verdict.** A "destructive automation must require
  confirmation" check scored well on Q2 and was ranked an easy win; its logic hardcodes a Makefile
  path and a `clean:` recipe, so it really offers *"benefits any project that builds with make"* —
  a conditional. **Rejected as-is.** Meanwhile `ROUTING-EVIDENCE` measures 0 build-system
  references and presumes only the task-tree system this template ships ⇒ promoted to top.
- **The portability seam to look for:** does the check presume anything beyond what bedrock ships?
  If yes, give it a project-declared seam or leave it upstream — never hardcode one project's
  answer and call it neutral.
- ✅ Retroactive audit: all four already-ported items PASS Q1. Nothing retracted.

## bedrock-scaffold 0.3.0 — WAIVER-ROUTING, and the neutrality bar for every future port

`BEDROCK-MAINTENANCE.2.2`.

- **Added the `WAIVER-ROUTING` doctrine** (`scripts/check_waiver_routing.sh`): a task leaf saying a
  gate DOES NOT APPLY must name the leaf that owns fixing the gate. ⭐ An author writing a waiver
  IS the gate reporting a missing capability — the highest-signal defect report a gate can get.
  Deliberately does **not** punish honesty: the waiver stays legal, it just has to name an owner.
- **Chosen by measurement.** All 15 upstream doctrines were classified by domain-dependence of
  their LOGIC (comments stripped). `WAIVER-ROUTING` scored **0** — portable essentially unchanged.
  The ranked remainder is now a frontier in `docs/tasks/BEDROCK-MAINTENANCE.md`, not a wish list.
- ⭐⭐ **The port FIXED a defect rather than inheriting one**: the origin's `printf … | grep -q …
  || continue` returns failure ON SUCCESS past the pipe buffer under `pipefail`, silently SKIPPING
  the file — a **fail-open**. Both sites here read a file instead. Threshold measured, not assumed:
  65,606 B → no SIGPIPE; 131,139 B → SIGPIPE.
- **Wrote down the neutrality bar** (`MAINTAINING.md`): every doctrine here must be objectively
  applicable to ANY project, with a measurable admission test and its honest bound — plus the rule
  that **transfer runs both ways**, after this repo's layer-C check turned out to be stronger than
  the reference deployment's.
- Probes 5/0; `make gate` 7/7; added to the `update_scaffold.sh` NEUTRAL allow-list.

## bedrock-scaffold 0.2.0 — README Stability Policy + a layer-A byte cap

`BEDROCK-MAINTENANCE.2.1`. Transferred from the reference deployment by maintainer order.

- **Added `README_POLICY.md`** (project-neutral, verbatim) — keeps `README.md` a stable landing
  page instead of a changelog/roadmap/catalogue, and states the caps rule.
- **Added the `README-STABILITY` doctrine** (`scripts/check_readme_stability.sh`): a line cap
  AND a byte cap, a dated-line (release-history) tripwire, and a required link back to the
  policy. Non-mutating; REFUSES (exit 2) rather than passing when the README or policy is
  absent. Template defaults 300 lines / 16384 bytes — generous on purpose, because they ship to
  a project whose README is not this one; tighten after your own trim.
- ⛔ **Closed a bypass the spine was itself shipping.** `scripts/check_memory_architecture.sh`
  capped layer-A `MEMORY.md` by LINES only (cap 120, no byte bound), exactly as
  `MEMORY_ARCHITECTURE.md` §9's reference check prescribed — so **every adopting project
  inherited a bound that does not bind.** Measured on a real project running this spine:
  60 lines (passing, exactly at its cap) carrying **138,403 bytes** — 2,306 B/line, one line of
  18,816 B. Now both caps, in the check **and** in the standard (§6 / §9 / §9.1).
  Layer-A caps: **50 lines** (tightened from 120, to match the "≤ ~50 lines" §6 already stated)
  and **7168 bytes**. Both env-overridable.
- Both new files added to the `update_scaffold.sh` NEUTRAL allow-list, so existing projects
  pull them with `scripts/update_scaffold.sh <bedrock-url>`.
- Verified: `make gate` 6/6 green; a 13-line / 19,304-byte fixture is REJECTED by the byte cap
  while being well under the line cap; the **retired** layer-A guard PASSES that same file
  (exit 0) — the change is proven necessary by execution, not by argument.

Changelog-style summary of completed work + its validation (internal continuity surface;
the immutable audit trail proper is `git log` — memory layer D). Newest first.

## _(YYYY-MM-DD)_ — bootstrap

Instantiated from the `bedrock` discipline-spine template. Next: replace `ROADMAP.md` and
seed the first task-tree.
