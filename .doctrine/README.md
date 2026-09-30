# `.doctrine/` — the project-declared seams

These optional files let a project adapt the **neutral** doctrine checks to its own shape
**without editing the checks**. Editing a spine check to hardcode your paths or your tool names
turns a portable standard into a fork of it — that is what these seams exist to prevent.

| file | consumed by | meaning |
|---|---|---|
| `docs_paths.txt` | `TASK-TREE-OWNERSHIP`, `TASK-ACCEPTANCE` | one extended regular expression per line (**not** a glob: `^docs/site/`, not `docs/site/*`): extra **documentation** paths, exempt from governance. Everything else is governed; the spine set always is. *(`code_paths.txt` is retired and refused if present: governance is deny-by-default.)* |
| `agent_identities` | `COMMIT-MESSAGE` | `address <ERE>` / `name <ERE>` lines: who counts as an AGENT in an attribution trailer. Nothing is built into the check; every identity is data here. |
| `commands` | `scripts/run` | `verb = command` lines — the project's own `check`, `test`, `lint`, `fmt`, `build`, `docs`. Packs append theirs at install. An undeclared verb is refused. |
| `handoff_ignore` | `scripts/handoff` | shell globs of session processes the hand-off census ignores (harness packs append theirs). Read from the working tree. |
| `harness_adapters` | `MEMORY-ARCH` | the files a harness auto-reads instead of `AGENTS.md`; each one present must point at `AGENTS.md`. |
| `evidence_tokens.txt` | `TASK-ACCEPTANCE` | one extended regular expression per line: **your** tools' output signatures, ADDED to the universal defaults. Absent ⇒ defaults only. |
| `config` | `MEMORY-ARCH`, `README-STABILITY`, the driver's `--range` | `key = value` settings: `memory_pointer_line_cap`, `memory_pointer_byte_cap`, `readme_line_cap`, `readme_byte_cap` (absent ⇒ 50 / 7168 / 300 / 16384); `ci_range_since` — the contract epoch, a commit at or before which CI does not re-judge history (empty in a child: its whole history is under the contract). |

Blank lines and `#` comments are ignored in all of them.

⛔ **Every file here is read as of the LAST COMMIT, never from the working tree.** A change to a
seam takes effect from the *next* commit, so a commit cannot loosen the gate that judges it
(`decision_ownership_contract`, BK-06). An invalid regular expression is **refused** (exit 2), not
skipped; repair it in a change that touches only `.doctrine/` and documentation.

## When to declare evidence tokens

`TASK-ACCEPTANCE` requires each hard-gated checklist box to contain output from a tool that was
actually run, inside a code span of the box. It ships with tool-neutral result shapes (`rc=0`,
`exit 1`, `12 passed / 0 failed`, the `evidence:` line `scripts/evidence -- <command>` prints)
and a few universal compiler/test outputs (`test result: ok`, `error[E1234]`, panics). Language
packs add their tools' native output shapes here; a bare tool name or version number is never a
signature.

If your project has its own instruments — a coverage reporter, a conformance gate, a custom
linter — declare their output signatures here so an author can cite them:

```
# .doctrine/evidence_tokens.txt
WIDGET-COVERAGE:
MYGATE: (pass|fail)
```

⚠️ **A signature family that does not match your real corpus is a gate that teaches authors to
waive it.** Before adopting a token, check it against the evidence your team actually pastes; a
family that backs almost nothing is worse than no family, because the honest response to it is a
waiver — which is itself a bug report about the gate (see `WAIVER-ROUTING`).
