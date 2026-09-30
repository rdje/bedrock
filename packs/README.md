# packs/ — everything that is not the spine

The spine is project-, harness- and language-neutral. A **pack** is what a project opts into at
setup (`scripts/bootstrap.sh --lang rust --docs mdbook --harness claude`, or the guided
questions) or later (`scripts/update_scaffold.sh <bedrock> --add-pack <name>`). Unselected packs
are not copied into a project.

| Pack | Kind | Gives the project |
| --- | --- | --- |
| `lang/rust` | language | a cargo workspace with a starter crate named after the project, rustfmt, clippy, tests, a pinned toolchain, a `rust.yml` workflow, a `Makefile`, its verbs and evidence tokens |
| `docs/mdbook` | docs | an mdBook skeleton under `docs/book/` and the `docs` verb |
| `harness/claude` (default), `codex`, `pi`, `kimi`, `qwen`, `gemini` | harness | what a harness needs beyond `AGENTS.md`, which every one of them reads: an adapter file for the ones that auto-read their own (`CLAUDE.md`, `QWEN.md`, `GEMINI.md`, each a one-line `@AGENTS.md` import), and the hand-off census exclusions for its session processes. Codex, Pi and Kimi read `AGENTS.md` natively (verified against their documentation, 2026-09-30) and ship exclusions only. The harness is transparent to the project: switch it at any hand-off |

A pack is a directory with a plain `pack` manifest (`key = value`), a `files/` tree copied into
the project root (`seed` paths become the project's own; `sync` paths follow the spine's update
rule), optional fragments appended to `.gitignore`, `.doctrine/commands`,
`.doctrine/evidence_tokens.txt`, `.doctrine/docs_paths.txt` and `.doctrine/handoff_ignore`, and an
optional `install.sh` hook that runs with the project name and prints measured evidence lines.
`order =` sets its place in the setup questions and `default = yes` makes it the answer Enter
accepts. Adding a pack never requires editing a spine script: `MAINTAINING.md` has the recipe.
