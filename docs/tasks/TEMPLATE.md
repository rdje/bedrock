# <TREE-ID>: <Task Title>

## Metadata

- Tree ID: `<TREE-ID>`
- Status: `proposed`
- Roadmap lane: `<roadmap lane name>`
- Created: `YYYY-MM-DD`
- Owner: repo-local workflow

## Goal

State the exact outcome this top-level task must deliver.

## Non-Goals

- State what this task deliberately does not solve.

## Acceptance Criteria

- The behavior, documentation, or infrastructure outcome is implemented.
- Focused validation passes.
- Broader validation runs when the blast radius warrants it.
- Live docs and roadmap status are updated where project state changed.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `<TREE-ID>`
  Status: `active`
  Goal: `<top-level goal>`
  Children: `<TREE-ID>.1`

- ID: `<TREE-ID>.1`
  Status: `pending`
  Goal: `<first executable leaf>`
  Acceptance: `<what proves this leaf is done>`
  Verification: `pending`
  Commit: `pending`

  ### Acceptance Checklist (enforced by `TASK-ACCEPTANCE` — one per leaf, INSIDE the leaf)

  - [ ] **ROOT CAUSE (WHY + WHERE)** — `<command you ran>` → `<its real output>` (`rc=<n>`), naming the mechanism and the location
  - [ ] **ADDRESSED (verified)** — before: `<measurement>` → after: `<measurement>` (`rc=0`)
  - [ ] **NO REGRESSION** — `<the suite / gate you re-ran>` → `<its result line>` (`rc=0`)
  - [ ] **FIX** — <the minimal change made> *(not hard-gated)*
  - [ ] **LOCKSTEP** — <docs / contracts / index updated, or N/A + reason> *(not hard-gated)*

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `<TREE-ID>.1` | `pending` | `<reason>` |

## Decisions

- `YYYY-MM-DD`: `<decision and rationale>`

## Open Questions

- `<question, owner, and why it does or does not block the frontier>`

## Blockers

- None.

## How a leaf owns a change (the ownership contract)

Every path except documentation is **governed**: it lands only in a commit whose subject names
**one** leaf, `<WORK-UNIT-ID> (leaf <TREE-ID>.<n>): <summary>`, and that leaf's section in this
file gains its commit-log row and its evidence **in the same commit**. An open leaf may own several
commits; a leaf already `done` may own none — open a child leaf (`<TREE-ID>.<n>.<m>`). Enforced by
`TASK-TREE-OWNERSHIP` and `TASK-ACCEPTANCE` at commit time and per commit in CI.

The checklist lives **inside each leaf** (above). The three hard-gated boxes must be ticked, carry
the label at the start of the bold text, and hold tool output **inside a code span of that box's
own bullet**: `` `command` → `result` (`rc=0`) ``, or the line `scripts/evidence -- <command>`
prints. Prose, a version number or a tool's name is not evidence. A tick is a claim; the pasted
output is the artifact someone else can re-run.

⚠️ If none of the built-in result signatures fit your tools, do **not** fake one and do **not**
quietly drop the box: declare your tool's output shape in `.doctrine/evidence_tokens.txt` (see
`.doctrine/README.md`). If you find yourself wanting to waive the gate instead, write the waiver
**and name the leaf that owns fixing the gate** — that is the `WAIVER-ROUTING` doctrine, and an
author hitting a gate's boundary is the highest-signal defect report the gate can receive. A
deliberate exception to ownership is a trailer, `Spine-Exception: <why no leaf applies>`, which CI
lists and counts.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `YYYY-MM-DD` | `<TREE-ID>.1` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `<TREE-ID>.1` | `pending` | `pending` |

## Changelog

- `YYYY-MM-DD`: Created task tree.
