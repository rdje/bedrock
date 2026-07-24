# MAINTAINING bedrock — read this if you are improving the TEMPLATE itself

> **You are here to work on bedrock the template, not to start a new project from it.**
> (Starting a new project? Run `scripts/bootstrap.sh <name>` — it resets this repo's
> maintainer files to a clean consumer seed and removes this guide.)
>
> This document exists because **no memory of building bedrock survives a session**. It is
> the baton-hand-off: read it and you have full context on what bedrock is, where it came
> from, and how to evolve it — with nothing lost.

## What bedrock is

bedrock is a **project-neutral, harness-agnostic discipline spine** for new Rust projects:
durable 4-layer memory, task-tree tracking, a strict commit workflow, mechanical doctrine
enforcement (git hooks + CI), a derived knowledge map, and an mdBook — all wired together
and **self-enforcing on a fresh clone**. A new project copies bedrock, drops its roadmap
into `ROADMAP.md`, runs `bootstrap.sh`, and grows with that spine as its backbone.

## Provenance & relationship to PGEN (the most important context)

- bedrock is the **neutral spine extracted from PGEN** — a mature, real Rust project (a
  parser generator) that developed and battle-tested this discipline over a long campaign.
  PGEN lives at `../pgen` — a **separate** git repo, typically a sibling directory of bedrock.
- **PGEN is the reference implementation / proving ground.** New doctrines, enforcement
  patterns, and memory-architecture refinements are invented and hardened in PGEN first,
  against a real workload. bedrock is where the **general** parts of that are distilled so
  *any* Rust project benefits.
- **Direction of flow:** PGEN → (generalize) → bedrock → (`update_scaffold.sh`) → other
  projects. bedrock does not depend on PGEN and contains no PGEN-specific content.
- **Boundary rule (the user's standing instruction):** keep bedrock content **out of
  PGEN's git**, and keep PGEN-specific content **out of bedrock**. They are deliberately
  separate. Created 2026-07-24.

## The neutral / project-specific boundary

| Belongs in the bedrock spine (general) | Stays PGEN-specific (never ported) |
| --- | --- |
| Memory architecture (`MEMORY_ARCHITECTURE.md`, the 4 layers) | The grammars / parsers / EBNF / SV / regex domain |
| Task-tree workflow + templates | `EBNF-SOURCE-OF-TRUTH`, `REGEX-SELF-HOSTING` checks |
| Commit workflow (`COMMIT.md`) | cert-coverage / ast-shape-contract / syntax-closure gates |
| Doctrine enforcer **driver + universal checks** | Any check that names a grammar/parser/domain artifact |
| `TOOLBOX.md` (tools-first, generalized) | The specific probes/tracers PGEN ships |
| Knowledge map (derived, drift-proof) | The book content about a specific product |
| The git hooks + CI enforcement layers | Release/version/ledger schemes tied to a product |

The litmus test for porting something from PGEN: **would it help a brand-new, unrelated
Rust project?** If yes → generalize (strip every domain noun) and add it to the spine. If
it only makes sense with grammars/parsers/etc. → it stays in PGEN.

## How to transfer a PGEN improvement into bedrock

1. **Spot it.** A structural/doctrine/memory-arch/enforcement improvement lands in PGEN.
2. **Classify it** against the boundary above (general vs PGEN-specific). Only general
   improvements come across.
3. **Neutralize it.** Remove all domain nouns (grammar, parser, EBNF, SV, regex, corpus,
   the specific gate names). What remains should read as if bedrock never knew about PGEN.
4. **Land it in bedrock** under a `BEDROCK-MAINTENANCE` task-tree leaf (bedrock maintains
   *itself* with its own discipline — task-tree first, `COMMIT.md`, the enforcer).
5. **If it is a re-syncable neutral file**, ensure it is in the `NEUTRAL` allow-list in
   `scripts/update_scaffold.sh` so downstream projects can pull it.
6. **Bump `DOCTRINE_VERSION`** and note the change in `CHANGELOG.md`.

Downstream projects then adopt it with `scripts/update_scaffold.sh <bedrock-url>`.

## This repo's dual role (why its own memory files look "used")

bedrock is **both** a template *and* a real project (its project = "maintain the spine").
So this repo's own layer-A/B/C memory describes the maintenance work:

- `MEMORY.md` — bedrock's resume pointer (points here + to the maintenance tree).
- `docs/tasks/BEDROCK-MAINTENANCE.md` — the living maintenance task-tree (frontier + backlog).
- `docs/decisions/reference_bedrock_provenance.md` — the durable provenance/boundary facts.
- `ROADMAP.md` — kept as the **consumer** placeholder (the canonical "replace me" file);
  bedrock's own roadmap is the maintenance tree above.

`scripts/bootstrap.sh` de-templates for a consumer: it resets `MEMORY.md` to a clean seed
and removes this guide + the maintenance tree + the provenance record, so a new project
starts fresh.

## File inventory (the spine)

- Bootstrap: `CLAUDE.md`, `AGENTS.md`. Memory: `MEMORY_ARCHITECTURE.md`, `MEMORY.md`.
- Task-trees: `docs/TASK_TREE.md`, `docs/TASK_TREE_README.md`, `docs/tasks/`.
- Decisions: `docs/decisions/` (+ `INDEX.md`). Commit: `COMMIT.md`.
- Enforcement: `DOCTRINE_ENFORCEMENT.md`, `scripts/check_doctrines.sh` (+ universal
  `check_*.sh`), `scripts/check_doctrines.project.sh` (project slot), `.githooks/`,
  `.github/workflows/`.
- Tools-first: `TOOLBOX.md`. Knowledge map: `KNOWLEDGE_MAP.md` (derived), `knowledge-map/`.
- Docs surface: `docs/book/` (mdBook). Live-docs: `CHANGELOG.md`, `DEV_NOTES.md`,
  `LIVE_STATUS.md`. Rust: `Cargo.toml`, `crates/`, `Makefile`, `rust-toolchain.toml`.
- Consumer entry: `ROADMAP.md`. Versioning: `DOCTRINE_VERSION`. Sync: `scripts/update_scaffold.sh`.

## Working on bedrock

Use bedrock's own discipline on bedrock: create/extend a `BEDROCK-MAINTENANCE` leaf before
changing spine files, run `make gate` (the enforcer), commit via `COMMIT.md`. The enforcer
must stay green — bedrock has to practice what it preaches.
