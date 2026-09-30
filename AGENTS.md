# AGENTS.md — agent bootstrap (read this first, whatever AI / harness you are)

This is the **canonical, complete** instruction file. Every harness reads a different file
(`CLAUDE.md`, `GEMINI.md`, `.cursorrules`, …); each of those, when present, is a one-line adapter
that points here and nothing else. A human contributor reads this file too.

This repository is built on a **portable discipline spine**: durable memory, task-tree
tracking, a strict commit workflow, and mechanical doctrine enforcement. The spine is
enforced at the **git level** (hooks + CI), so it holds regardless of which agent or
human is working. Follow it exactly.

<!-- BEDROCK-MAINTAINER-NOTE:START (removed by scripts/bootstrap.sh de-template) -->
> **Maintaining bedrock itself?** If a `MAINTAINING.md` exists at the repo root AND
> `git remote get-url origin` names `bedrock`, this IS the bedrock discipline-spine template and
> your job is to improve the template (not to start a project from it) — **read `MAINTAINING.md`
> first**, then resume from `MEMORY.md` → `docs/tasks/BEDROCK-MAINTENANCE.md`.
> If `MAINTAINING.md` exists but the remote is some other project, this copy was created from the
> template and **never initialised**: stop, run `scripts/bootstrap.sh <project-name>`, and commit
> what it stages. (An initialised project has `.bedrock/project` and no `MAINTAINING.md`.)
<!-- BEDROCK-MAINTAINER-NOTE:END -->


1. Read `README.md` — project objective, layout, standard commands.
2. Read `MEMORY_ARCHITECTURE.md` — the durable 4-layer memory model (**MANDATORY**;
   defines how nothing important is lost across sessions, machines, or harness switches).
3. Read `TOOLBOX.md` — the tools-first doctrine. For ANY unknown / failure / surprising
   result: use or build a diagnostic tool FIRST; never guess a root cause.
4. Read `DOCTRINE_ENFORCEMENT.md` — how every mechanizable doctrine is enforced, and the
   task-acceptance checklist a change MUST pass.
5. Resume from `MEMORY.md` (the bounded layer-A resume pointer) → the active task-tree's
   frontier under `docs/tasks/`.

## The non-negotiables

- **Nothing changes without a task-tree first.** Every code change is owned by a
  task-tree leaf under `docs/tasks/` (index: `docs/TASK_TREE.md`) BEFORE the change is
  made. Track every activity, task, slice, and lane so the project survives a lost session.
- **Record durable facts/decisions** as one-file-per-record notes under `docs/decisions/`
  (index there). Convert relative dates to absolute.
- **Commit per `COMMIT.md`** after each completed leaf, with the work-unit id in the
  subject. A code change must pass the `TOOLBOX.md` / `DOCTRINE_ENFORCEMENT.md` acceptance
  checklist (root cause + addressed + no regression) in its task leaf.
- **Activate the hooks once per clone:** `git config core.hooksPath .githooks`. The
  pre-commit hook runs `scripts/check_doctrines.sh` (the general enforcer); CI runs the
  same. These are git-level and harness-agnostic.
- **Keep the roadmap, the code, and the docs (README + mdBook) aligned** — locked
  together, no drift, for past, present, and future changes.
- **End every session with `scripts/handoff`** and make it print `handoff: OK` — before `/exit`,
  `/clear`, a pause or a handover. It refuses while a project-owned background job runs (a job
  that outlives its session rewrites tracked files under the next one, with its log gone; kill
  stragglers AND their children), while the tree holds uncommitted work (it survives nothing),
  or while `MEMORY.md` is not true for `HEAD`. Green means any agent, in any harness, on any
  machine, resumes from the repository alone (`docs/decisions/decision_context_continuity.md`).
- **The resume pointer is true in every commit.** A governed commit names itself in `MEMORY.md`'s
  `latest_commit` and points at an existing, open frontier leaf (`RESUME-POINTER` gate).
- **The harness and the model are transparent to the project.** Nothing the project depends on
  lives in a harness's own memory or settings; route every rule, fact and decision to a layer.
- **A commit message ends with its own last line** — no agent/tool attribution trailers
  (`COMMIT.md`); the `commit-msg` hook and CI refuse them.

> One rule above all: **information that exists only in the live conversation is not yet
> saved — route it to a layer and commit it before the turn ends.**

## First time in a fresh copy of the template

Run `scripts/bootstrap.sh <project-name>` once. It de-templates the copy, sets the project
name, installs the git hooks, generates the Knowledge Map, verifies the enforcer and seeds the
one leaf (`docs/tasks/BOOTSTRAP.md`) that owns that first commit. It does **not** invent a
task-tree from your roadmap: drop your real roadmap into `ROADMAP.md`, then create your first
tree from `docs/tasks/TEMPLATE.md`. A later clone of an initialised project only needs
`git config core.hooksPath .githooks`.
