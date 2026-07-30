# BEDROCK-MAINTENANCE: keep the discipline spine SOTA, neutral, and self-enforcing

## Metadata

- Tree ID: `BEDROCK-MAINTENANCE`
- Status: `active`
- Roadmap lane: maintain & evolve the spine (this IS bedrock's own roadmap; `ROADMAP.md` is
  the consumer placeholder — see `MAINTAINING.md`)
- Created: `2026-07-24`
- Last updated: `2026-07-30`
- Owner: repo-local workflow

## Goal

Keep bedrock the best-available project-neutral discipline spine: transfer the **general**
improvements that land in PGEN (`../pgen`), keep every spine
file project-agnostic, and keep the whole thing self-enforcing (`make gate` green on a fresh
clone). See `MAINTAINING.md` for provenance, the neutral/specific boundary, and the transfer
process.

## Non-Goals

- Porting PGEN-specific content (grammars, parsers, domain gates) — those stay in PGEN.
- Turning bedrock into a framework/library — it is a *starting structure*, not a dependency.

## Task Tree

- ID: `BEDROCK-MAINTENANCE`
  Status: `active`
  Goal: SOTA neutral self-enforcing spine
  Children: `.1`, `.2`

- ID: `BEDROCK-MAINTENANCE.1`
  Status: `done`
  Goal: initial extraction of the spine from PGEN (memory arch, task-trees, commit workflow,
  doctrine enforcer + universal checks + project slot, tools-first, derived knowledge map,
  mdBook skeleton, Rust workspace, CI, bootstrap + update_scaffold).
  Acceptance: the enforcer runs green on the fresh clone; manifest valid; hooks work.
  Verification: `scripts/check_doctrines.sh` → all checks ✅; `cargo metadata` valid;
  `commit-msg` hook rejects blank / accepts id-shaped subjects; KM generates deterministically.
  Commit: the genesis commit — bedrock spine extraction (see `git log`)

- ID: `BEDROCK-MAINTENANCE.2`
  Status: `active`
  Goal: the standing PGEN→bedrock transfer loop + the improvement backlog below.
  Acceptance: each transferred improvement is neutralized, landed under its own leaf, added
  to `update_scaffold.sh` NEUTRAL if re-syncable, and `DOCTRINE_VERSION` bumped.
  Verification: `.2.1` done (see below)
  Commit: see `.2.1`

