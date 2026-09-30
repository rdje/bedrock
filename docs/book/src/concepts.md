# The spine in six ideas

## 1. Memory has four layers, and each has one job

A project's memory is split by *lifecycle*, because mixing things that change at different
speeds is what turns a notes file into an unreadable blob.

| Layer | What it holds | Where | How it changes |
| --- | --- | --- | --- |
| A, the resume pointer | what is next, right now | `MEMORY.md` | overwritten, never appended; small by rule |
| B, work memory | one unit of work: goal, leaves, evidence, commits | `docs/tasks/<TREE>.md` | grows while the work is open |
| C, decisions and facts | what was decided and why; constraints; lessons | `docs/decisions/` | one record per file, superseded, never rewritten |
| D, the audit trail | what changed and when | `git log`, `CHANGELOG.md` | append-only |

A new session reads layer A, opens the one tree it points to, and pulls only the decisions that
matter for the next step. See [Memory](memory.md).

## 2. Work is a tree of leaves

A **task tree** is one Markdown file under `docs/tasks/` that breaks a goal into **leaves**. A
leaf is the smallest piece you can finish, verify and commit. It has an ID such as `FEATURE.2`,
a status, and, when it lands a change, an **acceptance checklist** with three boxes that matter:
**ROOT CAUSE**, **ADDRESSED**, **NO REGRESSION**.

## 3. A change is owned by exactly one leaf, in the same commit

Every path except documentation is **governed**. A governed change lands only in a commit whose
subject names one leaf, `PROJ-AREA-0007 (leaf FEATURE.2): …`, and that leaf's section must gain,
*in that same commit*, its evidence: the three boxes ticked, each with tool output inside
backticks. Evidence written yesterday does not answer for a change made today. This is the
**ownership contract**; see [Commits, leaves and evidence](commits.md).

## 4. Gates refuse; they do not warn

A **gate** (the project calls them *doctrines*) is a script that judges a change and exits with
one of three verdicts:

| Exit | Meaning | What you see |
| --- | --- | --- |
| 0 | the doctrine holds | `✅` |
| 1 | a breach | `❌` and the reason |
| 2 | it could not evaluate (git failed, a pattern is invalid) | `⛔ REFUSED`; the run fails |

The third one is the important design choice: an error is never reported as a pass. The gates
run in the git hooks on your machine and in CI, once per commit. See
[The gates, one by one](gates.md).

## 5. The spine is neutral; packs are not

Nothing in the spine's logic names a programming language, a build tool or an AI harness. What
is specific comes from a **pack** you choose at setup: a language pack (Rust today) brings a
starter, its commands and what its tools print; a docs pack brings a book skeleton; a harness
pack brings the one file that harness auto-reads. Your project declares its own commands in
`.doctrine/commands` and runs them with `scripts/run <verb>`. See [Packs](packs.md).

## 6. A session can end at any moment

`AGENTS.md` is the single, complete instruction file every harness reads. `MEMORY.md` must be
*true* in every commit: it names that commit and points at an open leaf. `scripts/handoff` is
the last command of a session and refuses while anything would be lost. Together they mean you
can close the terminal, clear the context, or switch from one AI model or harness to another,
and the next session starts where this one stopped. See
[Ending a session, switching harness](handoff.md).

## The words used in this guide

| Word | Meaning |
| --- | --- |
| spine | the files bedrock ships and maintains: scripts, hooks, workflows, doctrine documents |
| child, project | a repository created from bedrock |
| tree, leaf | a task file under `docs/tasks/`, and one unit of work inside it |
| work-unit id | the token that starts a commit subject, such as `ORBIT-APP-0002` |
| governed | any path that is not documentation; it needs an owning leaf |
| gate, doctrine, check | a script that judges a change |
| seam | a file under `.doctrine/` where a project declares its own data |
| pack | an opt-in bundle: a language, a docs tool, or a harness |
| the contract | the rules in idea 3, recorded in bedrock's decision records |
