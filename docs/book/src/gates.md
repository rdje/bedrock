# The gates, one by one

A gate is a script under `scripts/` that judges a change and exits 0 (holds), 1 (breach) or 2
(cannot evaluate). The **driver**, `scripts/check_doctrines.sh`, runs them all and reports each
verdict. `scripts/gate` is its friendly name.

## Reading the driver's output

```text
=== doctrine enforcement (18 checks; index vs 6a0116b) ===
  ✅ MEMORY-ARCH            durable 4-layer memory architecture invariants, and every spine document present
  ⏸  TASK-TREE-OWNERSHIP    not evaluated here: binding needs the commit message; the commit-msg hook and CI supply it
  ❌ TASK-ACCEPTANCE        a code change is owned by a leaf whose ticked checklist carries tool output IN each box
       TASK-ACCEPTANCE: leaf ORBIT.2 — the 'ADDRESSED' box carries no line added in this change: …
  ⚠️  TASK-TREE-OWNERSHIP    EXCEPTION — 1 governed path(s) land without a leaf: Spine-Exception: vendored data
  ⛔ REFUSED  TABLE-ARITY-RATCHET   cannot evaluate (exit 2) — an error is not a pass
=== 1 doctrine breach(es), 1 refusal(s) — commit blocked ===
```

| Symbol | Meaning |
| --- | --- |
| `✅` | the doctrine holds for this change |
| `❌` | a breach; the indented lines say what and how to fix it |
| `⏸` | not evaluated in this context (a message-time gate running in the pre-commit hook, or a gate that only applies to the template) |
| `⚠️ EXCEPTION` | a `Spine-Exception:` trailer bypassed the binding; CI counts these |
| `⛔ REFUSED` | the gate could not evaluate; the run fails, because an error is never a pass |

The first line names what is judged: `index vs <commit>` in the hooks, `<commit> vs <parent>`
in CI. The last line is the verdict.

## How to run it yourself

```bash
scripts/gate                       # the staged files against the last commit (what pre-commit does)
scripts/gate --message msg.txt     # with a message: the full judgement (what commit-msg does)
scripts/gate --commit HEAD         # one commit against its parent, with its real message (what CI does)
scripts/gate --range a..b          # every commit in the range, oldest first (what CI does on a push)
```

Each gate can also be run alone (`bash scripts/check_<name>.sh`), and several carry a
`--self-test` that proves their own arms.

## The gates

### MEMORY-ARCH

`MEMORY.md` exists and stays under both caps (50 lines, 7,168 bytes, set in `.doctrine/config`);
every decision record is listed in `docs/decisions/INDEX.md`; `docs/TASK_TREE.md` and
`docs/tasks/` exist; every spine document is present (`AGENTS.md`, `COMMIT.md`, the doctrine
files, `LICENSE`, `NOTICE`, the hooks, the workflow, the templates); `AGENTS.md` points at
`MEMORY_ARCHITECTURE.md` and `README.md`; and any harness adapter file present (the list is in
`.doctrine/harness_adapters`) points at `AGENTS.md`.

*Fix:* demote content out of `MEMORY.md`; add the missing index row; restore the missing file.

### DOCPATH

Changed Markdown files carry no path that exists only on one machine (a home directory, a mounted volume).

*Fix:* use a repository-relative path.

### TASK-TREE-OWNERSHIP

A governed change is bound to the one leaf the subject names: the leaf exists, its tree file is
in the commit, its section gains lines, and it was not already `done`. Message-time; `⏸` in the
pre-commit hook. `Spine-Exception:` is the only bypass.

*Fix:* name the leaf in the subject; put the tree file in the commit; open a child leaf if the
named one is done.

### README-STABILITY

`README.md` stays a landing page: under its line and byte caps, no date-stamped lines (release
history belongs in `CHANGELOG.md`), and it keeps linking `README_POLICY.md`. Refuses to evaluate
when the README or the policy is missing.

*Fix:* move the detail to its canonical home; the hint names one per kind of content.

### WAIVER-ROUTING

A tree that *adds* a line saying a gate's evidence shapes do not apply to it must name, in the
same paragraph, an owner that exists: a leaf of an existing tree, `.n` of this tree, or a
work-unit id some tree cites. Only added lines are judged.

*Fix:* open the leaf that owns fixing the gate and name it. Do not delete the waiver: it is the
most useful bug report a gate can get.