- ID: `BEDROCK-MAINTENANCE.2.1`
  Status: `done`
  Goal: adopt the README Stability Policy **and** close the layer-A size-cap bypass the spine
  was itself shipping. Transferred from the reference deployment by direct maintainer order.

  **Why this is one leaf and not two.** The upstream work adopted a README growth guard and,
  in doing so, measured *why* a growth guard needs two caps. The evidence came from the
  spine's own layer-A check: the reference deployment's `MEMORY.md` sat at **60 lines —
  PASSING, exactly at its line cap — and 138,403 bytes** (2,306 bytes per line; one line of
  18,816 bytes). A file the standard calls a *"bounded resume pointer"* was a 138 KB document
  with a green guard.

  ⛔ **And the defect was HERE, in the spine, not only downstream.** `MEMORY_ARCHITECTURE.md`
  §9's reference check prescribed a LINE-only cap, so **every project adopting bedrock
  inherits a bound that does not bind.** Shipping the README policy while leaving that in
  place would have published the *rule* and kept the *counter-example*.

  Measured in this repository before the change:
  - `scripts/check_memory_architecture.sh:14` — `lines=$(wc -l < MEMORY.md)`, cap **120**, no
    byte bound at all (looser even than the deployment that failed).
  - `MEMORY_ARCHITECTURE.md:129/249/315` — §6 rule, §9 reference script and §9.1 knob list all
    line-only.
  - no README size guard of any kind; `README_POLICY.md` absent.

  **Neutralization** (per MAINTAINING.md step 3): the policy text was already project-neutral
  and is copied verbatim. The guard names no domain noun and no upstream project; its routing
  hint points at this spine's own generic homes (`docs/`, `CHANGELOG.md`, `ROADMAP.md`,
  `docs/decisions/`, `docs/tasks/`). The measured evidence is cited as *"a real project
  running this spine"* — the number is what carries the argument, not whose file it was.

  **Cap choice differs from the upstream deployment ON PURPOSE.** Upstream chose caps fitted
  to its own trimmed files. bedrock is a **template**: its caps ship to a consumer whose README
  is not this one. So the README caps default to the policy's own published example
  (**300 lines / 16384 bytes**), generous enough not to false-fail a new project on day one,
  with the policy telling the consumer to tighten them after their own review-and-trim. Both
  are env-overridable. ⛔ The layer-A cap is *tightened* rather than loosened — 120 → **50
  lines** — because the standard itself says *"≤ ~50 lines"* in §6 and in the pointer template,
  so 120 was more than twice as loose as the rule it policed. Byte cap **7168** ≈ 143 B/line at
  50 lines: the shape of a real pointer file, so the two caps bind on the same document rather
  than one shadowing the other. This repo's own layer A measures 30 lines / 1,654 bytes, so it
  has ample headroom under both.

  Acceptance: the new guard REJECTS an over-cap fixture and PASSES this repo's files; the
  retired layer-A guard PASSES a file the new one rejects (proving the change was necessary,
  not cosmetic); `make gate` green; both new files in the `update_scaffold.sh` NEUTRAL
  allow-list; `DOCTRINE_VERSION` bumped; `CHANGELOG.md` noted.
  Verification: see the Verification Log entry for `.2.1`.
  Commit: see the Commit Log entry for `.2.1`.

  ⭐ **REVERSE-FLOW FINDING — the spine is AHEAD of the reference deployment on one check, and
  the documented flow does not anticipate this direction.** MAINTAINING.md states the flow as
  *"PGEN → (generalize) → bedrock"*. But this repo's layer-C check
  (`scripts/check_memory_architecture.sh:23-29`) already **reconciles every decision record
  against `INDEX.md`**, one record at a time — while the upstream deployment asserts only that
  the index has *more than zero* rows. Upstream measured **135 records / 133 index rows** with
  its doctrine green: two records invisible to their own index. ⇒ the fix upstream needs is
  already implemented here. **Reported back rather than silently duplicated.** ⚠️ Honest bound:
  this check is one-directional — it catches a record with no row, not a row with no record.

