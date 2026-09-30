# MAINTAINING bedrock — the maintainer's guide (read this if you are improving the TEMPLATE itself)

> **You are here to work on bedrock the template, not to start a new project from it.**
> (Starting a new project? `scripts/new_project.sh` from this clone, or `scripts/bootstrap.sh`
> in a copy made with GitHub's *Use this template*.)
>
> This document is the baton hand-off: **no memory of building bedrock survives a session**, so
> everything the next agent — any model, any harness — needs to keep enhancing bedrock is here or
> reachable from here. Then resume from `MEMORY.md` → `docs/tasks/BEDROCK-MAINTENANCE.md`.

## What bedrock is

bedrock is a **project-, harness- and language-neutral discipline spine** for new projects:
durable 4-layer memory, task-tree tracking, a strict commit workflow, mechanical doctrine
enforcement (git hooks + CI, per commit), a derived knowledge map, and a hand-off check that
proves a project resumable from the repository alone — all wired together and
**self-enforcing on a fresh clone**. A language, a docs tool or a harness file is an opt-in
**pack**, never part of the spine ([`decision_neutral_spine_and_packs`](docs/decisions/decision_neutral_spine_and_packs.md)).
A child project keeps working when its harness or model is switched at any hand-off, and resumes
with full context after any session end ([`decision_context_continuity`](docs/decisions/decision_context_continuity.md)).

## What bedrock is for — the bar every enhancement is measured against

The maintainer's own words (2026-07-30 and 2026-09-30): bedrock *"shall be usable for any project,
any harness, any coding language — project-, harness- and language-neutral, agnostic — and serve as
a common basis for **SOTA, sign-off and production-grade** doctrine-based, policy-based, rule-based
projects with a **very high level of maintainability**"*; a project spawned from it *"can change or
switch the harness and the AI model at any hand-off-ready state with no harm, with 100 % context
continuity across `/exit`, `/clear` and crashes — almost a guaranteed feature"*; and *"the next
agent shall be able to keep enhancing bedrock by adding new doctrines, new packs, new SOTA,
sign-off and production-grade features to make it even greater."*

So an enhancement is judged by one question before any other: **does it raise that bar for every
project created from bedrock, on day one, without naming a language, a tool or a harness in the
spine?** If yes, it is a doctrine, a seam or a spine tool. If it needs a language, a tool or a
harness, it is a pack. If it helps only one project, it stays in that project. The admission test
below makes this mechanical; the ranked backlog in `docs/tasks/BEDROCK-MAINTENANCE.md` (leaf `.4`)
is that question applied to what is known today.

## The architecture, in one screen

| Layer | Where | What to know before touching it |
| --- | --- | --- |
| **The library** | `scripts/lib/spine.sh` | every check sources it: fail-closed prelude, the exit contract `0 holds · 1 breach · 2 REFUSED`, the change context (`before`/`after`; the index or a commit, never the worktree), reads through `spine_read`, changes through `spine_changes` (deletions and renames included), `.doctrine/` read from `before`, scratch outside the worktree, message parsing, leaf-section parsing, the resume-pointer parsers. Never call `spine_refuse` inside `$( )` — it ends the subshell only. |
| **The driver** | `scripts/check_doctrines.sh` (`scripts/gate`) | the registry of checks; `--message` (commit-msg hook), `--commit <rev>` / `--range a..b` (CI, per commit); reports `⏸ not evaluated`, `⚠️ EXCEPTION`, `⛔ REFUSED` |
| **The ownership contract** | `check_task_tree_ownership.sh`, `check_task_acceptance.sh`, `check_commit_message.sh`, `check_resume_pointer.sh` | [`decision_ownership_contract`](docs/decisions/decision_ownership_contract.md): deny-by-default governance, the leaf bound by `(leaf <ID>)` in the subject, evidence new in the diff and inside code spans, a done leaf owns nothing, `Spine-Exception:` trailers, `MEMORY.md` true for every governed commit. All message-time checks. |
| **The project seams** | `.doctrine/` | data, never code: `config`, `docs_paths.txt`, `evidence_tokens.txt`, `commands`, `agent_identities`, `handoff_ignore`, `harness_adapters`, `neutrality_terms`, `neutrality_allow`. Packs append; projects declare. A spine script that needs a language or harness name is a defect (`NEUTRALITY` gate). |
| **The manifest** | `.bedrock/manifest` (`MANIFEST` gate) | every shipped path classified `spine` / `seed` / `project` / `maintainer` / `pack`; the updater's ground truth, read from the SOURCE. An unclassified path is refused. |
| **The updater** | `scripts/update_scaffold.sh` | [`decision_updater_ownership_classes`](docs/decisions/decision_updater_ownership_classes.md): replaces itself first, fast-forwards an unmodified spine file, never touches a modified one, runs `migrations/`, seeds an `UPDATE-<version>` leaf, writes `DOCTRINE_VERSION` only after the gate passes; `--plan`, `--add-pack`. |
| **The packs** | `packs/<kind>/<name>/` | `pack` manifest (`key = value`: `order`, `default`, `seed`, `sync`, fragments, `install`), `files/`, fragments, an install hook that prints measured evidence. See `packs/README.md`. |
| **The setup** | `scripts/bootstrap.sh`, `scripts/new_project.sh`, `scripts/lib/setup_questions.sh` | the guided questions (choices listed, defaults on Enter, re-ask, summary, confirmation), flags as the non-interactive path, validation before any write, literal edits, evidence measured over the staged first commit. |
| **The conformance suite** | `scripts/tests/spine_tests.sh` | THE regression harness: builds children from the working tree (no pack, packs, old bedrock versions), runs every scenario as a `req` or `xfail` arm; an `xfail` that starts passing fails the run. Run it before every commit that touches a script; CI runs it on Linux and macOS. |
| **The user guide** | `docs/book/` (`BOOK-COVERAGE` gate), `.github/workflows/book.yml` | the guided read for a person — <https://rdje.github.io/bedrock/>, built with mdBook and published by the workflow on every push to `main`. Maintainer-class: a child never inherits it. The gate refuses a doctrine, entry point, `.doctrine/` seam, pack or migration the book does not name, so a new one cannot land undocumented. |
| **The session end** | `scripts/handoff` | census of background jobs, a clean tree, the pointer true against the latest governed commit, unpushed commits listed. |

The three decisions above, plus [`decision_licence`](docs/decisions/decision_licence.md), are the
contract; the review that produced them is `docs/reviews/2026-09-30-consolidated-review.md`.

## Recipes

Every recipe starts the same way: open a leaf under `docs/tasks/BEDROCK-MAINTENANCE.md` (or a
tree of its own for a large change, as `REVIEW-2026-09` was), and ends the same way: the suite
green, the leaf's checklist carrying the measured evidence, `DOCTRINE_VERSION` bumped,
`CHANGELOG.md` telling existing children what changed and what to do, `scripts/handoff` → `OK`.

### Add a doctrine (a new check)

1. **Pass the admission test** below (Q0, Q1, Q2 — in that order). Write, in one sentence with no
   project's nouns, what the check prevents.
2. Write `scripts/check_<name>.sh`: source `scripts/lib/spine.sh`, `spine_init <ID>`, read the
   change through `spine_changed_paths` / `spine_read` / `spine_added_lines`, honour the exit
   contract, put a `--self-test` in it (RED and GREEN arms, the founding case pinned verbatim).
   Header: what it prevents, the measured incident behind it, the honest limit.
3. Register it in the driver's `DOCTRINES` array, mirror the row in `DOCTRINE_ENFORCEMENT.md`, and
   document it in the user guide (`docs/book/src/gates.md`: what it holds, how to satisfy it) — the
   `BOOK-COVERAGE` gate refuses a registered doctrine the book does not name.
4. Add `req` arms to `scripts/tests/spine_tests.sh` (the RED case refused **by the named check**,
   the GREEN control passing); wire the `--self-test` into the CI job's list.
5. Classify the script in `.bedrock/manifest` (`spine`). If it needs project data, add a
   `.doctrine/<file>` seed (class `seed`) and document it in `.doctrine/README.md`.
6. If it changes the SHAPE of content earlier templates created, ship a migration.

### Add a pack (a language, a docs tool, a harness)

1. `packs/<kind>/<name>/pack`: `name`, `kind`, `order`, `default`, `title`, `seed` (paths the
   project will own), `sync` (pack-owned paths the updater fast-forwards), the fragment file
   names, `install`.
2. `files/` — copied into the project root at install; keep starter code minimal and named after
   the project by the install hook, which prints measured evidence lines (`rc=…` in code spans).
3. Fragments: `commands` (the verbs `scripts/run` exposes), `evidence_tokens` (what the
   language's tools print), `gitignore`, `docs_paths`, `handoff_ignore` (a harness's session
   processes). A harness that reads `AGENTS.md` natively ships no adapter file — verify against
   the harness's current documentation and say so in the title.
4. Classify `packs/<kind>/<name>/` as `pack` in the manifest; add its terms to
   `.doctrine/neutrality_terms`; add a suite arm that bootstraps a child with the pack, runs its
   `check` verb when the toolchain is present, and proves an unowned change in its language is
   refused; add its toolchain to the CI self-test job if the arm needs it.
5. Migration 0006 detects packs older children already carry — extend it if the pack has a
   recognisable footprint.
6. Add its row to the user guide's pack table (`docs/book/src/packs.md`); `BOOK-COVERAGE` refuses a
   pack the book does not name.

### Add a migration

`migrations/NNNN-<slug>.sh` with `# since: <version>` (the version whose change it accompanies),
idempotent, printing what it changed, exiting nonzero on failure. Test it in a suite arm built
from the last bedrock commit that did not have the change (`old_child <rev>`), and add its row to
the migrations table in `docs/book/src/updating.md`.

### Cut a release

Bump `DOCTRINE_VERSION` (the manifest's `since` column names the version that added a path);
write the `CHANGELOG.md` entry with a **"for existing children"** paragraph (what changes for them,
what to run); run the suite under bash 5 and `/bin/bash` 3.2; `scripts/handoff`. Tag the commit.
Children upgrade with `scripts/update_scaffold.sh <bedrock> --ref <tag>`.

### Port an improvement from a child (transfer runs both ways)

See "How to transfer" and "Transfer runs BOTH WAYS" below; the mechanical part is: does the
child's version of an invariant beat bedrock's? Then it comes here, neutralised, with its own
suite arm — and the child's leaf notes that the fix is owed upstream.

### Run everything

```bash
scripts/gate                          # the enforcer on the index
scripts/tests/spine_tests.sh          # the suite (≈ 5 min); --only <arm>, --list, --keep
/bin/bash scripts/tests/spine_tests.sh   # the same under stock bash 3.2 (macOS)
for c in scripts/check_*.sh; do bash "$c" --self-test 2>/dev/null; done
bash docs/tasks/artifacts/*/run_*_probes.sh
scripts/handoff
```

## Provenance & relationship to PGEN (the most important context)

- bedrock is the **neutral spine extracted from PGEN** — a mature, real Rust project (a
  parser generator) that developed and battle-tested this discipline over a long campaign.
  PGEN lives at `../pgen` — a **separate** git repo, typically a sibling directory of bedrock.
- **PGEN is the reference implementation / proving ground.** New doctrines, enforcement
  patterns, and memory-architecture refinements are invented and hardened in PGEN first,
  against a real workload. bedrock is where the **general** parts of that are distilled so
  *any* project benefits, whatever its language or harness.
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

The litmus test for porting something from PGEN is the admission test below, on all three
axes: **would it help a brand-new, unrelated project, in any language, driven by any harness or
by a human?** If yes → generalize (strip every domain noun) and add it to the spine. If it only
makes sense with grammars/parsers/etc. → it stays in PGEN. If it only makes sense with one
language, build tool, docs tool or harness → it is a **pack**, not the spine.

## How to transfer a PGEN improvement into bedrock

1. **Spot it.** A structural/doctrine/memory-arch/enforcement improvement lands in PGEN.
2. **Classify it** against the boundary above (general vs PGEN-specific). Only general
   improvements come across.
3. **Neutralize it.** Remove all domain nouns (grammar, parser, EBNF, SV, regex, corpus,
   the specific gate names). What remains should read as if bedrock never knew about PGEN.
4. **Land it in bedrock** under a `BEDROCK-MAINTENANCE` task-tree leaf (bedrock maintains
   *itself* with its own discipline — task-tree first, `COMMIT.md`, the enforcer).
5. **Classify it in `.bedrock/manifest`** (`spine` if it never carries project content, `seed` if the
   project owns it after creation, `maintainer` if it is bedrock-only). The `MANIFEST` gate refuses an
   unclassified path, and `scripts/update_scaffold.sh` reads the manifest from the source it fetches.
   If the change alters the SHAPE of content earlier templates created, ship a migration under
   `migrations/` (`NNNN-<slug>.sh`, `# since: <version>`, idempotent).
6. **Bump `DOCTRINE_VERSION`** and note the change in `CHANGELOG.md`.

Downstream projects then adopt it with `scripts/update_scaffold.sh <bedrock-url>`.

## The neutrality bar — every doctrine here must be objectively applicable to ANY project

> **Maintainer directive, 2026-07-30:** *"The next projects I will start using bedrock as a
> template should inherit the best of the best, the best SOTA, best signoff, the best discipline,
> that we currently have"* — and *"the doctrines in bedrock shall be project neutral, agnostic …
> objectively applicable to any project, not just [the originating one]."*

Two obligations, and they pull against each other on purpose:

1. **Completeness** — a general improvement that lands upstream and is *not* ported is a defect in
   every project started afterwards. bedrock is a seed, not an archive.
2. **Neutrality** — a doctrine only belongs here if it is *objectively applicable to any project*.
   A check that merely had its nouns renamed is not neutral; a check whose LOGIC names a
   domain artifact is domain-bound however it is described.

### The admission test — ask these three, IN THIS ORDER

**Q0 (the pack gate — a question about WHERE it belongs, asked before value):**
> *Does its logic name a language, a build or docs tool, or a harness?*

If it does, it is not spine material however useful it is: it goes under `packs/` (a language
pack, a docs pack or a harness adapter), with its own commands, evidence signatures, install
hook and CI, and the spine sees it only as data declared under `.doctrine/`. The three axes are
**project**, **harness** and **language**; the spine must pass all three, and Q1 below is asked
about a project *in any language, driven by any harness or by a human*. Measured on the reviewed
tree (`docs/reviews/2026-09-30-consolidated-review.md` §5.1): 49 logic lines named a language
and 5 named a harness, and every one of them was a gate that a non-Rust or non-Claude child
passed without being judged.

**Q1 (primary, and it is a question about VALUE):**
> *Does this objectively benefit **any** present and **any** future project — in any language,
> driven by any harness or by a human?*

Answer it by stating, in one sentence and using **no project's nouns**, what the check prevents —
then asking whether a brand-new project would be better off with it **on day one**. If the honest
answer needs a qualifier — *"any project **that** uses X"*, *"once a project **has** Y"* — then it
is **conditional, not objective**, and it does not belong here as-is.

**Q2 (secondary, and it is only a filter):**
> *Can it be expressed without domain nouns?*

```sh
sed 's/#.*//' scripts/check_<doctrine>.sh | grep -ciE '<domain nouns>'   # must be 0
```

⛔⛔ **Q2 CANNOT SUBSTITUTE FOR Q1, AND THE ORDERING IS THE WHOLE POINT.** A check can score **0**
domain nouns and still encode a workflow only one project needs — *neutral vocabulary, project-shaped
substance*. Q2 measures whether a thing **can** be neutralized; Q1 asks whether it **should** be.
Running Q2 first waves the impostors straight through.

⭐ **Worked example, measured — this is not hypothetical.** A "destructive automation must require
explicit confirmation" check scored well on Q2 and looked like an easy win. Its logic hardcodes a
`Makefile` path and extracts a `clean:` recipe, so what it actually offers is *"benefits any project
**that builds with make and has a clean target**"*. That is a conditional. The **principle** is
universal and worth having; **that implementation is not portable**, and only Q1 catches the
difference. Compare a check that presumes **only what this template itself ships** (task-trees, a
decisions index, a README, a resume pointer) — that one is objectively applicable, because every
consumer has those by construction.

⇒ **The portability seam to look for:** does the check presume anything beyond what bedrock ships?
If yes, either give it a project-declared seam (a config/list the project supplies) or leave it
upstream. Do not hardcode one project's answer and call it neutral.

⚠️ Honest bound on Q2: 0 is *necessary, not sufficient* — the count treats strings and heredocs as
logic. Use it to rank and to catch self-deception, never as the verdict.

⛔ **A doctrine that fails Q1 stays upstream.** Porting it anyway converts a portable standard into
a fork of one project, which is the failure this repo exists to prevent.

## Transfer runs BOTH WAYS

The flow above is the common case, not the only one — and until 2026-07-30 the process had **no
step for the reverse**, so nothing would have surfaced a spine improvement the reference project
lacked.

⛔ **It happened, and it was found by accident.** bedrock's layer-C check already reconciled every
decision record against `INDEX.md`; upstream asserted only that the index had *more than zero
rows*, and passed at **135 records / 133 rows** — two records invisible to their own index with
the doctrine green. The stronger implementation was **downstream**, and the weaker one would have
kept passing indefinitely.

⭐ **This is structural, not luck: generalizing a check is a REWRITE, not a copy.** Stripping
domain assumptions regularly produces a cleaner, stronger check — so the distillation step can
*improve* the thing. Expect it to recur. The same session produced a second instance: the ported
`WAIVER-ROUTING` check had a latent **fail-open** in its origin (`printf … | grep -q … || continue`
returns failure ON SUCCESS past the pipe buffer under `pipefail`, so the file is silently skipped);
it was **fixed on the way in** rather than inherited, and the fix is owed back upstream.

**So, when you port anything:**

1. Ask whether bedrock's existing version of the same invariant is *already stronger*. If it is,
   say so and push it back — do not silently overwrite it with the upstream one.
2. Ask whether the thing you are porting carries a known defect. Fix it here, and record that the
   fix is owed back.

⚠️ **A raw `diff` of the two copies is NOT the trigger — measured and rejected.** Of the 12 files
present in both repos, **11 differ, by 15–559 lines**, because the upstream copies deliberately
carry project-specific evidence while these are deliberately neutral. A check reporting hundreds
of intended differences teaches its authors to waive it. The right trigger compares **behaviour**:
where both repos implement the same invariant, run both against one fixture and compare verdicts.
That harness is **not built** — recorded as owed, not claimed.

## This repo's dual role (why its own memory files look "used")

bedrock is **both** a template *and* a real project (its project = "maintain the spine").
So this repo's own layer-A/B/C memory describes the maintenance work:

- `MEMORY.md` — bedrock's resume pointer (points here + to the maintenance tree).
- `docs/tasks/BEDROCK-MAINTENANCE.md` — the living maintenance task-tree (frontier + backlog of
  candidate enhancements for the next agent).
- `docs/tasks/REVIEW-2026-09.md` — the tree that closed the 2026-09-30 review (done).
- `docs/decisions/` — the contract (four decision records) and the provenance record.
- `docs/reviews/` — external reviews, kept so their item ids can be cited.
- `ROADMAP.md` — kept as the **consumer** placeholder (the canonical "replace me" file).

`scripts/bootstrap.sh` de-templates for a consumer: it removes every `maintainer`-class path
(this guide, both maintainer trees, the reviews, every decision record, the user guide and its
workflow — read from the manifest, so a new maintainer file needs no edit there) and resets the live docs.

## File inventory (the spine)

The authoritative inventory is `.bedrock/manifest` (the `MANIFEST` gate keeps it complete). In
words: agent entry `AGENTS.md` (canonical; harness adapters come from packs); memory
`MEMORY_ARCHITECTURE.md`, `MEMORY.md`; task-trees `docs/TASK_TREE.md`, `docs/TASK_TREE_README.md`,
`docs/tasks/` (+ `TEMPLATE.md`); decisions `docs/decisions/` (+ `INDEX.md`, `TEMPLATE.md`); commit
`COMMIT.md`; enforcement `DOCTRINE_ENFORCEMENT.md`, `scripts/lib/spine.sh`, `scripts/gate` →
`scripts/check_doctrines.sh` + `scripts/check_*.sh`, `scripts/check_doctrines.project.sh` (project
slot), `scripts/tests/spine_tests.sh`, `.githooks/`, `.github/workflows/doctrines.yml`, `.doctrine/`;
tools-first `TOOLBOX.md`; knowledge map `KNOWLEDGE_MAP.md` (derived), `knowledge-map/`; live docs
`CHANGELOG.md`, `DEV_NOTES.md`, `LIVE_STATUS.md`; posture `VISIBILITY.md`; settings
`docs/REPOSITORY_SETTINGS.md`; licence `LICENSE`, `NOTICE`; entry points `scripts/run`,
`scripts/evidence`, `scripts/handoff`, `scripts/bootstrap.sh`, `scripts/new_project.sh`,
`scripts/update_scaffold.sh`; versioning `DOCTRINE_VERSION`, `.bedrock/manifest`, `migrations/`;
packs `packs/`.

## Working on bedrock

Use bedrock's own discipline on bedrock: create/extend a `BEDROCK-MAINTENANCE` leaf before
changing spine files, run `scripts/gate` and `scripts/tests/spine_tests.sh`, commit via
`COMMIT.md`, end with `scripts/handoff`. The enforcer must stay green — bedrock has to practice
what it preaches, and since `7b6d898` every commit is judged by the same contract a child's is.
