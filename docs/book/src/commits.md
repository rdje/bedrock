# Commits, leaves and evidence

This chapter is the ownership contract in practice: what makes a commit acceptable, rule by
rule, with the refusal you get when a rule is broken.

## Governed or documentation?

Every changed path is one or the other.

**Documentation** (no leaf needed): files ending in `.md`, `.markdown`, `.txt`, `.rst`, `.adoc`;
`LICENSE`, `NOTICE`, `COPYING`, `AUTHORS` and `CHANGELOG` files; `.gitignore`; images (`.png`,
`.jpg`, `.gif`, `.svg`, `.ico`, `.webp`); and any path your project declares in
`.doctrine/docs_paths.txt`.

**Governed** (a leaf must own the change): everything else. Source files in any language, build
files, configuration, generated artefacts. Deleting or renaming a governed file counts.

**Always governed, whatever you declare**: the spine itself. The hooks, the workflows,
`.doctrine/`, `.bedrock/`, the check scripts, `scripts/lib/`, the entry-point scripts and
`DOCTRINE_VERSION`. A project cannot exempt the gate that judges it.

## The subject line

```text
ORBIT-APP-0005 (leaf ORBIT.2): parse the two-line element format
└─ work-unit id ┘ └── the leaf ──┘
```

- It **starts with a work-unit id**: uppercase words joined by `-`, ending in a number of at
  least four digits. `ORBIT-APP-0005` and `SEED-0001` are valid; `hello` and `fix bug` are not.
  The first word is normally your project's prefix from `.bedrock/project`.
- A governed change **names exactly one leaf**: `(leaf <TREE>.<n>)`, where `<TREE>` is the file
  name under `docs/tasks/` without `.md`.
- A merge commit's subject is git's own and is exempt.

## What the named leaf must show, in the same commit

1. The tree file `docs/tasks/<TREE>.md` is part of the commit.
2. It contains a section starting with ``- ID: `<TREE>.<n>` ``.
3. That leaf was **not already `done`** before this commit. A finished leaf owns nothing new.
4. The leaf's section **gains lines** in this commit.
5. It has exactly one box for each of the three labels, **ticked**, with the label at the very
   start of the bold text:

```markdown
  - [x] **ROOT CAUSE (WHY + WHERE)** — …
  - [x] **ADDRESSED (verified)** — …
  - [x] **NO REGRESSION** — …
```

6. Each of the three boxes **gains at least one line in this commit**. Evidence must be new.
7. Each box holds **tool output inside backticks** (or a fenced block): a result such as
   `rc=0`, `exit 1`, `12 passed / 0 failed`, a line your project declared in
   `.doctrine/evidence_tokens.txt`, or the `evidence:` line that `scripts/evidence` prints.

Other boxes (`FIX`, `LOCKSTEP`, anything you add) are welcome and not judged.

### Why so strict about evidence?

Because each loosening was a real hole, measured:

- When any old ticked checklist counted, yesterday's evidence answered for today's change.
- When a box was found by keyword, a line saying "**FIX** — addressed by rewriting" stood in for
  an unticked **ADDRESSED** box.
- When prose counted, "should exit 0 now" and a bare version number passed as tool output.

The honest limit remains: the gate proves you *cited* something a reviewer can re-run, in this
commit. It cannot prove the output is true.

## `scripts/evidence`

One shape of evidence for any language and any tool:

```text
$ scripts/evidence -- prove -lr t
evidence: rc=0 cmd="prove -lr t" out-sha256=3f2a9c1d4b7e6a55 lines=9
  | All tests successful.
  | Files=3, Tests=42
```

Paste the first line into a box, inside backticks. It exits with the command's own status, so
you can use it in place of the command. `-n <lines>` sets how much of the output's tail is shown.

## The resume pointer travels with every governed commit

`MEMORY.md` must be true for the commit being made:

- `latest_commit:` names this commit's work-unit id;
- `active_work_unit:` names a tree that exists, and the last leaf it names, the frontier, exists
  and is not `done`;
- `next_action:` says something.

A documentation-only commit may leave the pointer as it is.

## Trailers

**No agent attribution.** A commit message ends with its own last line. A trailer that credits an
AI agent (`Co-Authored-By`, `Co-Developed-By`, `Assisted-By`, `Generated-By` with an agent's
address or product name) is refused, and so are the "Generated with …" lines some harnesses add.
Who counts as an agent is data, in `.doctrine/agent_identities`. A human co-author is never
affected, whatever their name.

**The one bypass.** `Spine-Exception: <reason>` on its own line at the end of the message lets a
governed change land without a leaf. It is stored in history and CI lists and counts every one.
The pointer rule still applies.

## What runs when

| Moment | What runs | What it can judge |
| --- | --- | --- |
| `git commit`, before the message exists | `.githooks/pre-commit`: regenerates `KNOWLEDGE_MAP.md`, then every gate on the staged files | everything except the four message-time gates, which report `⏸ not evaluated here` |
| `git commit`, once the message exists | `.githooks/commit-msg`: every gate again, with the message | the binding: subject, leaf, evidence, pointer |
| after a push | CI: every gate, for each commit pushed, against its parent, with its message | the same, where `--no-verify` cannot reach |

You can run the same judgement by hand at any time:

```bash
scripts/gate                          # the staged files against the last commit
scripts/gate --message msg.txt        # the same, with a message (a full dry run)
scripts/gate --commit HEAD            # one commit, as CI judges it
```

## A refused commit, read line by line

```text
=== doctrine enforcement (18 checks; index vs 6a0116b) ===
  ❌ TASK-TREE-OWNERSHIP    every code change — added, modified, deleted or renamed — is owned by a task-tree leaf
       TASK-TREE-OWNERSHIP: governed paths change but the subject names no leaf (exactly one '(leaf <TREE>.<n>)' is required):
           crates/app/src/main.rs
         Every path except documentation is governed (…).
         Name the owning leaf in the subject, e.g. 'PROJ-AREA-0007 (leaf FEATURE-X.2): …', or record a
         deliberate exception as a trailer:  Spine-Exception: <why no leaf applies>
  ❌ TASK-ACCEPTANCE        a code change is owned by a leaf whose ticked checklist carries tool output IN each box
=== 2 doctrine breach(es), 0 refusal(s) — commit blocked ===
```

The first line says what is being judged: the staged index against commit `6a0116b`. Each `❌`
names a gate and, indented, its reason and the way out. Nothing was committed; fix and commit
again. The message file is still there.
