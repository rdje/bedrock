# Configuration: the project seams

A spine check never carries your project's names inside it. What is specific to your project is
**data**, in `.doctrine/`, and the checks read it. Two rules apply to every file there:

- **It is read as of the last commit**, never from the working tree. A change to a seam takes
  effect from the *next* commit, so a commit cannot loosen the gate that judges it.
- **An invalid entry is refused**, not skipped. Repair it in a change that touches only
  `.doctrine/` and documentation.

Editing a seam is itself a governed change: it needs an owning leaf.

## The files

### `.doctrine/config`

`key = value` lines.

| Key | Meaning | Default |
| --- | --- | --- |
| `memory_pointer_line_cap` | the line cap on `MEMORY.md` | 50 |
| `memory_pointer_byte_cap` | its byte cap | 7168 |
| `readme_line_cap` | the line cap on `README.md` | 300 |
| `readme_byte_cap` | its byte cap | 16384 |
| `ci_range_since` | a commit at or before which CI does not re-judge history; empty in a project | empty |

Never raise a cap to fit content: demote the content.

### `.doctrine/docs_paths.txt`

One extended regular expression per line (not a glob: `^docs/site/`, not `docs/site/*`). Paths
that match are **documentation** and need no leaf. Markdown, text, licence files, images and
`.gitignore` already are. The spine set can never be exempted.

### `.doctrine/evidence_tokens.txt`

One extended regular expression per line: what *your* tools print when they succeed or fail,
added to the built-in shapes (`rc=N`, `exit N`, `12 passed / 0 failed`, `all tests passed`, the
errno names, the `evidence:` line). A language pack appends its compiler's and test runner's
lines at install. Declare a token only if your team actually pastes that output; a token that
backs nothing teaches authors to waive the gate.

### `.doctrine/commands`

`verb = command` lines. `scripts/run <verb>` runs the command through `bash -c`; an undeclared
verb is refused with the list. Conventional verbs, so any agent can call them without knowing
the language: `check`, `test`, `lint`, `fmt`, `build`, `docs`. Packs append theirs.

```text
check = cargo fmt --all -- --check && cargo clippy --all-targets --all-features -- -D warnings && cargo test --workspace --all-features
docs = mdbook build docs/book
```

### `.doctrine/agent_identities`

Who counts as an AI agent in a commit message, for `COMMIT-MESSAGE`:

```text
address noreply@anthropic\.com$          # matched against the e-mail in a trailer
name ^(Claude( Code)?|Codex|Gemini( CLI)?|…)$   # matched against the whole name, exactly
line ^claude-session:                    # a body line a harness adds
```

A human named Claude is never an agent: names must match exactly; addresses are the primary
signal.

### `.doctrine/handoff_ignore`

Shell globs, one per line, of session processes the hand-off census ignores. Harness packs
append the processes of their harness. Read from the working tree, because hand-off is a
session check, not a commit gate.

### `.doctrine/harness_adapters`

The files a harness auto-reads instead of `AGENTS.md`: `CLAUDE.md`, `QWEN.md`, `GEMINI.md`, …
Each one present must point at `AGENTS.md`; an absent one is fine.

### `.doctrine/neutrality_terms` and `.doctrine/neutrality_allow`

Used by the `NEUTRALITY` gate in bedrock itself: the words that mark logic as bound to a language
or harness, and the spine paths allowed to contain them, each with a reason. A project inherits
them unused.

### `.doctrine/README.md`

The short reference for all of the above, kept next to the files.

## `.bedrock/`

### `.bedrock/project`

Your identity card, written by the bootstrap and read by the updater and the tools: `name`,
`title`, `prefix`, `visibility`, `created`, `source` (the bedrock version you started from), and
`packs` (the packs installed, comma-separated). Do not edit it by hand; the updater's
`--add-pack` and the migrations maintain it.

### `.bedrock/manifest`

Every path bedrock ships, its ownership class and the version that added it. It is bedrock's,
read by the updater *from the source it fetches*, and checked by the `MANIFEST` gate.

| Class | Meaning for the updater |
| --- | --- |
| `spine` | bedrock's; identical is left, absent is seeded, unmodified is fast-forwarded, modified is never touched |
| `seed` | created once for you to own; seeded when absent, never touched again |
| `project` | yours; never touched |
| `maintainer` | bedrock-only; removed at bootstrap, never shipped |
| `pack` | opt-in; copied only when selected |

The licence follows the class: spine files are LGPL-2.1-or-later; seed files are 0BSD; your own
files are yours. `NOTICE` says it in full.

## `DOCTRINE_VERSION`

The spine version this project is at (`bedrock-scaffold 1.0.3`). The updater reads it to find
the merge base and writes the new one only after the upgrade passes the gate.
