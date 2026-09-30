# DOCTRINE_ENFORCEMENT.md — how every mechanizable doctrine is enforced

Discipline holds because it is **mechanical**, not remembered. A rule that lives only in a
doc is a suggestion; a rule wired into a git hook + CI is enforced for every agent and
every human, identically.

## Defense in depth (four layers)

- **E1 — discovery.** The doctrine docs: this file, `README.md`, `MEMORY_ARCHITECTURE.md`,
  `TOOLBOX.md`, `COMMIT.md`, and `docs/decisions/`. Where an agent learns the rules.
- **E2 — self-check.** `scripts/check_doctrines.sh` (the driver) + each registered
  `scripts/check_*.sh`. The single source of truth for "which doctrine is enforced by
  what". Runnable by hand anytime.
- **E3 — git hook.** `.githooks/pre-commit` calls the enforcer on the index; `.githooks/commit-msg`
  calls it again with the message. Activate once per clone: `git config core.hooksPath .githooks`.
- **E4 — CI.** The same enforcer runs in CI (`.github/workflows/doctrines.yml`) **on every commit
  the push or pull request introduces**, each judged against its parent, with its real message —
  so a locally `--no-verify`'d hook still fails the build. A second job runs the enforcer's own
  tests (`scripts/tests/spine_tests.sh`, every `--self-test`, the probe drivers, shellcheck).

## The check contract

Every check is a script that reads the change through **`scripts/lib/spine.sh`** and honours one
contract, which the driver reports:

| Exit | Meaning | The driver prints |
| --- | --- | --- |
| `0` | the doctrine holds | `✅` |
| `1` | a breach — the change violates the doctrine | `❌` and the check's stderr |
| `2` | **cannot evaluate** — git failed, a dependency is missing, a pattern is invalid | `⛔ REFUSED`, and the run fails |

- **The change context.** A check receives `before` and `after`: locally `HEAD` and the index; in
  CI the commit's parent and the commit. Every read goes through `spine_read` (the `after`
  snapshot), never the worktree, so an unstaged edit cannot hide a staged defect. Changes are
  enumerated with `spine_changes`, which includes deletions and both sides of a rename.
- **Configuration from `before`.** `.doctrine/` is read as of the last commit, so a commit cannot
  loosen the gate that judges it; a change there takes effect from the next commit.
- **An error is never a pass.** `2` fails the run. A registered check that is missing is a
  refusal; the project slot is run through `bash`, so a lost executable bit cannot drop it.
- **Scratch outside the worktree.** `spine_tmp` is a temporary directory removed on exit.

## The enforcer registry

`scripts/check_doctrines.sh` carries the **universal** registry:

