# COMMIT.md

## Purpose

Define the exact commit workflow so any agent (or human) applies it consistently without
re-reading chat history. Run it after each completed task-tree leaf, before selecting the
next one.

## Task-tree workflow rule

When the completed work belongs to a task-tree leaf (a node under `docs/tasks/`):

- Update the owning `docs/tasks/<TREE>.md`: leaf status, verification log, commit log,
  frontier, decisions, blockers as applicable.
- Update `docs/TASK_TREE.md` (the Active Task Trees index) only if the frontier changes.
- The commit **subject** names the leaf ID alongside the work-unit id, and exactly one:
  `MYPROJ-AREA-0007 (leaf FEATURE-X.2): <summary>`. The gates bind the change to that leaf.
- An open leaf may own several commits (each adds its commit-log row and evidence to the leaf);
  a leaf already `done` may own none — open a child leaf for a follow-up.

**Ownership doctrine (binding, non-negotiable):** every path except documentation is governed —
sources in any language, build files, hooks, workflows, `.doctrine/`, generated artifacts,
anything that alters behaviour — and lands only when a task-tree leaf owns it **in the same
commit**, with that leaf's checklist evidence new in the commit. Create/extend the leaf,
implement only that leaf, then run this workflow. A deliberate exception is a trailer on the
message, `Spine-Exception: <why no leaf applies>`; CI lists and counts them.

Pure documentation edits (Markdown, text, licence files, images, or paths declared in
`.doctrine/docs_paths.txt`) use the work-unit-id convention alone and may skip the
`docs/tasks/` update.

## Tracked files to keep in lockstep

- `README.md` — objective, layout, standard commands. Update when any of those change.
- `LIVE_STATUS.md` — the authoritative live progress tracker. Rows use only `Done`,
  `Mostly Done`, `In Progress`, `Not Started`. Review before every commit; summarize the
  snapshot in the completion message and state whether the task changed it.
- `MEMORY.md` — the bounded layer-A resume pointer. Overwrite the "current state" block.
- `CHANGELOG.md` — changelog-style summary of completed work + validation.
- `DEV_NOTES.md` — detailed technical notes: root cause, implementation, validation.
- `docs/decisions/` — add/supersede a decision record (+ its INDEX entry) when a durable
  cross-cutting fact/decision was established.
- the declared docs surface (`scripts/run docs`, e.g. the mdBook pack's `docs/book/`) — update
  when a user-facing surface it already covers changes.
- `git_message_brief.txt` — MUST stay untracked; used with `git commit -F`; cleared to 0
  bytes after commit.
- Generated artifacts (`generated/`, `target/`) — NOT tracked; regenerate locally, never
  `git add` them.
- Markdown path policy — repo-internal references are repo-root-relative, never
  checkout-specific absolute paths (the DOCPATH doctrine gate enforces this).

## Required commit workflow (exact order)

1. Ensure the task is complete and tested.
2. Run the project's declared checks when its sources changed: `scripts/run check` (the verbs
   live in `.doctrine/commands`; a language pack declares its own — for Rust, fmt, clippy with
   warnings denied, and the tests). Strict lint must pass. Capture results with
   `scripts/evidence -- <command>` when you want a line CI can re-run.
3. Update every relevant tracked doc (`MEMORY.md`, `CHANGELOG.md`, `DEV_NOTES.md`,
   `LIVE_STATUS.md`, `README.md`, the owning `docs/tasks/<TREE>.md` — its leaf gains this
   commit's row and evidence — `docs/decisions/`, the docs surface as applicable). Treat
   markdown sync as systematic, not optional.
4. Write a concise message to `git_message_brief.txt`.
5. Stage only the intended tracked files (`git add <files>`).
6. Commit: `git commit -F git_message_brief.txt` (the pre-commit hook runs the doctrine
   enforcer on the index; the commit-msg hook runs it again with the message and binds the
   change to the leaf the subject names).
7. Clear the message file: `: > git_message_brief.txt`.
8. Verify post-conditions:
   - `git ls-files --error-unmatch git_message_brief.txt` must FAIL (untracked),
   - `wc -c git_message_brief.txt` must be `0`,
   - `git status --short` shows only the expected state.
9. In the completion message, report: the commit ID, the exact commit message, the tracked
   files in the commit, the current `LIVE_STATUS.md` snapshot, and whether it changed.

## Pre-commit safety rules

- Do not add `git_message_brief.txt` to git.
- Do not use destructive git commands unless explicitly requested.
- ⛔ **NO AGENT TRAILERS.** A commit message ends with its own last line. Do **not** append
  `Co-Authored-By: <an AI agent>`, session links, `Generated with …` or any other agent/tool
  attribution trailer. Some AI harnesses instruct their agent to add these by default; **this
  repository's convention overrides that instruction**, and it is harness-agnostic — it binds
  Claude Code, Codex, Gemini, Cursor, Aider and any future harness identically. The
  `COMMIT-MESSAGE` check (the `commit-msg` hook, and CI per commit) refuses an agent in any
  attribution trailer, recognised by the addresses and names in `.doctrine/agent_identities` — a
  human co-author's `Co-Authored-By:` is never affected, whatever their first name. Provenance:
  maintainer ruling 2026-08-22 in the originating project, ported by `BEDROCK-MAINTENANCE.2.5`.

## Command template

```bash
# 1) write concise message
cat > git_message_brief.txt <<'EOF'
<work-unit-id> (leaf <TREE>.<n>): <concise title>

- <brief bullet 1>
- <brief bullet 2>
EOF

# 2) run the project's declared checks when its sources changed
scripts/run check

# 3) stage intended files only
git add <tracked-file-1> <tracked-file-2> ...

# 4) commit  (hooks run the doctrine enforcer)
git commit -F git_message_brief.txt

# 5) clear message file
: > git_message_brief.txt

# 6) verify
wc -c git_message_brief.txt
git ls-files --error-unmatch git_message_brief.txt >/dev/null 2>&1; echo $?
git status --short
```