- ID: `BEDROCK-MAINTENANCE.2.2`
  Status: `done`
  Goal: port `WAIVER-ROUTING` — the highest-value doctrine that passes the neutrality bar
  unchanged — and write that bar down as an explicit admission test for every future port.

  **Why this one, chosen by measurement rather than taste.** The reference deployment enforces
  **15** doctrines; this spine had **4**. Classifying all 15 by domain-dependence *of the logic*
  (comments stripped, since comments legitimately cite the originating evidence):

  | verdict | doctrines |
  |---|---|
  | ⭐⭐ neutral as-is (0 domain nouns in logic) | `MEMORY-ARCH` ✅here · `KNOWLEDGE-MAP` ✅here · **`WAIVER-ROUTING` ← this leaf** |
  | ⭐ portable with 2–4 edits | `ROUTING-EVIDENCE` (3) · `DESTRUCTIVE-TARGET-GUARD` (4) · `GATE-REACHABILITY` (4) · `README-STABILITY` ✅`.2.1` |
  | ⛔ domain-bound by construction | source-of-truth / self-hosting / oracle-anchor / version-currency / flow-integrity checks, plus `TASK-ACCEPTANCE` (10) and `DESIGN-PRIOR-ART` (7) |

  ⚠️ **The first cut of that instrument was WRONG and was thrown away, not tuned.** Counting
  domain nouns across the whole file scored `README-STABILITY` as domain-bound — a doctrine
  already ported cleanly here — because its *routing-hint prose* names domain homes. Comments
  were being read as logic. Re-measured on non-comment lines only, the ranking matched
  independent judgement. ⚠️ Remaining honest bound: strings and heredocs still count as logic,
  so the number ranks candidates; it does not rule.

  ⛔ **`TASK-ACCEPTANCE` is the single highest-value discipline upstream and is deliberately NOT
  ported**: its evidence-signature families name that project's own tools, so a neutral version
  needs a project-declared token list — a design, not a copy. Recorded in the backlog rather
  than half-ported.

  ⭐⭐ **The port FIXED a defect instead of inheriting one.** The origin's version contains
  `printf '%s\n' "$added" | grep -qE "$RE" || continue`. Under `pipefail`, `grep -q` exits at the
  first match, the producer takes SIGPIPE (141), and 141 becomes the pipeline status — so the
  `|| continue` **skips the file** and an unrouted waiver passes silently. It **fails OPEN**,
  the worst direction. Both sites here are written to a file instead. ⚠️ The threshold is NOT a
  flat 64 KiB: measured **65,606 B → PIPESTATUS=(0 0)** but **131,139 B → (141 0)**, i.e. pipe
  capacity plus the consumer's read-ahead. The first CTRL fixture was built on the flat-64 KiB
  assumption and **failed to reproduce** — the probe caught the over-claim, not review.

  Acceptance: 0 domain nouns in the ported logic AND 0 project references anywhere in the file;
  registered in the driver + mirrored; probes RED/GREEN/CONTROL green; `make gate` green; in the
  `update_scaffold.sh` NEUTRAL allow-list; `DOCTRINE_VERSION` bumped.
  Verification: see the Verification Log entry for `.2.2`.
  Commit: see the Commit Log entry for `.2.2`.

  🔜 **Owed back upstream**: the fail-open fix (that project tracks it, latent, as its own leaf).

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `BEDROCK-MAINTENANCE.2` | `active` | the ongoing transfer loop; pick a backlog item below |
| — | `BEDROCK-MAINTENANCE.2.1` | `done` | README Stability Policy + the layer-A byte cap (0.2.0) |
| — | `BEDROCK-MAINTENANCE.2.2` | `done` | `WAIVER-ROUTING` ported + the neutrality bar written down (0.3.0) |
| 2 | `.2.x` — port `ROUTING-EVIDENCE` | `todo` | next by the measured ranking: 3 domain sites in logic |
| 3 | `.2.x` — port `DESTRUCTIVE-TARGET-GUARD` / `GATE-REACHABILITY` | `todo` | 4 sites each; the latter needs ground-truth controls (its instrument produced six wrong answers upstream before it was right) |
| 4 | `.2.x` — design a neutral `TASK-ACCEPTANCE` | `todo` | highest value, NOT a copy: needs a project-declared evidence-token list |

## Improvement backlog (seed — for a future session to pick up)

Concrete candidates, each to become a `.2.x` leaf when worked:

- **Generalize PGEN's `run_with_memory_guard.sh`** into a neutral `scripts/run_with_resource_guard.sh`
  (RAM/disk/timeout guard for heavy jobs) — a broadly useful utility.
- **Add more universal doctrine checks** as they prove general in PGEN: e.g. a commit-message
  co-authorship-trailer check, a "no unguarded destructive make targets" check, a
  "generated artifacts not staged" check.
- **Wire cargo-generate placeholders properly** (`{{project-name}}` substitution + a rename
  hook) if the cargo-generate path is used often — currently naming is done by `bootstrap.sh`.
- **A `docs/decisions/` linter** (every record has the required frontmatter fields).
- **Port memory-architecture refinements** (§ any new enforcement or layer discipline).
  ⭐ Partly discharged by `.2.1` (layer-A byte cap) and `.2.2` (layer-C reconcile was already
  stronger here, and went the other way). Still open: the rest of the upstream enforcement
  surface — see the ranked frontier rows above, which are now evidence-backed rather than a
  wish list.
