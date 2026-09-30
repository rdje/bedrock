# Creating a project

## What you need

- `git` and `bash` (version 3.2 or later; the one macOS ships is enough), plus the standard
  `awk`, `sed` and `grep`. Nothing else is required by the spine.
- Optional: the GitHub CLI `gh`, logged in, if you want the repository created on GitHub for you.
- Optional: the toolchain of the language pack you choose (for Rust, `cargo`).

## The stress-free way: `scripts/new_project.sh`

Clone bedrock once, and let it ask you the questions:

```bash
git clone https://github.com/rdje/bedrock
cd bedrock
scripts/new_project.sh
```

You are asked seven questions about the project and then where it should live. Every question
lists its choices; the value in brackets is the default, and pressing Enter accepts it. An
invalid answer is asked again. Nothing is written until you confirm the summary.

```text
bedrock — set up a new project. Enter accepts the value in brackets.

1/7  Project name [my-project]: orbit
2/7  Display title [orbit]: Orbit Tracker
3/7  Work-unit prefix (commit subjects start with it) [ORBIT]:
4/7  Visibility posture (VISIBILITY.md; nothing confidential goes into a public repository)
  1) public     the repository is public; nothing confidential ever goes in  (default)
  2) private    the repository is private; record why in docs/decisions/
  choice [public]:
5/7  Language pack (the spine itself is language-neutral)
  1) none       no language: add your own build and its verbs to .doctrine/commands  (default)
  2) rust       Rust — a cargo workspace with a starter binary crate, rustfmt, clippy (deny warnings) and tests
  choice [none]: 2
6/7  Docs pack (the public documentation surface)
  1) none       no docs tool: declare a docs verb later if you want one  (default)
  2) mdbook     mdBook — a book skeleton under docs/book, built with `scripts/run docs`
  choice [none]:
7/7  Harness packs (AGENTS.md is canonical and every harness reads it; …)
  0) none
  1) claude     Claude Code — CLAUDE.md, a one-line adapter importing AGENTS.md (default)
  2) codex      Codex CLI — reads AGENTS.md natively; no adapter file, only its hand-off exclusions
  3) pi         Pi coding agent — reads AGENTS.md natively; no adapter file, only its hand-off exclusions
  4) kimi       Kimi Code CLI — reads AGENTS.md natively; no adapter file, only its hand-off exclusions
  5) qwen       Qwen Code — QWEN.md, a one-line adapter importing AGENTS.md
  6) gemini     Gemini CLI — GEMINI.md, a one-line adapter importing AGENTS.md
  choices, comma-separated [claude]: 1,2

Summary:
  name        orbit
  title       Orbit Tracker
  prefix      ORBIT   (first commit: ORBIT-BOOTSTRAP-0001)
  visibility  public
  language    rust
  docs        none
  harness     claude,codex
```

Then `new_project.sh` asks where the repository should live:

- **github**: it runs `gh repo create <owner>/<name> --template …` for you, with the visibility
  you chose, and clones the result. This is offered when `gh` is installed and logged in.
- **local**: it exports bedrock into a new directory and runs `git init`. You can add a remote
  later.

After you confirm, it does the rest without further questions: it runs the
[bootstrap](bootstrap.md) in the new repository with your answers, makes the first commit
through the hooks, and, on the GitHub path, offers to push. It ends by telling you where the
project is.

Everything can also be given as flags, which is how scripts and CI call it:

```bash
scripts/new_project.sh --name orbit --title "Orbit Tracker" --dest ../orbit \
  --local --lang rust --harness claude,codex --yes
```

## The other way: GitHub's "Use this template" button

If you created the repository from the button on GitHub, clone it, enter it, and run the
bootstrap yourself. On a terminal it asks the same seven questions:

```bash
git clone https://github.com/<you>/<project>
cd <project>
./scripts/bootstrap.sh
```

Then make the commit it prints. The next chapter explains exactly what it does.

## What you have afterwards

```text
AGENTS.md            the complete instructions for any agent or person
MEMORY.md            the resume pointer: what is next
ROADMAP.md           the one file you replace with your own roadmap
README.md            your landing page (kept short by a gate)
COMMIT.md  DOCTRINE_ENFORCEMENT.md  MEMORY_ARCHITECTURE.md  TOOLBOX.md  VISIBILITY.md
CHANGELOG.md  DEV_NOTES.md  LIVE_STATUS.md        the live documents, reset for your project
docs/tasks/          task trees; BOOTSTRAP.md records this setup
docs/decisions/      decision records and their index
scripts/             gate, run, evidence, handoff, the checks, the updater
.githooks/           pre-commit and commit-msg
.github/workflows/   doctrines.yml (and the pack's workflow, if any)
.doctrine/           your project's declared data
.bedrock/            project (your identity) and manifest (what the spine owns)
LICENSE  NOTICE      the spine's licence, and what it does not cover
```

With the Rust pack you also get `Cargo.toml`, `crates/`, `rust-toolchain.toml`, a `Makefile`
and `.github/workflows/rust.yml`; with the Claude pack, `CLAUDE.md`.

## Your first ten minutes

1. Read `VISIBILITY.md`. It states whether the repository is public or private, and what that
   means for confidential material.
2. Replace `ROADMAP.md` with your real roadmap.
3. Create your first task tree: `cp docs/tasks/TEMPLATE.md docs/tasks/<TREE-ID>.md`, fill it in,
   add its row to the table at the end of `docs/TASK_TREE.md`, and point `MEMORY.md` at it.
4. Work its first leaf. [The daily loop](daily-work.md) shows how.
5. If the repository is on GitHub, set the two repository settings in
   [CI and repository settings](ci.md) so a red run blocks a merge.

Anyone who clones the project later runs one command, once per clone, to install the hooks:

```bash
scripts/bootstrap.sh --contributor
```
