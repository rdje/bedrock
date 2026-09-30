# The updater never overwrites a file the project changed; it fast-forwards one the project never touched

- **Type:** `decision`
- **Date:** `2026-09-30`
- **Status:** `active` (refines the maintainer instruction of 2026-09-21: *"shall not update files that
  are different. Worst case it shall ask to merge, never overwrite, never."*)
- **Owner / source:** `REVIEW-2026-09.6`, review items BK-09, BK-10, BR-01, BR-09

## The fact / decision

`scripts/update_scaffold.sh` acts by the **ownership class** every shipped path carries in
`.bedrock/manifest`, read from the **fetched source**, never from the project's own copy:

| Class | Absent in the project | Present and identical | Present and different |
| --- | --- | --- | --- |
| `spine` | seeded | nothing | **fast-forwarded** if byte-identical to the template version the project last synced from (it never touched it); otherwise copied to `.bedrock-incoming/`, never overwritten, three-way merge offered with `--merge` |
| `seed` | seeded | nothing | nothing — the project owns it |
| `project` | nothing | nothing | nothing — except the printed bookkeeping the upgrade commit needs: the `UPDATE` row in `docs/TASK_TREE.md`, and `MEMORY.md`'s `latest_commit` (its whole current-state block when it cannot pass `RESUME-POINTER`, the previous block kept in `.bedrock-incoming/`) |
| `maintainer` | nothing (bedrock-only) | — | — |

Two further rules: the updater **replaces itself first** from the source and re-executes, so a
child never upgrades with the file list of the version it was created from (BK-09); and
`DOCTRINE_VERSION` is written **only after** every registered check exists and the gate passes
over the staged upgrade (BK-09, BK-10). Migrations under `migrations/` repair content that an
older template created, and an `UPDATE-<version>` leaf with measured evidence owns the upgrade
commit.

## Why

"Never overwrite a different file" protected project content, which was right; applied to spine
files a project never edited, it turned every upgrade into twenty manual merges and left the
gate running old code. A file byte-identical to the version bedrock shipped carries no project
content by definition, so updating it is not the loss the rule guards against. A file the
project changed is still never touched. The base version is resolved from the project's recorded
`DOCTRINE_VERSION` through the commit that introduced it upstream; when it cannot be resolved,
the file is treated as modified (the safe direction).

## How to apply

- Classify every new spine path in `.bedrock/manifest`; the `MANIFEST` gate refuses an
  unclassified one.
- Ship a migration with any change to the shape of generated content, and bump the version.
- Tell existing children (release note) to copy `scripts/update_scaffold.sh` by hand once; from then
  on the updater replaces itself.
- Related: [[decision_neutral_spine_and_packs]], [[decision_licence]].
