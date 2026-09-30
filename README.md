# bedrock — a project discipline-spine template

**bedrock** is a starting point for a new project in **any language, under any AI harness or
none**, with a battle-tested *discipline spine* already wired in: durable memory, task-tree
tracking, a strict commit workflow, mechanical doctrine enforcement, and a knowledge map. A
language, a docs tool or a harness file is an opt-in **pack**. Create a project from it, drop
in your roadmap, and grow the project with that spine as its backbone.

## Why a spine

Discipline that lives in an agent's head evaporates on session loss, a model switch, or a
new contributor. bedrock puts the discipline **in the repo** and enforces it at the **git
level** (pre-commit hook + CI), so it holds for any agent — Claude Code, Codex, Gemini,
Cursor, a custom runner — or a human, identically.

## What's inside (the spine)

| File / dir | What it gives you |
| --- | --- |
| `AGENTS.md` | the canonical, harness-neutral agent bootstrap (read this first); `CLAUDE.md` is an optional adapter |
| `MEMORY_ARCHITECTURE.md` | the durable 4-layer memory model (A resume pointer · B task-trees · C decisions · D git) |
| `docs/TASK_TREE.md` + `docs/tasks/` | task-tree tracking — nothing changes without a leaf |
| `COMMIT.md` | the strict, repeatable commit workflow |
| `DOCTRINE_ENFORCEMENT.md` + `scripts/check_doctrines.sh` | the mechanical enforcer (registry + universal checks + a project slot) |
| `TOOLBOX.md` | the tools-first diagnostic doctrine |
| `VISIBILITY.md` | the repository's declared visibility posture — **public**, and what that means for confidential material |
| `KNOWLEDGE_MAP.md` + `knowledge-map/` | a derived, drift-proof orientation map |
| `.githooks/` + `.github/workflows/` | the E3 (hook) + E4 (CI) enforcement layers |
| `scripts/gate` · `scripts/run <verb>` · `scripts/handoff` | the enforcer; the project's declared commands; the session-end check |
| `MEMORY.md` · `CHANGELOG.md` · `DEV_NOTES.md` · `LIVE_STATUS.md` | the seeded live-docs |
| `ROADMAP.md` | **the one file you replace** — your project's roadmap |
| `packs/` | opt-in: `lang/rust`, `docs/mdbook`, harness adapters (`claude`, `gemini`, `cursor`, `copilot`, `windsurf`) — see `packs/README.md` |

## Use it

**The stress-free way** — clone bedrock once, then let it ask you the questions:

```bash
git clone https://github.com/rdje/bedrock && cd bedrock && scripts/new_project.sh
```

It asks for a name, a title, a work-unit prefix, the visibility, a language pack, a docs pack and
harness adapters (Enter accepts each default, every choice is listed), shows a summary, then
creates the repository — on GitHub from this template when `gh` is logged in, otherwise locally —
bootstraps it with your answers, makes the first commit through the hooks and offers the push.

**Or from GitHub's "Use this template"** button: clone your new repository, `cd` into it, and run
`./scripts/bootstrap.sh` on a terminal — the same questions — then **commit with the exact command
it prints**. Flags answer in advance: `./scripts/bootstrap.sh <name> --lang rust --harness claude --yes`.

Then: replace `ROADMAP.md` with your roadmap, create your first task-tree from
`docs/tasks/TEMPLATE.md` and register it in `docs/TASK_TREE.md`, grow the project one leaf at a
time via `COMMIT.md`, and end every session with `scripts/handoff`. Anyone who clones the project
later runs only `./scripts/bootstrap.sh --contributor` — never the naming bootstrap.

## Keep the spine current

bedrock improves over time. To pull the latest spine into a project you already created, run:

```bash
./scripts/update_scaffold.sh <bedrock-repo-url> [--ref <tag>] [--plan]
```

It acts by ownership class (`.bedrock/manifest`, read from the source): a spine file you never
touched is updated, one you changed is never overwritten (theirs lands in `.bedrock-incoming/`),
your own files are not touched. It replaces itself first, runs the migrations your version
needs, seeds an `UPDATE-<version>` leaf, and prints the commit. `--plan` shows the plan and
writes nothing. The spine version is recorded in `DOCTRINE_VERSION`.

This README is deliberately a **landing page**, governed by [`README_POLICY.md`](README_POLICY.md)
and mechanically capped (line **and** byte) by the `README-STABILITY` doctrine. Route changing
detail to its canonical home rather than growing this file.

## The non-negotiables (full detail in `AGENTS.md`)

- Nothing changes without a **task-tree leaf** first.
- Record durable facts/decisions in `docs/decisions/`.
- Commit per `COMMIT.md`; the hooks + CI enforce the doctrines.
- Keep **roadmap ↔ code ↔ docs** in lockstep, always.

## Licence

The spine is LGPL-2.1-or-later (`LICENSE`); a project built on it keeps its own licence for its
own work, and the seed files are 0BSD — see `NOTICE`.
