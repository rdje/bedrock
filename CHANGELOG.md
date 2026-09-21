# CHANGELOG.md

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
