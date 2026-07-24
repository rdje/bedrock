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
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `BEDROCK-MAINTENANCE.2` | `active` | the ongoing transfer loop; pick a backlog item below |

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
- **Port PGEN memory-architecture refinements** (§ any new enforcement or layer discipline).
- **An example filled-in slice** (a tiny worked task-tree + commit) as living documentation.

## Decisions

- `2026-07-24`: bedrock extracted from PGEN as a separate repo; kept out of PGEN's git; its
  own memory layers describe its maintenance (this tree + `reference_bedrock_provenance`),
  so a cold future session picks up with no lost context.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-07-24` | `.1` | enforcer (5 checks) · cargo metadata · commit-msg hook · KM gen | all green |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | genesis commit — bedrock spine extraction | full spine, verified green |

## Changelog

- `2026-07-24`: Created the maintenance tree; `.1` spine-extraction done, `.2` transfer loop active.
