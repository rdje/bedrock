# Introduction

**bedrock** is a starting point for a software project. It is not a framework and not a
library: it is a *discipline spine*, a small set of files, scripts and git hooks that make a
project keep its own promises.

Three promises, specifically:

1. **Nothing important is lost.** What the project is doing, what was decided and why, and what
   comes next are written in the repository, in a fixed place, in a form any person or any AI
   agent can read. A session can end, a machine can die, you can switch from one AI harness to
   another, and the next session resumes from the repository alone.
2. **Every change is owned and evidenced.** A change to anything but documentation lands only in
   a commit that names the unit of work that owns it, and that unit carries the output of the
   tools that were run. This is checked by git hooks on your machine and again by CI, per commit.
3. **The discipline is mechanical, not remembered.** Rules live in scripts that refuse, not in a
   document someone may skip. When a check cannot evaluate, it refuses instead of passing.

bedrock is **neutral on three axes**. It does not care what your project is about, which
programming language it uses, or which AI harness (or none) drives it. A language, a
documentation tool or a harness file is an opt-in *pack*.

## Who this guide is for

You, the person who creates a project from bedrock and works in it, alone or with AI agents. It
explains what each piece is for, walks through the two scripts you will meet at the start and at
every upgrade (`scripts/bootstrap.sh` and `scripts/update_scaffold.sh`) step by step, and tells
you what to do when a gate refuses a commit.

The files at the root of a project (`AGENTS.md`, `COMMIT.md`, `MEMORY_ARCHITECTURE.md`,
`DOCTRINE_ENFORCEMENT.md`) are the *rules*, written for agents and meant to be precise. This
guide is the *explanation*. Where they disagree, the root files and the scripts win, and that
disagreement is a defect worth reporting.

## How to read it

- New to bedrock: read [The spine in six ideas](concepts.md), then
  [Creating a project](getting-started.md) and [The daily loop](daily-work.md).
- A commit was refused: go to [Troubleshooting](troubleshooting.md), then the gate's entry in
  [The gates, one by one](gates.md).
- Upgrading an existing project: [Upgrading the spine, step by step](updating.md).
- Working on bedrock itself: [Maintaining and extending bedrock](maintaining.md).

The transcripts in this guide are real output, captured from bedrock 1.0.3 and lightly trimmed.
