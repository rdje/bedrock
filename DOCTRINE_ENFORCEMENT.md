# DOCTRINE_ENFORCEMENT.md — how every mechanizable doctrine is enforced

Discipline holds because it is **mechanical**, not remembered. A rule that lives only in a
doc is a suggestion; a rule wired into a git hook + CI is enforced for every agent and
every human, identically.

## Defense in depth (four layers)

- **E1 — discovery.** The doctrine docs: this file, `README.md`, `MEMORY_ARCHITECTURE.md`,
  `TOOLBOX.md`, `COMMIT.md`, and `docs/decisions/`. Where an agent learns the rules.
- **E2 — self-check.** `scripts/check_doctrines.sh` (the driver) + each registered
  `scripts/check_*.sh`. The single source of truth for "which doctrine is enforced by
  what". Runnable by hand anytime.
- **E3 — git hook.** `.githooks/pre-commit` calls the enforcer; `.githooks/commit-msg`
  checks the subject shape. Activate once per clone: `git config core.hooksPath .githooks`.
- **E4 — CI.** The same enforcer runs in CI (`.github/workflows/doctrines.yml`), so a
  locally `--no-verify`'d hook still fails the build. This is the "no matter what" backstop.

## The enforcer registry

`scripts/check_doctrines.sh` carries the **universal** registry:

| ID | Proves | Check |
| --- | --- | --- |
| `MEMORY-ARCH` | the durable 4-layer memory invariants hold | `scripts/check_memory_architecture.sh` |
| `DOCPATH` | tracked `.md` carry no checkout-specific absolute paths | `scripts/check_docpaths.sh` |
| `TASK-TREE-OWNERSHIP` | every staged code change is owned by a task-tree leaf | `scripts/check_task_tree_ownership.sh` |
| `WAIVER-ROUTING` | a task leaf saying a gate **does not apply** names the leaf that owns fixing it — ⭐ *an author writing a waiver IS the gate reporting a missing capability*, the highest-signal defect report a gate can receive. Deliberately does **not** punish honesty: the waiver stays legal, it just has to name an owner | `scripts/check_waiver_routing.sh` |
| `README-STABILITY` | `README.md` stays a stable landing page — a **line cap AND a byte cap**, because a line cap alone is measurably bypassable (a real project running this spine passed its 60-line layer-A cap while carrying 138,403 bytes) | `scripts/check_readme_stability.sh` |
| `KNOWLEDGE-MAP` | the derived Knowledge Map is in sync (if the subsystem exists) | `knowledge-map/scripts/check_knowledge_map.sh` |
| `PROJECT-SPECIFIC` | this project's own doctrines | `scripts/check_doctrines.project.sh` |

**Project-specific doctrines go in `scripts/check_doctrines.project.sh`** (the pluggable
slot) — never in the universal driver. That is where a project adds the equivalent of its
own build gates, format checks, invariant proofs, etc.

## Adding a doctrine

1. Write `scripts/check_<name>.sh` — cheap, deterministic, self-describing; exit nonzero
   with a one-line stderr message on breach. Keep it fast (heavy proofs belong in CI).
2. Register it — universal → the `DOCTRINES` array in the driver; project → append it to
   `scripts/check_doctrines.project.sh`.
3. Mirror it in the table above (this file is the human-readable mirror of the registry).

## The task-acceptance checklist (every code-change leaf must pass)

A code change cannot commit until its owning task-tree leaf records all six:

- [ ] **REPRODUCE / ISSUE** — the problem, shown (not asserted).
- [ ] **ROOT CAUSE (WHY + WHERE)** — tool-backed and pinpointed (`TOOLBOX.md`).
- [ ] **FIX** — the change, made at the lowest-risk level that actually works.
- [ ] **ADDRESSED (verified)** — measured before→after (the global metric where one exists).
- [ ] **NO REGRESSION** — the guard set stays green; state how you proved it.
- [ ] **LOCKSTEP** — live docs (`MEMORY.md`, `CHANGELOG.md`, `DEV_NOTES.md`,
  `LIVE_STATUS.md`), the book, and any trackers updated in the SAME commit.
