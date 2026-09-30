# Packs

The spine is neutral by contract: no language, no build tool, no docs tool, no harness in its
logic. Everything specific is a **pack**: a directory under `packs/` in bedrock that you opt
into at setup, or later. A pack you did not choose is never copied into your project.

## The packs bedrock ships

| Pack | Kind | What it gives the project |
| --- | --- | --- |
| `packs/lang/rust` | language | a cargo workspace with a starter binary crate named after the project, rustfmt, clippy with warnings denied, tests, a pinned toolchain, a `rust.yml` workflow, a `Makefile`, the verbs `check` `test` `lint` `fmt` `build`, and what cargo prints as evidence shapes |
| `packs/docs/mdbook` | docs | an mdBook skeleton under `docs/book/`, titled after the project, and the `docs` verb |
| `packs/harness/claude` | harness | `CLAUDE.md`, a one-line adapter importing `AGENTS.md`; the harness's session processes ignored at hand-off. The default answer |
| `packs/harness/codex` | harness | Codex reads `AGENTS.md` natively; the pack ships only its hand-off exclusions |
| `packs/harness/pi` | harness | the same, for Pi |
| `packs/harness/kimi` | harness | the same, for Kimi Code |
| `packs/harness/qwen` | harness | `QWEN.md`, a one-line adapter importing `AGENTS.md`, plus exclusions |
| `packs/harness/gemini` | harness | `GEMINI.md`, the same shape |

The harness list is ordered by the maintainer's preference; the order and the default come
from each pack's own manifest, not from a script.

## Choosing packs

At setup: the wizard's questions 5, 6 and 7, or the flags `--lang`, `--docs`, `--harness a,b`.
Later:

```bash
scripts/update_scaffold.sh <bedrock> --add-pack docs/mdbook
scripts/update_scaffold.sh <bedrock> --add-pack harness/qwen
```

`--add-pack` copies the pack from the bedrock you point at, appends its fragments, runs its
install hook and records it in `.bedrock/project`. It refuses if any file the pack ships already
exists.

## What installing a pack does

1. Its `files/` are copied into the project root (a collision is refused).
2. Its fragments are appended: `gitignore` → `.gitignore`, `commands` → `.doctrine/commands`,
   `evidence_tokens` → `.doctrine/evidence_tokens.txt`, `docs_paths` →
   `.doctrine/docs_paths.txt`, `handoff_ignore` → `.doctrine/handoff_ignore`.
3. Its `install.sh` hook runs with the project name and title, and prints what it measured.
4. Its name is added to `packs =` in `.bedrock/project`.

## How the updater treats a pack's files

A pack's manifest classes each of its files as `seed` or `sync`:

- **seed**: the project's own from the moment they are copied. The Rust starter crate, the
  book skeleton. The updater never touches them again.
- **sync**: pack-owned, such as the Rust pack's `rust.yml`. The updater fast-forwards them when
  you never modified them, and parks the new version beside yours when you did.

## Switching or adding a harness

Nothing in the project depends on which harness works on it. To start using a harness that reads
its own file, add its pack; to stop, delete the adapter file. Codex, Pi and Kimi need no file at
all. See [Ending a session, switching harness](handoff.md).

## Writing a pack

A pack is a directory with a plain `pack` manifest:

```text
name = rust
kind = lang            # lang | docs | harness
order = 1              # its place in the setup questions
default = no           # yes: the answer Enter accepts
title = Rust — a cargo workspace …
seed = Cargo.toml crates/ rust-toolchain.toml Makefile
sync = .github/workflows/rust.yml
gitignore = gitignore
commands = commands
evidence_tokens = evidence_tokens
docs_paths =
install = install.sh
```

plus `files/`, the fragment files named above, and the hook. Adding a pack never requires
editing a spine script. The recipe, with the tests a pack must come with, is in
[Maintaining and extending bedrock](maintaining.md).
