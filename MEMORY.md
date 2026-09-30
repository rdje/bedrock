# MEMORY — resume pointer (layer A; overwrite-only)

> Answers ONE question: **what is next?** See `MEMORY_ARCHITECTURE.md` §6.
> Maintaining bedrock itself → `MAINTAINING.md`. Starting a NEW project from it →
> `scripts/bootstrap.sh <name>`.

## Current state (OVERWRITE this block each update — do not append)

- next_action: `BEDROCK-MAINTENANCE.4` — the enhancement loop after 1.0.0; first candidate: evidence re-run in CI (`evidence: rc=N cmd=…` lines re-executed, `rc` compared). Read `MAINTAINING.md` first, then the candidate list in `docs/tasks/BEDROCK-MAINTENANCE.md`.
- active_work_unit: `BEDROCK-MAINTENANCE` → frontier leaf `BEDROCK-MAINTENANCE.4` (`pending`); the review tree `REVIEW-2026-09` is done.
- latest_commit: `BEDROCK-REVIEW-0011`.
- in_flight_uncommitted: none.
- blockers: none.
