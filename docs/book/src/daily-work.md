# The daily loop

A day in a bedrock project is the same five moves, whether you or an AI agent does them.

```text
resume  →  pick or create a leaf  →  do the work and measure it  →  commit  →  hand off
```

## 1. Resume

Open `MEMORY.md`. It answers one question: *what is next?*

```text
- next_action: ORBIT.2 — parse the two-line element format; see docs/tasks/ORBIT.md.
- active_work_unit: `ORBIT` → frontier leaf `ORBIT.2` (`active`).
- latest_commit: `ORBIT-APP-0004`.
- in_flight_uncommitted: none.
- blockers: none.
```

Then open the tree it names and go to that leaf. If the step touches something a past decision
settled, read that record under `docs/decisions/`. That is the whole read path; you never need
to reread the repository's history to know where you are.

An AI agent does exactly this, because `AGENTS.md` tells it to. That is why the harness does not
matter.

## 2. Pick or create a leaf

A leaf must exist **before** you change anything governed. If your roadmap lane has no tree yet:

```bash
cp docs/tasks/TEMPLATE.md docs/tasks/ORBIT.md
```

Fill in the goal, list the leaves, and add one row for the tree to the table at the end of
`docs/TASK_TREE.md`. A leaf looks like this while it is open:

```markdown
- ID: `ORBIT.2`
  Status: `active`
  Goal: parse the two-line element format into a struct
  Acceptance: the three sample files parse; a malformed checksum is rejected
```

Keep leaves small: one leaf is what you can finish, verify and commit in one go. When the work
uncovers more work, add a leaf (`ORBIT.3`) or a child leaf (`ORBIT.2.1`); do not stretch the
current one.

## 3. Do the work, and measure it

Diagnose with tools before you change code (`TOOLBOX.md`): find the cause and the place, then
fix. Run your project's checks through its declared verbs:

```bash
scripts/run check        # whatever your project declared: format, lint, tests
scripts/run test
```

When you want a result you can paste as evidence, run the command through `scripts/evidence`:

```text
$ scripts/evidence -- scripts/run test
evidence: rc=0 cmd="scripts/run test" out-sha256=5891b5b522d5df08 lines=14
  | test result: ok. 7 passed; 0 failed; 0 ignored
```

## 4. Commit

Before committing, the leaf gains its checklist, with what you measured:

```markdown
  ### Acceptance Checklist

  - [x] **ROOT CAUSE (WHY + WHERE)** — no parser existed: `scripts/run test` → `2 failed / 5 passed`
    (`rc=101`), both in `tle::tests`, at `crates/orbit/src/tle.rs:1`.
  - [x] **ADDRESSED (verified)** — `scripts/run test` → `7 passed / 0 failed` (`rc=0`).
  - [x] **NO REGRESSION** — `scripts/run check` → `7 passed / 0 failed` (`rc=0`); `scripts/gate` →
    `=== all doctrines green ===`.
```

Update `MEMORY.md` so `latest_commit` names the commit you are about to make and the pointer
shows what comes after it. Add a line to `CHANGELOG.md` if something user-visible changed. Then:

```bash
printf '%s\n' 'ORBIT-APP-0005 (leaf ORBIT.2): parse the two-line element format' > git_message_brief.txt
git add crates/ docs/tasks/ORBIT.md MEMORY.md CHANGELOG.md
git commit -F git_message_brief.txt && : > git_message_brief.txt
```

Two hooks run. The first judges the staged files; the second judges them again together with
your message, which is when the leaf named in the subject is bound to the change. If both are
green, the commit lands. If one refuses, nothing is committed and the message tells you why;
[Commits, leaves and evidence](commits.md) explains every rule, and
[Troubleshooting](troubleshooting.md) lists the fixes.

`COMMIT.md` in your project is the exact checklist for this step.

## 5. Hand off

Before you close the terminal, clear the context, or switch harness:

```text
$ scripts/handoff
handoff: OK — resumable from the repository alone: HEAD 6a0116b "ORBIT-APP-0005 (leaf ORBIT.2): …"; pointer → ORBIT frontier ORBIT.3
```

If it says `NOT READY`, it names what would be lost: an uncommitted file, a background job still
writing into the repository, or a pointer that no longer matches the last commit. Fix that, run
it again. See [Ending a session, switching harness](handoff.md).

## Variations you will meet

**One leaf, several commits.** An open leaf may own more than one commit. Each commit must add
its own evidence lines to the leaf's boxes and its row to the commit log.

**A follow-up to finished work.** A leaf marked `done` cannot own a new commit. Open a child
leaf, `ORBIT.2.1`, that says what the first fix missed, with its own evidence.

**A documentation-only change.** Markdown, text files, images and licence files are not
governed. A commit that touches only those needs a work-unit id in its subject and nothing else:
`ORBIT-DOC-0001: clarify the install steps`.

**A change no leaf can own.** Rare: vendored third-party sources, a mechanical import. Say so in
the message with a trailer, and CI will list and count it:

```text
ORBIT-VENDOR-0001: import the SGP4 reference tables

Spine-Exception: vendored third-party data, no leaf applies
```
