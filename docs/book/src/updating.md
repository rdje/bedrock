# Upgrading the spine, step by step

bedrock improves over time. `scripts/update_scaffold.sh` pulls a newer spine into your project
while touching nothing that is yours. This chapter walks through a real upgrade, then explains
each rule the script follows.

## When to upgrade

When a bedrock release says something for you in its `CHANGELOG.md` ("for existing children"),
or when you want a new gate or pack. `DOCTRINE_VERSION` tells you where your project is.

## Before the first upgrade of an old project

Projects created before bedrock 0.17.0 carry an updater that knows nothing of the manifest.
Once, by hand: copy `scripts/update_scaffold.sh` from bedrock into your project, commit it, and
run that. From then on the updater replaces itself.

## The call

```bash
scripts/update_scaffold.sh <bedrock-url-or-local-path> [--ref <tag>] [--plan] [--merge] [--add-pack <kind/name>]
```

- The source is a URL (`https://github.com/rdje/bedrock`) or a local clone.
- `--ref v1.0.3` pins the exact release. Without it, the source's current tip is used and its
  commit is recorded in the leaf.
- `--plan` is a dry run: it prints what would happen and writes nothing.
- `--merge` offers, per modified file, a three-way merge into a side file.
- `--force` skips only the clean-tree check. Nothing makes the tool overwrite your files.

## A real upgrade: 0.6.1 to 1.0.3

The project below was created from bedrock 0.6.1. It has a customised `TOOLBOX.md` (a table of
its own tools) and a hardened copy of one check, `scripts/check_docpaths.sh`.

### The plan

```text
$ scripts/update_scaffold.sh ~/src/bedrock --ref v1.0.3 --plan
update: bedrock-scaffold 0.6.1 → bedrock-scaffold 1.0.3 (source 44501fe, base f210a96) — PLAN ONLY, nothing written
  would seed     .bedrock/manifest
  would update   .doctrine/README.md (unmodified since bedrock-scaffold 0.6.1)
  would seed     .doctrine/agent_identities
  would seed     .doctrine/commands
  would update   .githooks/commit-msg (unmodified since bedrock-scaffold 0.6.1)
  would update   .githooks/pre-commit (unmodified since bedrock-scaffold 0.6.1)
  …
  would differ   scripts/check_docpaths.sh (modified here; theirs would go to .bedrock-incoming/)
update: PLAN — 33 to seed, 26 to update (unmodified), 1 differ (would go to .bedrock-incoming/); migrations newer than 0.6.1:
  would run      0002-retire-code-paths.sh (since 0.14.0)
  would run      0003-backfill-identity.sh (since 0.16.0)
  would run      0004-agents-canonical.sh (since 0.13.0)
  would run      0005-pointer-field-names.sh (since 0.7.0)
  would run      0006-detect-installed-packs.sh (since 0.19.0)
  would run      0007-clear-foreign-epoch.sh (since 1.0.1)
update: nothing written (--plan)
```

Read it as three lists: what is new and will be created (`would seed`), what you never touched
and will be brought up to date (`would update`), and what you changed and will **not** be
touched (`would differ`). `TOOLBOX.md` appears in none of them: it is a `seed` file, yours since
creation, and the updater never looks at it again.

### The run

```text
$ scripts/update_scaffold.sh ~/src/bedrock --ref v1.0.3
update: bedrock-scaffold 0.6.1 → bedrock-scaffold 1.0.3 (source 44501fe, base f210a96)
  seeded         .bedrock/manifest
  updated        .doctrine/README.md (yours was the unmodified bedrock-scaffold 0.6.1 version)
  seeded         .doctrine/agent_identities (yours to edit from now on)
  …
  DIFFERS        scripts/check_docpaths.sh — yours is UNTOUCHED; theirs is .bedrock-incoming/scripts/check_docpaths.sh
  migration 0002: nothing to do
  migration 0003: .bedrock/project written (name=old, prefix=STITCH) — check it
  migration 0004: AGENTS.md is already canonical; CLAUDE.md becomes the adapter, its previous body is kept at .bedrock-incoming/CLAUDE.md.previous
  migration 0005: MEMORY.md current-state fields renamed to next_action / active_work_unit / latest_commit / in_flight_uncommitted / blockers
  migration 0006: packs recorded in .bedrock/project: rust,mdbook,claude
  migration 0007: cleared ci_range_since (0f471da… is not a commit of this repository)
  edited         docs/TASK_TREE.md (+1 row: UPDATE-1-0-3)
  edited         MEMORY.md (latest_commit → STITCH-SPINE-10003)
update: judging the staged upgrade with the enforcer…
=== doctrine enforcement (18 checks; index vs ab8e2ea) ===
=== all doctrines green ===
✓ update: 33 seeded, 26 updated, 1 differ, 6 migration(s) — DOCTRINE_VERSION is now bedrock-scaffold 1.0.3; the upgrade is staged.
  ⚠️  1 file(s) you modified were NOT touched; the source's versions are in .bedrock-incoming/. Review them, take what you
      want, then:  rm -rf .bedrock-incoming   (improvement often flows project → bedrock; theirs is not automatically better)

Commit the update (everything is staged; docs/tasks/UPDATE-1-0-3.md carries the evidence):
       printf '%s\n' 'STITCH-SPINE-10003 (leaf UPDATE-1-0-3.1): spine updated to bedrock-scaffold 1.0.3' > git_message_brief.txt
       git commit -F git_message_brief.txt && : > git_message_brief.txt
```

