# Task-Tree Workflow

This document defines the repo-local task-tree workflow. A step-by-step setup guide is in
[TASK_TREE_README.md](TASK_TREE_README.md). Individual trees live under
[`tasks/`](tasks/); the leaf template is [`tasks/TEMPLATE.md`](tasks/TEMPLATE.md).

## Purpose

Use a task tree when a top-level task is too broad to finish safely as one signoff-quality
slice, or when it is expected to discover subtasks over time. The tree owns the recursive
breakdown, current frontier, acceptance criteria, blockers, decisions, validation, and
completion evidence for one top-level task — so the project survives a lost session and
continuity holds across sessions, machines, and harness switches.

The tree is not a second roadmap. `ROADMAP.md` states the high-level direction; a task tree
owns the disciplined execution of one lane of it.

## Code-change doctrine (binding, non-negotiable)

**It is strictly forbidden to change any governed path unless a task-tree leaf owns the change
in the same commit.** Every path is governed except documentation (Markdown, text, licence files,
images, and what `.doctrine/docs_paths.txt` declares): sources in any language, build files, the
hooks and workflows, `.doctrine/`, generated artifacts, anything altering behaviour. Before
touching one, a leaf must exist that owns the change (create/extend a tree, or add a leaf); the
commit subject names it, `(leaf <TREE-ID>.<n>)`, and the leaf's section gains that commit's row
and evidence. The leaf — its goal, acceptance, verification, and commit — is the unit of
traceability. Enforced by `scripts/check_task_tree_ownership.sh` and
`scripts/check_task_acceptance.sh` at commit time and per commit in CI.

## Leaf lifecycle (statuses)

`proposed` → `pending` → `active`/`in_progress` → `done`. A leaf is `done` only when its
acceptance criteria are met, verification is recorded, and it is committed via `COMMIT.md`.
Mark `blocked` (with the blocker named) rather than leaving a stalled leaf `active`.

## The pivot rule

**Do not pivot to a different task-tree while the repo is dirty.** The repo is
handoff-ready only when the tree is clean (no modified/untracked work except the task-tree
file itself). Finish the current leaf and get the repo clean before switching — even if
asked to pivot immediately. The guarantor of repo integrity holds this line.

## Commit traceability

Each slice uses a work-unit id in the commit subject (e.g. `MYPROJ-AREA-0007`). When the
slice belongs to a leaf, the subject also names the leaf ID (e.g. `MYPROJ-AREA-0007 (leaf
FEATURE-X.2): …`), so the slice id and the tree node coexist on the same commit. An open leaf
may own several commits; a `done` leaf owns none — a follow-up is a child leaf.

## Active Task Trees

| Tree | Status | Frontier (next leaf) | Owner |
| --- | --- | --- | --- |
| [`BEDROCK-MAINTENANCE`](tasks/BEDROCK-MAINTENANCE.md) | `active` | `.3` — the 2026-09-30 review, executed in `REVIEW-2026-09` | repo-local |
| [`REVIEW-2026-09`](tasks/REVIEW-2026-09.md) | `active` | `.9` — the maintainer's guide, reconciled documents, neutrality in CI, 1.0.0 | repo-local |

> _Note: `BEDROCK-MAINTENANCE` is bedrock's own maintenance tree (see `MAINTAINING.md`). A
> project generated from bedrock (via `scripts/bootstrap.sh`) starts with no trees — that
> row is removed and you seed your own from `ROADMAP.md`._
