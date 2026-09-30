# MEMORY — resume pointer (layer A; overwrite-only)

> Answers ONE question: **what is next?** See `MEMORY_ARCHITECTURE.md` §6.
> Maintaining bedrock itself → `MAINTAINING.md`. Starting a NEW project from it →
> `scripts/bootstrap.sh <name>`.

## Current state (OVERWRITE this block each update — do not append)

- next_action: `REVIEW-2026-09.6` — the updater: `.bedrock/manifest` shipped with the source, self-replace first, pinned source, migrations, an `UPDATE-<version>` leaf. See `docs/tasks/REVIEW-2026-09.md`.
- active_work_unit: `BEDROCK-MAINTENANCE.3` → executed as tree `REVIEW-2026-09`, frontier leaf `.6` (`pending`).
- latest_commit: `BEDROCK-REVIEW-0006`.
- in_flight_uncommitted: none.
- blockers: none.
