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
- **Active tree:** `BEDROCK-MAINTENANCE` — leaf `.1` (spine extraction) **done**; frontier
  `.2` = the standing PGEN→bedrock transfer loop + the improvement backlog in the tree.
- **Next action:** pick a `.2.x` backlog item, or port a newly-landed **general** PGEN
  doctrine/structure improvement (process in `MAINTAINING.md`).
- **Latest commit:** the genesis commit — bedrock spine extracted from PGEN (see `git log`).
- **In-flight uncommitted work:** none — the spine is committed; `make gate` green.
