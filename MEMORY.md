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
  **done**, `.2.2` (`WAIVER-ROUTING` + the neutrality bar) **done**, `.2.3` (admission test
  re-ordered) **done**, `.2.4` (`TASK-ACCEPTANCE` universal core) **done**, `.2.5` (the 2026-09 day-one
  batch: NO AGENT TRAILERS + hook, the handoff census, `LIVE-DOC-CURRENCY`) **done**; frontier `.2.6` =
  ⏸ part 2 of that transfer, PAUSED by the maintainer 2026-09-04 (`LESSON-PROMOTION`, `ROUTING-EVIDENCE`,
  `GAP-CLAIM-CENSUS`, a fresh `TABLE-ARITY-RATCHET`; `DESTRUCTIVE-TARGET-GUARD` stays **rejected as-is**).
- **Next action:** `.2.6` — resume part 2 of the 2026-09 transfer (classified in the `.2.5` leaf; each
  port is a copy with the fixtures AND the comments re-worded, admitted by Q1 then Q2), then a
  `.2.x` backlog item (process in `MAINTAINING.md`).
- **The bar for anything ported here (maintainer, 2026-07-30):** ask **Q1 first** — *does this
  objectively benefit any present and any future project?* — and only then Q2, *can it be said
  without domain nouns?* ⛔ A 0-noun score does NOT imply portability: neutral vocabulary can
  still encode one project's workflow. See `MAINTAINING.md`.
- **Latest commit:** `.2.5` (`BEDROCK-MAINTENANCE-0007`) — the template said the OPPOSITE of the
  upstream trailer ruling; now `COMMIT.md` + the `commit-msg` hook refuse agent trailers (a human
  co-author passes); `scripts/check_no_background_jobs.sh` is the handoff census; `LIVE-DOC-CURRENCY`
  deletes self-reported `Last updated:` fields and holds the line. `DOCTRINE_VERSION` → `0.5.0`.
  Doctrines here: **7** (+ knowledge-map + project slot) vs 38 upstream, most domain-bound — the
  ranked gap is the tree's frontier.
- **Transfer runs BOTH WAYS** (maintainer-confirmed, now in `MAINTAINING.md`): this spine's
  layer-C check was stronger than upstream's; upstream adopted it, strengthened it (row-anchored
  + bidirectional) and sent it back. Owed upstream: the `WAIVER-ROUTING` fail-open fix.
- **In-flight uncommitted work:** none — `make gate` green (9/9).
