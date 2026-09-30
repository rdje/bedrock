# Adding your own doctrine

The universal gates judge the spine's concerns. Your project has its own: a source of truth that
must stay in sync, a format that must hold, a generated file that must match its generator.
Those go in the **project slot**, `scripts/check_doctrines.project.sh`, which the driver runs
last as `PROJECT-SPECIFIC`. It ships as a passing no-op.

## The shape of a check

```bash
#!/usr/bin/env bash
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib/spine.sh"; spine_init PROJECT-SPECIFIC

# every generated schema must match its generator
for f in $(spine_changed_paths | grep -E '^schemas/.*\.json$'); do
  spine_read "$f" > "$SPINE_TMP/actual.json"
  bash tools/gen_schema.sh "${f#schemas/}" > "$SPINE_TMP/expected.json" || spine_refuse "the schema generator failed on $f"
  cmp -s "$SPINE_TMP/actual.json" "$SPINE_TMP/expected.json" || { spine_fail "$f is out of date: run tools/gen_schema.sh"; exit 1; }
done
exit 0
```

Three rules make it a real gate rather than a script that happens to run:

- **Read the change through the library.** `spine_changed_paths` lists what the commit changes;
  `spine_read <path>` gives the content as it will be committed, never the working tree. That is
  what makes "an unstaged edit hides a staged defect" impossible.
- **Honour the exit contract.** `exit 1` with a message on stderr (`spine_fail`) for a breach;
  `spine_refuse "…"` (exit 2) when you cannot evaluate, such as a missing tool. Never `exit 0`
  around an error.
- **Keep it fast.** The hook runs it on every commit. Anything heavier than a few seconds
  belongs in a CI job.

## The library, in short

| Function | Gives you |
| --- | --- |
| `spine_init <ID>` | the fail-closed prelude: the repository root, the change context |
| `spine_changed_paths` | paths that exist after the change and were touched |
| `spine_removed_paths`, `spine_touched_paths` | deletions, and both sides together |
| `spine_read <path>` | the file's content in the after-snapshot (exit 1 if absent) |
| `spine_read_before <path>` | its content before the change |
| `spine_added_lines <path>`, `spine_added_text <path>` | the lines the change adds, by number or text |
| `spine_config <key> <default>`, `spine_config_file <name>` | `.doctrine/` data, as of the last commit |
| `spine_tmp` | a scratch directory outside the worktree, removed on exit (`$SPINE_TMP`) |
| `spine_ok`, `spine_fail`, `spine_refuse` | the three verdicts |
| `spine_msg_subject`, `spine_msg_leaf`, `spine_msg_trailers` | the commit message, when `SPINE_COMMIT_MSG` is set |

One trap: never call `spine_refuse` inside a `$( … )` capture; it ends the subshell only, and
the caller continues with an empty string.

## Data, not names

If your check needs a list that may grow, put it in a file under `.doctrine/` and read it with
`spine_config_file`. It is then read as of the last commit, like every seam, and changing it is a
governed change with its own leaf.

## When it becomes general

A check that would help any project on day one, in any language, under any harness, belongs in
bedrock. The recipe for porting it there, and the tests it must come with, is in
[Maintaining and extending bedrock](maintaining.md).