### TASK-ACCEPTANCE

The bound leaf's three boxes are ticked, labels first, one per label; each gains a line in this
commit; each holds tool output inside backticks. Message-time. Details in
[Commits, leaves and evidence](commits.md).

*Fix:* write the evidence you measured into the box, in backticks, with its `rc=`.

### LIVE-DOC-CURRENCY

No tracked Markdown file has a line beginning `Last updated:`, `Last modified:` or `Updated on:`
about itself. Git carries currency; a hand-kept date is false the day after.

*Fix:* delete the line. `git log -1 --format=%ad -- <file>` is the date.

### LESSON-PROMOTION

A new dated lesson heading in `DEV_NOTES.md` is either promoted (a `docs/knowledge/` file with
an `answers:` line, or a decision record gaining `answers:`) or explicitly declined in the
owning leaf with `promotion: declined (<reason>)`, one decline per lesson.

*Fix:* promote it, or decline it with a real reason.

### ROUTING-EVIDENCE

A tree that adds a line routing a finding *out to another tree* carries a `ROUTING EVIDENCE`
section: does the finding reproduce outside the family it is sent to, what was measured, what
would make the routing wrong.

*Fix:* add the section; "not checked outside this family" is an honest, accepted answer.

### GAP-CLAIM-CENSUS

A tree that adds a "nothing checks X" sentence must, in the same heading section, cite the
search that backs it inside backticks (`git grep -c …`, `grep -r …`, `find . …`, a
`--self-test`), or say `census: not run (<why>)`.

*Fix:* paste the census you ran, or disclose that you did not.

### TABLE-ARITY-RATCHET

A changed Markdown file may not raise the number of table rows whose cell count disagrees with
their header. It follows GFM's own rules: an unescaped `|` splits a cell even inside a code span;
a table ends at a blank line, so a prose line right after a table becomes a one-cell row.

*Fix:* escape the pipe as `\|`; put a blank line after the table.

### COMMIT-MESSAGE

The subject starts with a work-unit id; no attribution trailer names an agent, and no
harness-added body line does either (`.doctrine/agent_identities` says who counts). Merge
subjects are exempt. Message-time; also judged in CI, so `--no-verify` does not help.

*Fix:* start the subject with `PREFIX-AREA-NNNN`; remove the trailer.

### MANIFEST

`.bedrock/manifest` exists, every `spine`-class path it names exists in the tree (a
half-installed spine is a breach), and, in bedrock itself, every tracked path is classified.

*Fix:* in a project, run the updater to restore the missing spine file; in bedrock, classify
the new path.

### NEUTRALITY

In bedrock itself only: no spine logic file names a language, a build or docs tool, or a
harness. Terms are in `.doctrine/neutrality_terms`; reviewed exceptions, each with a reason, in
`.doctrine/neutrality_allow`. In a project it reports `OK — not the template itself`.

### BOOK-COVERAGE

In bedrock itself only: this guide names every doctrine, entry-point script, `.doctrine/` seam,
pack and migration, so none can land undocumented.

### RESUME-POINTER

`MEMORY.md` is true for this commit: `next_action` is set; `active_work_unit` names an existing
tree and an open frontier leaf; for a governed commit, `latest_commit` names this commit's
work-unit id. Message-time.

*Fix:* overwrite the current-state block as part of the commit.

### KNOWLEDGE-MAP (when the subsystem exists)

`KNOWLEDGE_MAP.md` equals a fresh render of its sources. The pre-commit hook regenerates it, so
this passes locally and catches out-of-band edits in CI.

*Fix:* `knowledge-map/scripts/gen_knowledge_map.sh > KNOWLEDGE_MAP.md`, then stage it.

### PROJECT-SPECIFIC (your own)

`scripts/check_doctrines.project.sh`, the slot for your project's doctrines. It ships as a
passing no-op. See [Adding your own doctrine](extending.md).

## The self-tests

Five gates prove their own arms, and CI runs them: `check_gap_claims.sh --self-test`,
`check_lesson_promotion.sh --self-test`, `check_live_doc_currency.sh --self-test`,
`check_routing_evidence.sh --self-test`, `check_table_arity.sh --self-test`. Two *probe drivers*
under `docs/tasks/artifacts/` build throwaway repositories to prove the acceptance and waiver
gates refuse what they must and accept what they must.