- **Build the behavioural cross-repo differential** — where both repos implement the same
  invariant, run both against one fixture and compare verdicts. This is the trigger that would
  have surfaced the layer-C gap deliberately instead of by accident. ⛔ A raw text `diff` is NOT
  the answer: 11 of the 12 shared files differ by 15–559 lines, by design.
- **An example filled-in slice** (a tiny worked task-tree + commit) as living documentation.

## Decisions

- `2026-07-24`: bedrock extracted from PGEN as a separate repo; kept out of PGEN's git; its
  own memory layers describe its maintenance (this tree + `reference_bedrock_provenance`),
  so a cold future session picks up with no lost context.

## Blockers

- None.

## Verification Log

- `2026-07-30` — `.2.2`: `make gate` → **7/7 green** (adds `WAIVER-ROUTING`).
  Neutrality: `sed 's/#.*//' scripts/check_waiver_routing.sh | grep -ciE '<domain nouns>'` → **0**;
  project references anywhere in the file (including comments) → **0**.
  Probes **5 pass / 0 fail** (`docs/tasks/artifacts/waiver_routing/run_waiver_routing_probes.sh`):
  GREEN-1 ordinary leaf passes · RED-1 unrouted waiver blocked · **GREEN-2 the same waiver WITH an
  owner passes** (the doctrine must not punish honesty) · **CTRL-1 the shipped form CATCHES a
  343,376-byte staged addition while the unfixed pipe form MISSES it (exit 0)** ⇒ the port closed a
  real fail-open · CTRL-2 an honest SCOPE statement is not bound.
  `bash -n` clean. ⚠️ CTRL-1's first fixture (113,776 B) did **not** reproduce the fail-open; the
  threshold was measured (65,606 B → no SIGPIPE, 131,139 B → SIGPIPE) and the fixture rebuilt past
  the band. The probe caught the over-claim.

- `2026-07-30` — `.2.1`: `make gate` → **6/6 green** (`MEMORY-ARCH`, `DOCPATH`,
  `TASK-TREE-OWNERSHIP`, **`README-STABILITY`** (new), `KNOWLEDGE-MAP`, `PROJECT-SPECIFIC`).
  Live readings: `README-STABILITY: OK — README.md is 73/300 lines, 3571/16384 bytes`;
  layer A 30 lines / 1,654 bytes against caps 50 / 7168.
  **RED arms:** a **13-line / 19,304-byte** fixture — comfortably under the 300-line cap — is
  REJECTED by the byte cap (exit 1), for both the README guard and the layer-A guard.
  ⭐ **CONTROL (the arm that matters):** the **retired** layer-A guard, extracted with
  `git show HEAD:scripts/check_memory_architecture.sh`, returns **exit 0** over that same
  19,304-byte file ⇒ the previous check was genuinely blind, so the change is proven necessary
  by execution rather than argued. `bash -n` clean on all 4 edited/added scripts.
  Neutrality: `grep -ciE 'pgen|grammar|parser|ebnf|systemverilog|regex' README_POLICY.md` → **0**.
  ⚠️ Not verified: no book chapter covers the memory layers or doctrines (`docs/book/` is still
  an introduction-only skeleton), so there was no book surface to sync — stated rather than
  implied.

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-07-24` | `.1` | enforcer (5 checks) · cargo metadata · commit-msg hook · KM gen | all green |

## Commit Log

- `2026-07-30` — `.2.2` — `BEDROCK-MAINTENANCE-0004`: port `WAIVER-ROUTING` (fixing its
  fail-open), write down the neutrality bar and the both-ways transfer rule;
  `DOCTRINE_VERSION` `0.2.0` → `0.3.0`.

- `2026-07-30` — `.2.1` — `BEDROCK-MAINTENANCE-0002`: adopt the README Stability Policy and
  close the layer-A size-cap bypass; `DOCTRINE_VERSION` `0.1.0` → `0.2.0`.

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | genesis commit — bedrock spine extraction | full spine, verified green |

## Changelog

- `2026-07-24`: Created the maintenance tree; `.1` spine-extraction done, `.2` transfer loop active.
