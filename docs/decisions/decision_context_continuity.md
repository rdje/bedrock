# Context continuity: a bedrock project resumes from the repository alone, under any harness, after any session end

- **Type:** `decision`
- **Date:** `2026-09-30`
- **Status:** `active`
- **Owner / source:** maintainer instruction 2026-09-30 (*"any project spawned out of bedrock can
  change or switch the harness and AI model at any time at any handoff-ready state with no harm
  … the spine should ensure 100% context continuity across session `/exit`s, `/clear`s or
  crashes … it shall become almost a guaranteed feature"*)

## The fact / decision

A project created from bedrock has two properties, and the spine makes both **mechanical**:

1. **Harness and agent transparency.** The harness and the AI model working on the project can be
   switched at any handoff-ready state with no effect on the project. Nothing the project depends
   on lives in a harness's own memory, settings or scrollback: `AGENTS.md` is the canonical
   instruction file and every harness file is an optional adapter (enforced by `MEMORY-ARCH`);
   spine logic never names a harness or a model, and harness knowledge is data under
   `.doctrine/` (the neutrality lint, `REVIEW-2026-09.9`).
2. **Context continuity.** After any session end — `/exit`, `/clear`, a crash, a machine loss
   once pushed — a fresh agent in any harness resumes with full context from the repository
   alone, by the read path in `MEMORY_ARCHITECTURE.md` §5. The spine guarantees it by:
   - **the resume pointer is true at every commit** (`RESUME-POINTER`, `REVIEW-2026-09.10`): at
     `commit-msg` time and per commit in CI, `MEMORY.md`'s `latest_commit` names the work-unit id
     of the commit being made when the change is governed, the named `active_work_unit`'s tree
     file and frontier leaf exist and the leaf is open, and `next_action` is not empty;
   - **one hand-off command** (`scripts/handoff`, `REVIEW-2026-09.10`): the background-job census,
     a clean tree (or only the active tree file modified), and the pointer matching `HEAD`; it
     prints `handoff: OK` and is the last command of every session, named in `AGENTS.md`;
   - **the resume protocol is tested**: the conformance suite clones a child at `HEAD` and resumes
     it from `MEMORY.md` alone.

## Why

The four memory layers already made continuity *possible*; no gate made it *checked*. A pointer
whose `latest_commit` is stale, or whose frontier leaf no longer exists, is exactly how a resumed
session starts wrong, and every gate in the reviewed tree was blind to it. A harness's own memory
cannot be the system of record because a harness switch loses it (`MEMORY_ARCHITECTURE.md` §1).

## How to apply

- Overwrite `MEMORY.md`'s current-state block in every governed commit; the gate requires it.
- End every session with `scripts/handoff` and make it print `handoff: OK`.
- Never leave a rule, fact or decision only in a harness file or a harness's memory; route it to
  a layer and commit it.
- Related: [[decision_neutral_spine_and_packs]], [[decision_ownership_contract]].
