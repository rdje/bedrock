# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~50 lines)

> The bounded layer-A resume pointer (see `MEMORY_ARCHITECTURE.md`). **OVERWRITE** the
> "Current state" block each update — never append history. History is git (layer D) + the
> task-tree logs (layer B); durable facts are `docs/decisions/`.

## Which mode are you in?

- **Maintaining bedrock itself?** → read `MAINTAINING.md`, then the active tree
  `docs/tasks/BEDROCK-MAINTENANCE.md` → its Current Frontier.
- **Starting a NEW project from bedrock?** → run `scripts/bootstrap.sh <name>`; it resets
  this file to a clean seed and removes the maintainer-only files (`MAINTAINING.md`, the
  maintenance tree, the provenance record).

## How to resume (maintainer)

1. Read `README.md`, `MAINTAINING.md`, `MEMORY_ARCHITECTURE.md`, `TOOLBOX.md`,
   `DOCTRINE_ENFORCEMENT.md`.
2. Open `docs/tasks/BEDROCK-MAINTENANCE.md` → Current Frontier → continue from the next action.

## Current state

- **Project:** bedrock — the project-neutral discipline spine extracted from PGEN
  (see `docs/decisions/reference_bedrock_provenance.md`; PGEN = `../pgen`).
- **Active tree:** `BEDROCK-MAINTENANCE` — `.1` (spine extraction) **done**, `.2.1` (README
  Stability Policy + layer-A byte cap) **done**; frontier `.2` = the standing transfer loop.
- **Next action:** pick a `.2.x` backlog item, or port a newly-landed **general** upstream
  doctrine/structure improvement (process in `MAINTAINING.md`).
- **Latest commit:** `.2.1` — adopted `README_POLICY.md` + the `README-STABILITY` doctrine, and
  closed the layer-A size-cap bypass the spine itself was shipping (line-only → line **and**
  byte, in `check_memory_architecture.sh` *and* in `MEMORY_ARCHITECTURE.md` §6/§9/§9.1, so
  adopters stop inheriting it). `DOCTRINE_VERSION` → `0.2.0`.
- **Open, reported upstream:** this spine's layer-C check reconciles every decision record
  against `INDEX.md`; the upstream deployment only asserts the index is non-empty (measured
  there: 135 records / 133 rows, doctrine green). Reverse-flow — the fix upstream needs already
  exists here.
- **In-flight uncommitted work:** none — `make gate` green (6/6).