Afterwards: the custom `TOOLBOX.md` row is still there, the hardened check is byte-identical,
and its new version waits in `.bedrock-incoming/scripts/check_docpaths.sh` for you to compare.
Nothing is committed until you run the printed command.

## What the script does, in order

1. **Preflight.** The tools it needs exist; this is a git repository; the working tree is clean.
   A dirty tree is refused because uncommitted content is the one thing a write can destroy.
2. **Fetch and export.** A full clone of the source (its history is needed for the merge base),
   then `git archive` of the pinned commit into a temporary directory. No `.git`, no build
   output. A source without a manifest, or older than your project, is refused.
3. **Step 0: replace itself.** If the source's updater differs from the one running, yours is
   kept at `.bedrock-incoming/scripts/update_scaffold.sh.previous`, the new one is written, and
   it re-executes. The code that upgrades is always the source's.
4. **The merge base.** Every commit that carried your recorded version is a candidate; a file
   that equals any of them is "unmodified". The first of them is the three-way merge base.
5. **Classify and act**, per path of the source's manifest:

   | Class | Absent here | Present, identical | Present, different |
   | --- | --- | --- | --- |
   | `spine` | seeded | nothing | unmodified since your version: **updated**; otherwise `.bedrock-incoming/<path>`, yours untouched |
   | `seed` | seeded | nothing | nothing, ever |
   | `project`, `maintainer` | nothing | nothing | nothing |

   In a project, a Markdown spine file is compared without bedrock's own maintainer note, which
   the bootstrap stripped. Installed packs (`packs =` in `.bedrock/project`) are synced the same
   way, `sync` files by the spine rule, `seed` files never.
6. **Migrations.** Each `migrations/NNNN-<slug>.sh` whose `since:` version is newer than yours
   runs, oldest first, and prints what it changed. They are idempotent.
7. **Verification.** Every check the new driver registers must exist and parse.
8. **Bookkeeping for the commit.** `docs/tasks/UPDATE-<version>.md` is written with the measured
   counts; one row is added to `docs/TASK_TREE.md`; `MEMORY.md`'s `latest_commit` is set (and
   its whole current-state block rewritten only if it cannot pass the pointer gate, the previous
   block kept in `.bedrock-incoming/`). Every edit is printed.
9. **The gate.** Everything is staged, the Knowledge Map regenerated, and the enforcer judges the
   staged upgrade with the commit's real subject. Its verdict is written into the leaf.
10. **The version, last.** `DOCTRINE_VERSION` is written only if the gate passed. Then the exact
    commit command is printed.

## The migrations

| Migration | Since | What it repairs |
| --- | --- | --- |
| `0001-remove-last-updated-fields` | 0.5.0 | deletes `Last updated:` lines older templates shipped |
| `0002-retire-code-paths` | 0.14.0 | retires `.doctrine/code_paths.txt`; keeps its content as a comment in `docs_paths.txt` |
| `0003-backfill-identity` | 0.16.0 | writes `.bedrock/project` for a project created before it existed (check the values) |
| `0004-agents-canonical` | 0.13.0 | makes `AGENTS.md` the complete instruction file and `CLAUDE.md` an adapter; the old body is kept |
| `0005-pointer-field-names` | 0.7.0 | renames `MEMORY.md`'s fields to the ones the pointer gate reads |
| `0006-detect-installed-packs` | 0.19.0 | records the packs the project already carries |
| `0007-clear-foreign-epoch` | 1.0.1 | empties a CI epoch that names a commit this repository does not have |

## `.bedrock-incoming/`

One directory to read and one to delete. It holds the new version of every file you had
modified, your previous updater, and anything a migration set aside. Compare, take what you
want, then `rm -rf .bedrock-incoming`. It is ignored by git, so it cannot be committed by
accident. With `--merge`, the script asks per file and writes a three-way merge to
`<path>.merged` beside it; conflicts keep their markers; your file is still untouched.

## Undo

Until you run the printed commit, everything is only staged: `git reset --hard` returns the
tree to the previous commit. After the commit, it is one commit to revert.

## When it refuses

| Message | Cause | Do |
| --- | --- | --- |
| `the working tree is not clean` | uncommitted changes | commit or stash them |
| `the source at … ships no .bedrock/manifest` | you pointed at a bedrock older than 0.17.0 | use a newer `--ref` |
| `… is OLDER than this project … a downgrade is refused` | the ref is older than `DOCTRINE_VERSION` | pick a newer ref |
| `registered check(s) missing or unparsable after sync` | a check the driver expects is absent | rerun; if it persists, report it |
| `the gate REFUSED the staged upgrade` | a check failed on the staged result | read its message; often a file in `.bedrock-incoming/` must be merged |
