# Troubleshooting

Every refusal names its gate and says what to do. This table maps the messages you are most
likely to meet to their fix. Nothing is committed when a hook refuses; fix and commit again.

## Commits refused

| The gate said | It means | Do this |
| --- | --- | --- |
| `governed paths change but the subject names no leaf` | a non-documentation file changed and the subject has no `(leaf …)` | add `(leaf TREE.n)` to the subject, and the leaf's evidence to the tree file |
| `the subject names leaf X but docs/tasks/T.md is not part of this change` | the tree file is not staged | `git add docs/tasks/T.md` after adding this commit's evidence |
| `leaf X was already \`done\` before this change, so it cannot own a new commit` | a finished leaf | open a child leaf `X.1` with its own root cause and evidence |
| `leaf X's section in … gains no line in this change` | the tree is staged but the leaf's section is unchanged | add the commit-log row and the evidence lines to the leaf |
| `has no 'ROOT CAUSE' box` | the box is missing, or its label is not first in the bold | `- [x] **ROOT CAUSE (…)** — …`, label first, one per label |
| `the 'ADDRESSED' box is present but NOT ticked` | `[ ]` | tick it once the evidence is real |
| `carries no line added in this change: evidence must be NEW here` | the box's lines all predate this commit | add this commit's measurement to the box |
| `no tool output sits INSIDE a code span of its bullet` | the evidence is prose, or outside backticks | cite `` `command` → `result` (`rc=0`) ``, or paste the `evidence:` line |
| `the subject must start with a work-unit id such as PROJ-AREA-0007` | the subject's first token is not `WORDS-…-NNNN` | start with your prefix: `ORBIT-APP-0005 …` |
| `the message attributes an AGENT in a trailer` | a `Co-Authored-By` or similar names an AI agent | delete the trailer; a commit message ends with its own last line |
| `MEMORY.md: 'latest_commit:' must name THIS commit` | the pointer is stale | overwrite the current-state block in the same commit |
| `the frontier leaf X is already \`done\`` | the pointer names finished work | point at the next open leaf |
| `MEMORY.md has N lines (> cap 50)` | the pointer grew | demote content to the tree or a decision record; never raise the cap |
| `decision record X is not listed in docs/decisions/INDEX.md` | a record without its row | add the row |
| `KNOWLEDGE_MAP.md is out of sync with its sources` | a hand edit, or the hook did not run | `knowledge-map/scripts/gen_knowledge_map.sh > KNOWLEDGE_MAP.md`, stage it |
| `a tracked document reports its own currency` | a `Last updated:` line | delete it |
| `RISE — … row(s) whose cell count disagrees with their header` | a table row with the wrong number of cells | escape a literal pipe as `\|`; leave a blank line after the table |
| `states a gate does not apply, without naming the leaf that owns fixing it` | an unrouted waiver | name an existing leaf or open one |
| `ADDS a "nothing checks X" claim with no census` | an unbacked claim about the whole tree | cite the search in backticks, or write `census: not run (<why>)` |
| `new lesson entries … no promotion, and 0 explicit decline(s)` | a dated heading in `DEV_NOTES.md` | promote it, or `promotion: declined (<reason>)` per lesson in the leaf |
| `spine path X is missing (a half-installed spine)` | a spine file was deleted | restore it (the updater re-seeds it) |

## `⛔ REFUSED`

The gate could not evaluate. The run fails so the error is never mistaken for a pass.

| Message | Cause | Do this |
| --- | --- | --- |
| `not inside a git worktree, or git failed` | git cannot read the repository (a container running as another user, a broken checkout) | fix git first; `git status` must work |
| `.doctrine/… holds an invalid regular expression` | a seam has a bad pattern | repair it in a change that touches only `.doctrine/` and documentation |
| `ci_range_since=… is not a commit` | an epoch this repository does not have | empty it (migration 0007 does) |
| `registered check is missing` | a check the driver expects is gone | run the updater to restore it |

## Hooks and sessions

| Symptom | Cause | Do this |
| --- | --- | --- |
| commits are never checked in a new clone | the hooks are not installed in this clone | `scripts/bootstrap.sh --contributor` |
| `scripts/run check` says `no 'check' verb` | the project declares no verbs | add `check = …` to `.doctrine/commands`, or install the language pack |
| `handoff: NOT READY — the working tree is not clean` | uncommitted work | commit it, or stash it and say so in `MEMORY.md` |
| `handoff: … project-owned process(es) STILL RUNNING` | a job holds a file in the repository | stop it and its children |
| `handoff: 'latest_commit:' is stale` | a governed commit bypassed the hooks | fix the pointer in a commit |
| CI is red on the Initial commit of a new project | the template copy was not yet bootstrapped when GitHub ran CI | expected once; the bootstrap commit passes |
| the wizard did not appear | input is not a terminal | run on a terminal, pass flags, or use `--ask` with piped answers |

## Bootstrap and upgrade

See the end of [The bootstrap, step by step](bootstrap.md) and of
[Upgrading the spine, step by step](updating.md).
