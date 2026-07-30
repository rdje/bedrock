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
- **Active tree:** `BEDROCK-MAINTENANCE` — `.1` **done**, `.2.1` (README policy + layer-A byte cap)
  **done**, `.2.2` (`WAIVER-ROUTING` + the neutrality bar) **done**; frontier `.2` = the transfer
  loop, now with an EVIDENCE-RANKED backlog (next: `ROUTING-EVIDENCE`, 3 domain sites).
- **Next action:** pick a `.2.x` backlog item, or port a newly-landed **general** upstream
  doctrine/structure improvement (process in `MAINTAINING.md`).
- **Latest commit:** `.2.2` — ported `WAIVER-ROUTING` (fixing a fail-open in the origin rather
  than inheriting it) and wrote down the **neutrality bar**: every doctrine here must be
  objectively applicable to ANY project, with a measurable admission test.
  `DOCTRINE_VERSION` → `0.3.0`. Doctrines here: **5** (+ knowledge-map + project slot) vs 15
  upstream — the ranked gap is the tree's frontier.
- **Transfer runs BOTH WAYS** (maintainer-confirmed, now in `MAINTAINING.md`): this spine's
  layer-C check was stronger than upstream's; upstream adopted it, strengthened it (row-anchored
  + bidirectional) and sent it back. Owed upstream: the `WAIVER-ROUTING` fail-open fix.
- **In-flight uncommitted work:** none — `make gate` green (6/6).
