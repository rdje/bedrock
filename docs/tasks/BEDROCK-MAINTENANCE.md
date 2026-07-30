# BEDROCK-MAINTENANCE: keep the discipline spine SOTA, neutral, and self-enforcing

## Metadata

- Tree ID: `BEDROCK-MAINTENANCE`
- Status: `active`
- Roadmap lane: maintain & evolve the spine (this IS bedrock's own roadmap; `ROADMAP.md` is
  the consumer placeholder — see `MAINTAINING.md`)
- Created: `2026-07-24`
- Last updated: `2026-07-24`
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

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `BEDROCK-MAINTENANCE.2` | `active` | the ongoing transfer loop; pick a backlog item below |
| — | `BEDROCK-MAINTENANCE.2.1` | `done` | README Stability Policy + the layer-A byte cap (0.2.0) |

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
  ⭐ Partly discharged by `.2.1`: the layer-A **byte cap** landed (the line-only form was
  measurably not binding). Still open: the rest of the upstream enforcement surface.
- **An example filled-in slice** (a tiny worked task-tree + commit) as living documentation.

## Decisions

- `2026-07-24`: bedrock extracted from PGEN as a separate repo; kept out of PGEN's git; its
  own memory layers describe its maintenance (this tree + `reference_bedrock_provenance`),
  so a cold future session picks up with no lost context.

## Blockers

- None.

## Verification Log

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

- `2026-07-30` — `.2.1` — `BEDROCK-MAINTENANCE-0002`: adopt the README Stability Policy and
  close the layer-A size-cap bypass; `DOCTRINE_VERSION` `0.1.0` → `0.2.0`.

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | genesis commit — bedrock spine extraction | full spine, verified green |

## Changelog

- `2026-07-24`: Created the maintenance tree; `.1` spine-extraction done, `.2` transfer loop active.