| ID | Proves | Check |
| --- | --- | --- |
| `MEMORY-ARCH` | the durable 4-layer memory invariants hold | `scripts/check_memory_architecture.sh` |
| `DOCPATH` | tracked `.md` carry no checkout-specific absolute paths | `scripts/check_docpaths.sh` |
| `TASK-TREE-OWNERSHIP` | every **governed** change (everything but documentation; the spine set always) is bound to the ONE leaf the subject names: the leaf exists, its tree file is in the commit, its section gains lines, and it was not already `done`. `Spine-Exception: <reason>` is the only bypass, recorded in history and counted by CI. Message-time: judged by the `commit-msg` hook and per commit in CI | `scripts/check_task_tree_ownership.sh` |
| `TASK-ACCEPTANCE` | the bound leaf's checklist has ROOT CAUSE / ADDRESSED / NO REGRESSION **ticked**, labels anchored and one per leaf, each box backed by tool output **inside a code span of its own bullet**, and each box **new in this commit**. ⭐ Box-scoping and freshness are the soundness properties: they close the measured holes — a co-staged leaf supplying the evidence, a token matched anywhere, a keyword box shadowing the real one, and yesterday's ticked boxes answering for today's change. ⚠️ Honest limit: it proves a re-runnable artifact was cited here, never that it is true — the un-fakeable leg is re-running `evidence:` lines in CI. Project seams in `.doctrine/` keep it neutral | `scripts/check_task_acceptance.sh` |
| `WAIVER-ROUTING` | a task leaf saying a gate **does not apply** names the leaf that owns fixing it — ⭐ *an author writing a waiver IS the gate reporting a missing capability*, the highest-signal defect report a gate can receive. Deliberately does **not** punish honesty: the waiver stays legal, it just has to name an owner | `scripts/check_waiver_routing.sh` |
| `README-STABILITY` | `README.md` stays a stable landing page — a **line cap AND a byte cap**, because a line cap alone is measurably bypassable (a real project running this spine passed its 60-line layer-A cap while carrying 138,403 bytes) | `scripts/check_readme_stability.sh` |
| `LIVE-DOC-CURRENCY` | no tracked document reports its own currency (`Last updated:` and kin) — git already carries it, and a hand-kept date is right the day it is typed and false the day after; the upstream instrument that scores distinct dates per live surface against a declared charter is a backlog item | `scripts/check_live_doc_currency.sh` |
| `LESSON-PROMOTION` | a NEW dated lesson heading staged in `DEV_NOTES.md` must be either **promoted** (a `docs/knowledge/` change, or a `docs/decisions/` record gaining `answers:`) or **explicitly declined** (`promotion: declined (<reason>)` in the owning leaf) — never silently dropped. Founding measurement upstream: 1 592 lesson entries, none reachable by question, because no gate asked. Evidence archetype: it verifies a decision was RECORDED, not that it was right | `scripts/check_lesson_promotion.sh` |
| `ROUTING-EVIDENCE` | a task leaf that routes a finding **out to another tree** carries a `ROUTING EVIDENCE` section: does the finding reproduce OUTSIDE the family it is sent to, what was measured, what would make the routing wrong. Keyed on the semantics of leaving the tree (the first cut upstream, keyed on a tree-ID spelling, missed its own founding incident); intra-tree routing is not flagged | `scripts/check_routing_evidence.sh` |
| `GAP-CLAIM-CENSUS` | a task leaf that **ADDS** a *"nothing checks X"* claim records the CENSUS it rests on in the same heading section (a command that enumerates a population, or `census: not run (<why>)`). Such a sentence is a universally quantified claim over the whole tree, false the moment one reader exists; staged-diff-scoped (81 pre-existing claims upstream would otherwise teach bypass); `--all` reports the backlog, advisory | `scripts/check_gap_claims.sh` |
| `COMMIT-MESSAGE` | the subject starts with a work-unit id (`PROJ-AREA-0007`) and no attribution trailer names an agent — recognised by `.doctrine/agent_identities` (addresses and exact product names), never by a human's first name; evaluated wherever a message exists (the `commit-msg` hook, and CI per commit) | `scripts/check_commit_message.sh` |
| `TABLE-ARITY-RATCHET` | a staged `.md` may not RAISE the number of table rows whose cell count disagrees with their header — GFM silently DROPS extra cells and PADS missing ones, so the page looks fine and the reader loses the rightmost column (26 of 197 rows of a shipped contract upstream, every enforcer green). Per-file ratchet against HEAD; code spans and escaped pipes respected; a fresh minimal implementation with an 8-arm `--self-test` | `scripts/check_table_arity.sh` |
| `KNOWLEDGE-MAP` | the derived Knowledge Map is in sync (if the subsystem exists) | `knowledge-map/scripts/check_knowledge_map.sh` |
| `PROJECT-SPECIFIC` | this project's own doctrines | `scripts/check_doctrines.project.sh` |

**Project-specific doctrines go in `scripts/check_doctrines.project.sh`** (the pluggable
slot) — never in the universal driver. That is where a project adds the equivalent of its
own build gates, format checks, invariant proofs, etc.

## Adding a doctrine

1. Write `scripts/check_<name>.sh` — cheap, deterministic, self-describing; source
   `scripts/lib/spine.sh`, read the change through it, and honour the contract above (exit
   `1` with a one-line stderr message on breach, `2` when you cannot evaluate). Keep it fast
   (heavy proofs belong in CI).
2. Register it — universal → the `DOCTRINES` array in the driver; project → append it to
   `scripts/check_doctrines.project.sh`.
3. Mirror it in the table above (this file is the human-readable mirror of the registry).

## The task-acceptance checklist (every governed change's leaf must pass)

A governed change cannot commit until its owning leaf records these, in that leaf's own section
and in the same commit; the first three are hard-gated (`TASK-ACCEPTANCE`), the rest are the
discipline:

- [ ] **REPRODUCE / ISSUE** — the problem, shown (not asserted).
- [ ] **ROOT CAUSE (WHY + WHERE)** — tool-backed and pinpointed (`TOOLBOX.md`).
- [ ] **FIX** — the change, made at the lowest-risk level that actually works.
- [ ] **ADDRESSED (verified)** — measured before→after (the global metric where one exists).
- [ ] **NO REGRESSION** — the guard set stays green; state how you proved it.
- [ ] **LOCKSTEP** — live docs (`MEMORY.md`, `CHANGELOG.md`, `DEV_NOTES.md`,
  `LIVE_STATUS.md`), the book, and any trackers updated in the SAME commit.
