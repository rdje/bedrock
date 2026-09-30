# The bootstrap, step by step

`scripts/bootstrap.sh` turns a fresh copy of the bedrock template into *your* project. It runs
once per project. This chapter explains every mode, every question, every step, and what each
one writes, so nothing it does is a surprise.

## The four ways to call it

| Call | When | What it does |
| --- | --- | --- |
| `scripts/bootstrap.sh` on a terminal, in a fresh copy | the first time | asks the seven questions, then initialises the project |
| `scripts/bootstrap.sh <name> [flags] --yes` | scripts, CI | initialises without asking; flags and defaults answer |
| `scripts/bootstrap.sh --contributor` | every later clone | installs the git hooks and nothing else |
| `scripts/bootstrap.sh --maintainer` | in bedrock itself | installs the hooks and runs the enforcer; removes nothing |

Two safety rules sit on top:

- In a fresh copy, with no name and no terminal to ask on, it prints its usage and exits with
  status 2. It never silently does "just the hooks" in a copy that has not been initialised,
  because such a copy still believes it is the template.
- In a project that is already initialised, running it again with the **same** name only
  re-installs the hooks; with a **different** name it refuses. Renaming a project is a
  deliberate change with its own leaf, not a re-run.

## The flags

```text
scripts/bootstrap.sh [<project-name>]
    --title "<display title>"        default: the name
    --prefix <WORK-UNIT-PREFIX>      default: derived from the name (orbit → ORBIT, my_app → MY-APP)
    --visibility public|private      default: public
    --lang <pack>|none               default: none        (available: rust)
    --docs <pack>|none               default: none        (available: mdbook)
    --harness <a,b,…>|none           default when asked: claude; with --yes and no flag: none
    --yes                            take every default and flag; ask nothing
    --ask                            ask the questions even when input is piped
```

A flag answers its question in advance: the wizard skips what you already gave.

## What is validated before anything is written

| Input | Rule | Why |
| --- | --- | --- |
| name | a letter, then letters, digits, `-` or `_`; at most 64 characters | it becomes the identity, a starter crate's name with the Rust pack, and the source of the prefix |
| title | free text, at most 120 characters, no backquote, no backslash | it is written into files literally |
| prefix | uppercase words joined by `-`, such as `ORBIT` or `MY-APP` | every commit subject starts with it |
| visibility | `public` or `private` | it sets the posture line in `VISIBILITY.md` |
| packs | each must exist under `packs/` | an unknown pack is refused with the list of those available |

A name such as `a/b`, `x&y`, `my.proj` or `Stitch CAD` is refused with status 2 and the tree is
left exactly as it was.

The run also refuses, before writing, when:

- the directory is not the root of a git repository;
- `git`, `awk`, `sed` or `grep` is missing;
- the working tree is not clean. The bootstrap rewrites tracked files; uncommitted work would be
  silently swept into the first commit or lost. (A repository with no commit at all, as
  `git init` leaves it, is accepted: the whole tree becomes the first commit.)

## The steps, in order

Here is a real run, with the seven answers given as flags:

```text
$ ./scripts/bootstrap.sh orbit --title "Orbit Tracker" --lang rust --harness claude,codex --yes
→ initialising project 'orbit' (title: Orbit Tracker, work-unit prefix: ORBIT)
✓ de-templated: maintainer files, reviews and decision records removed; live docs reset
rust pack: crate renamed: `grep -c '^name = "app"' crates/app/Cargo.toml` → `1` before, `0` after (`rc=1`, …)
rust pack: `cargo metadata --no-deps` → valid workspace (`rc=0`).
✓ pack installed: lang/rust
✓ pack installed: harness/claude
✓ pack installed: harness/codex
✓ identity recorded in .bedrock/project (name=orbit, prefix=ORBIT, packs=rust,claude,codex)
✓ git hooks activated (core.hooksPath=.githooks)
✓ docs/tasks/BOOTSTRAP.md seeded
✓ KNOWLEDGE_MAP.md generated from the staged sources
→ running the doctrine enforcer over the staged index…
=== doctrine enforcement (18 checks; index vs 8e48875) ===
=== all doctrines green ===

bedrock is ready: project 'orbit' is initialised and its first commit is staged.
```

### Step 0: de-template

Everything that belongs to bedrock the template, and not to your project, is removed:

- every path the manifest (`.bedrock/manifest`) classes as `maintainer`: `MAINTAINING.md`,
  bedrock's own task trees, its decision records, its reviews, this guide and the workflow that
  publishes it;
- the "maintaining bedrock" note inside `AGENTS.md` and `ROADMAP.md`.

Then the documents that carry bedrock's own history are reset to a clean start for you:

| File | Becomes |
| --- | --- |
| `docs/decisions/INDEX.md` | an empty index |
| `docs/TASK_TREE.md` | the workflow text, then a table with one row: `BOOTSTRAP` |
| `CHANGELOG.md` | one entry: version 0.1.0, bootstrapped from bedrock |
| `DEV_NOTES.md` | the introduction and one bootstrap entry |
| `LIVE_STATUS.md` | three rows: the spine (Done), the roadmap (Not Started), your first milestone |

