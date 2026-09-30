# Ending a session, switching harness

A bedrock project is built so that the *session* is disposable. You can `/exit`, `/clear`, lose
power, or open the project tomorrow in a different AI harness with a different model, and the
work continues. Two things make that a property and not a hope: one command at the end of a
session, and one gate on every commit.

## The last command of every session: `scripts/handoff`

```text
$ scripts/handoff
handoff: OK — resumable from the repository alone: HEAD 6a0116b "ORBIT-BOOTSTRAP-0001 (leaf BOOTSTRAP.1): bootstrapped from bedrock"; pointer → BOOTSTRAP
```

It prints `handoff: OK` only when all of these hold:

1. **No background job belongs to the project.** A process that outlives its session keeps
   rewriting tracked files under the next one, and its log is gone. The census is not a list of
   known program names: it asks the system which processes hold a file open inside the
   repository, or name the repository on their command line. Processes that only inherited the
   directory as their working directory are advisory. The session processes of your harness are
   ignored through `.doctrine/handoff_ignore`.
2. **The working tree is clean.** Uncommitted content survives nothing: not a crash, not a
   cleared context, not a harness switch. So this is refused, not warned about.
3. **The resume pointer is true.** `MEMORY.md` names the latest governed commit, an existing
   tree, and a frontier leaf that exists and is open.
4. **Advisory: nothing is only on this machine.** Commits not yet on the remote are counted. An
   unpushed commit does not survive the loss of the machine.

When it refuses, it says what would be lost:

```text
$ scripts/handoff
handoff: NOT READY — the working tree is not clean; uncommitted content survives nothing (not a crash, not a /clear, not a harness switch):
    M  crates/app/src/main.rs
handoff:   commit it through COMMIT.md (or stash it and say so in MEMORY.md's in_flight_uncommitted line — then it is a choice, not a loss)
handoff: NOT READY (see above)
```

If a job is still running, stop it **and its children**; killing a parent does not stop what it
started. `scripts/handoff --all` lists the advisory processes too.

## Resuming

In a new session, in any harness:

1. The harness reads `AGENTS.md` (directly, or through its one-line adapter file).
2. `AGENTS.md` sends the reader to `MEMORY.md`.
3. `MEMORY.md` names the tree and the frontier leaf.
4. The leaf says what is done and what is next.

That is all. A new clone on a new machine needs one more command, once:
`scripts/bootstrap.sh --contributor`, to install the hooks.

## Switching harness or model

The harness is transparent to the project:

- The complete instructions are in **`AGENTS.md`**. Codex, Pi, Kimi Code and Copilot's agent read
  it natively. Claude Code, Qwen Code and Gemini CLI read a file of their own (`CLAUDE.md`,
  `QWEN.md`, `GEMINI.md`); a harness pack provides that file, and it contains one line that
  imports `AGENTS.md`. The `MEMORY-ARCH` gate checks that any such file present points there.
- Nothing the project needs lives in a harness's private memory, settings or chat history. If an
  agent learned something that matters, it belongs in a layer, committed.
- The gates live in git hooks and CI. They fire identically for any agent and for a person.

So to switch: make `scripts/handoff` print `OK` in the old harness, open the project in the new
one. If the new harness auto-reads a file of its own that the project lacks, add its pack:

```bash
scripts/update_scaffold.sh <bedrock> --add-pack harness/qwen
```

## After a crash

Nothing to repair in the normal case: the last commit is intact, and `MEMORY.md` at that commit
is true because the gate required it. What a crash can lose is only what was not committed,
which is the reason to commit small and often, and to run `scripts/handoff` before stepping away.
If you stashed unfinished work on purpose, the `in_flight_uncommitted` line of `MEMORY.md` is
where you said so.
