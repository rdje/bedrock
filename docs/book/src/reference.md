# Command and file reference

## Commands

### `scripts/new_project.sh` (run in a clone of bedrock)

```text
scripts/new_project.sh [--name <n>] [--dest <dir>] [--github|--local] [--owner <gh-user-or-org>]
                       [--title "<t>"] [--prefix <P>] [--visibility public|private]
                       [--lang <pack>|none] [--docs <pack>|none] [--harness <a,b>|none]
                       [--yes] [--push|--no-push]
```

Asks the questions, creates the repository (GitHub through `gh`, or local), clones, bootstraps,
commits, offers the push.

### `scripts/bootstrap.sh` (run in a project)

```text
scripts/bootstrap.sh [<name>] [--title "<t>"] [--prefix <P>] [--visibility public|private]
                     [--lang <pack>|none] [--docs <pack>|none] [--harness <a,b>|none] [--yes] [--ask]
scripts/bootstrap.sh --contributor
scripts/bootstrap.sh --maintainer
```

### `scripts/gate`

```text
scripts/gate                  # the index against HEAD
scripts/gate --message <file> # with a commit message
scripts/gate --commit <rev>   # one commit against its parent
scripts/gate --range <a>..<b> # every commit in the range
```

### `scripts/run`

```text
scripts/run <verb> [args…]    # a verb from .doctrine/commands
scripts/run --list
```

### `scripts/evidence`

```text
scripts/evidence [-n <lines>] -- <command> [args…]
```

Prints `evidence: rc=<n> cmd="…" out-sha256=<hash> lines=<n>` and the output's tail; exits with
the command's status.

### `scripts/handoff`

```text
scripts/handoff [--all]
```

### `scripts/update_scaffold.sh`

```text
scripts/update_scaffold.sh <bedrock-url-or-path> [--ref <tag|sha>] [--plan] [--merge] [--force]
                           [--add-pack <kind/name>]
```

### The checks

`scripts/check_doctrines.sh` (the driver) and `scripts/check_<name>.sh`, one per gate; several
accept `--self-test`. `scripts/check_doctrines.project.sh` is yours.

## Files, by who owns them

| Class | Files |
| --- | --- |
| spine (bedrock's; updated when you never modified them) | `AGENTS.md`, `COMMIT.md`, `DOCTRINE_ENFORCEMENT.md`, `MEMORY_ARCHITECTURE.md`, `LICENSE`, `NOTICE`, `docs/TASK_TREE_README.md`, `docs/tasks/TEMPLATE.md`, `docs/decisions/TEMPLATE.md`, `docs/REPOSITORY_SETTINGS.md`, `.doctrine/README.md`, `.doctrine/neutrality_*`, `.githooks/`, `.github/workflows/doctrines.yml`, `scripts/` (except the project slot), `knowledge-map/scripts/`, `migrations/`, `.bedrock/manifest`, `DOCTRINE_VERSION` |
| seed (yours from creation; never touched again) | `TOOLBOX.md`, `README_POLICY.md`, `VISIBILITY.md`, `docs/TASK_TREE.md`, `.gitignore`, `.doctrine/config`, `.doctrine/docs_paths.txt`, `.doctrine/evidence_tokens.txt`, `.doctrine/commands`, `.doctrine/agent_identities`, `.doctrine/handoff_ignore`, `.doctrine/harness_adapters`, a pack's starter files |
| project (yours) | `README.md`, `ROADMAP.md`, `MEMORY.md`, `CHANGELOG.md`, `DEV_NOTES.md`, `LIVE_STATUS.md`, `KNOWLEDGE_MAP.md`, `knowledge-map/subsystems.md`, `scripts/check_doctrines.project.sh`, `docs/tasks/*.md`, `docs/decisions/INDEX.md` and your records, `.bedrock/project`, harness adapter files |
| maintainer (bedrock-only, never in a project) | `MAINTAINING.md`, bedrock's trees and decision records, `docs/reviews/`, this guide, `.github/workflows/book.yml` |
| pack (opt-in) | `packs/lang/rust`, `packs/docs/mdbook`, `packs/harness/*` |

## Frequently asked

**Why LGPL for the spine, and what does it cover?** The spine's files are LGPL-2.1-or-later, the
model FFmpeg uses: anyone may use them in any project, including closed-source ones; changes to
those files stay under the licence and keep the notices. Seed files are 0BSD, so you can
relicense them. Your own code and content are not covered. `NOTICE` says so in the licensor's
words.

**Does bedrock's branch protection apply to my project?** No. Settings belong to one repository;
a template copies files. Set yours per `docs/REPOSITORY_SETTINGS.md`.

**Why run the updater with `--plan`?** You don't have to. It is a dry run that shows the plan and
writes nothing; useful before a large jump, optional otherwise. The real run refuses a dirty
tree, never overwrites a modified file, and only stages.

**Can I use bedrock without any AI harness?** Yes. `AGENTS.md` is written for a person too, the
hooks and CI do not care who commits, and the harness question accepts `none`.

**Can a project switch harness later?** At any hand-off. Add the harness's pack if it reads a
file of its own; Codex, Pi and Kimi read `AGENTS.md` as it is.

**What if a gate is wrong for my case?** Write the waiver in the leaf and name the leaf that owns
fixing the gate (the `WAIVER-ROUTING` gate makes sure it is not lost). If the gate is bedrock's,
that leaf can be a bedrock maintenance leaf: improvements flow back.