### Step 1: install the packs you chose

For each selected pack, in this order: language, docs, then each harness.

1. **Collision check.** If any file the pack would copy already exists, the run stops. A pack
   never overwrites.
2. **Copy** the pack's `files/` into the project root.
3. **Append its fragments**: ignore patterns to `.gitignore`, its verbs to `.doctrine/commands`,
   what its tools print to `.doctrine/evidence_tokens.txt`, documentation paths to
   `.doctrine/docs_paths.txt`, and a harness's session processes to `.doctrine/handoff_ignore`.
4. **Run its install hook**, if it has one. The Rust pack's hook renames the starter crate from
   `app` to your project's name and validates the workspace; the mdBook pack's hook writes your
   title into `docs/book/book.toml`. Each hook prints what it measured.

Then the whole `packs/` directory is removed. A pack you did not choose is never copied into
your project.

### Step 2: name and identity

- `ROADMAP.md`'s heading gets your title.
- `VISIBILITY.md`'s posture line becomes PRIVATE if you chose private.
- bedrock's own CI setting `ci_range_since` is emptied in `.doctrine/config`; it names one of
  bedrock's commits and means nothing in your history.
- `.bedrock/project` is written. It is your project's identity card:

```text
# .bedrock/project — this project's identity, written by scripts/bootstrap.sh (do not edit by hand).
name = orbit
title = Orbit Tracker
prefix = ORBIT
visibility = public
created = 2026-09-30
source = bedrock-scaffold 1.0.3
packs = rust,claude,codex
```

Every edit to an existing file in this step and the others is a *literal* replacement that must
change exactly one occurrence. If it would change none or several, the run stops rather than
guess. No `sed -i` is used, so the script behaves the same on macOS and Linux.

### Step 3: the git hooks

`git config core.hooksPath .githooks` is run, and the scripts are made executable. From now on
every `git commit` in this clone runs the gates.

### Step 4: the resume pointer

`MEMORY.md` is written for your project. It already names the commit you are about to make:

```text
- next_action: replace `ROADMAP.md`; create your first task-tree (…) and register it in `docs/TASK_TREE.md`.
- active_work_unit: `BOOTSTRAP` (its only leaf is done) — seed your first real tree from `ROADMAP.md`.
- latest_commit: `ORBIT-BOOTSTRAP-0001` — the bootstrap commit (make it with the command bootstrap printed).
- in_flight_uncommitted: none.
- blockers: none.
```

### Step 5: the leaf that owns this very step

The bootstrap changes governed files, so, by the project's own rules, a leaf must own it.
`docs/tasks/BOOTSTRAP.md` is created with one leaf, `BOOTSTRAP.1`, whose three boxes cite what
this run actually measured: the maintainer files present before and absent after, each pack
hook's output, the hooks path read back from git, and the verdict of the enforcer.

### Step 6: stage everything, then regenerate the Knowledge Map

`git add -A` stages the result. `KNOWLEDGE_MAP.md` is then generated from the *staged* sources
and staged too, so it lists exactly what the first commit will contain.

### Step 7: judge the staged first commit

The enforcer runs over the staged index with the first commit's real subject, as the commit
hook will. Its summary line is written into the leaf, so the evidence is the verdict of the
change it judges. If a gate refuses here, the bootstrap exits with status 1 and tells you; you
fix what it names and then commit.

### Step 8: the first commit, printed exactly

```text
Next:
  0) Commit the bootstrap itself (everything is staged; its leaf docs/tasks/BOOTSTRAP.md carries the evidence):
       printf '%s\n' 'ORBIT-BOOTSTRAP-0001 (leaf BOOTSTRAP.1): bootstrapped from bedrock' > git_message_brief.txt
       git commit -F git_message_brief.txt && : > git_message_brief.txt
```

Copy those two lines as they are. The hooks run the same gates again and the commit lands:

```text
=== doctrine enforcement (18 checks; index vs 8e48875) ===
=== all doctrines green ===
[main 6a0116b] ORBIT-BOOTSTRAP-0001 (leaf BOOTSTRAP.1): bootstrapped from bedrock
 61 files changed, 112 insertions(+), 4128 deletions(-)
```

`scripts/new_project.sh` makes this commit for you.

## If something goes wrong

| What you see | What it means | What to do |
| --- | --- | --- |
| `project name '…' is not valid` | the name broke the rule above | choose another; nothing was written |
| `the working tree is not clean` | uncommitted changes exist | commit or stash them, then re-run |
| `pack … would overwrite …` | a file the pack ships already exists | remove or rename your file, or skip the pack and add it later |
| `no such pack: …` | a misspelt pack name | the message lists the available ones |
| `already initialised as '…'` | you ran it again with another name | nothing to do; the project keeps its identity |
| `the enforcer reported a breach on the staged first commit` | a gate refused the staged result | read the gate's message, fix, then run the printed commit |

Because nothing is committed until you run the printed command, you can always inspect the
staged result with `git status` and `git diff --cached`, and return to the pristine copy with
`git reset --hard` followed by `git clean -fd`.
