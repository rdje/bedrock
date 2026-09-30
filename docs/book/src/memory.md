# Memory: where everything lives

The rule that makes a project survive a lost session is short: **information that exists only in
the conversation is not saved. Put it in its layer and commit it.** This chapter says which
layer, and what each file is for. The full design is in `MEMORY_ARCHITECTURE.md`.

## Layer A: `MEMORY.md`, the resume pointer

It answers one question, *what is next?*, and nothing else. Five fields:

| Field | Holds |
| --- | --- |
| `next_action` | one concrete sentence: the next thing to do |
| `active_work_unit` | the tree being worked, and its frontier leaf |
| `latest_commit` | the work-unit id of the last governed commit |
| `in_flight_uncommitted` | `none`, or what is unfinished and how to finish it |
| `blockers` | `none`, or what blocks and who owns it |

It is **overwritten**, never appended to. It is capped at 50 lines and 7,168 bytes (both caps,
because long lines defeat a line cap alone), and the caps are there to be far away: if the file
grows, something is being written into it that belongs in another layer. A lesson, a warning, a
measurement or a history of what was done does not describe what is next.

The `RESUME-POINTER` gate checks the pointer is *true* in every governed commit, and
`MEMORY-ARCH` checks its size.

## Layer B: task trees, the work memory

`docs/tasks/<TREE>.md`, one file per top-level task, indexed by the table at the end of
`docs/TASK_TREE.md`. A tree owns the breakdown into leaves, each leaf's status and evidence, the
decisions taken along the way, and the log of commits. `docs/tasks/TEMPLATE.md` is the form you
copy; `docs/TASK_TREE_README.md` is the short how-to.

Statuses move `proposed` → `pending` → `active` → `done`; a stalled leaf is `blocked`, with the
blocker named.

Four gates watch what is written in trees:

- `WAIVER-ROUTING`: if a leaf says a gate's evidence shapes do not fit its case, it must name a
  leaf that owns fixing the gate. A waiver is a bug report about the gate.
- `ROUTING-EVIDENCE`: if a leaf sends a finding to a different tree, it records what was measured
  to place it there.
- `GAP-CLAIM-CENSUS`: a sentence of the form "nothing checks X" is a claim about the whole
  repository; it must come with the search that backs it, in backticks, or an honest
  `census: not run (<why>)`.
- `TASK-ACCEPTANCE` and `TASK-TREE-OWNERSHIP`: the contract of the previous chapter.

## Layer C: decisions and facts

`docs/decisions/`, one record per file, listed in `docs/decisions/INDEX.md` (the `MEMORY-ARCH`
gate refuses a record that is not indexed). Write a record when you establish something that
must outlive the current work and is not obvious from the code: a constraint, a convention, a
trade-off, "we tried X and it failed because Y", a preference of the project's owner. Copy
`docs/decisions/TEMPLATE.md`. When a decision changes, add a new record and mark the old one
superseded; do not rewrite history.

### Lessons and knowledge

`DEV_NOTES.md` holds detailed technical notes per piece of work. When you add a *dated lesson*
there (a heading with a date), the `LESSON-PROMOTION` gate asks for a decision, because a lesson
that is written down but cannot be found again is lost:

- **promote** it: add `docs/knowledge/<slug>.md` that begins with a line
  `answers: <the question it answers>`, or add an `answers:` line to a decision record; or
- **decline**: write `promotion: declined (<reason>)` in the owning leaf, once per lesson.

Declining is normal. Promote what is durable, general and question-shaped.

## Layer D: the audit trail

`git log` is the history; `CHANGELOG.md` is its human-readable summary. Because every commit
subject starts with a work-unit id and names its leaf, `git log --grep 'ORBIT.2'` reconstructs a
unit's whole history. No document should retell git's history in prose, and none should carry a
"Last updated:" line (the `LIVE-DOC-CURRENCY` gate refuses it): git already knows when each line
changed, and a hand-kept date is wrong the day after it is typed.

## The derived map

`KNOWLEDGE_MAP.md` is generated, never edited. It lists the project's key subsystems (the one
part you curate, in `knowledge-map/subsystems.md`), every task tree with its status, every
decision record, and every knowledge file with its question. The pre-commit hook regenerates it
from what is staged, and the `KNOWLEDGE-MAP` gate refuses a map that does not match its sources.

## The other live documents

| File | For |
| --- | --- |
| `README.md` | the landing page; kept short by the `README-STABILITY` gate (`README_POLICY.md` says what belongs there) |
| `ROADMAP.md` | the direction; each lane becomes one or more trees |
| `LIVE_STATUS.md` | a table of areas and their state: Done, Mostly Done, In Progress, Not Started |
| `CHANGELOG.md` | what each version changed |
| `DEV_NOTES.md` | technical notes and dated lessons |
| `TOOLBOX.md` | the tools-first rule, and your project's own diagnostic tools |
| `VISIBILITY.md` | the declared posture, public or private, and what it implies |

Markdown files must not contain paths that exist only on one machine, such as a home directory;
the `DOCPATH` gate refuses them. Tables must be well-formed: the `TABLE-ARITY-RATCHET` gate
refuses a change that adds a row whose cell count differs from its header, because such a row
renders with cells silently dropped.
