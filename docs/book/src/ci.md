# CI and repository settings

The same gates that run in your hooks run in CI, on every commit, where `--no-verify` cannot
reach. Two repository settings on the hosting platform turn a red run into a blocked merge.

## The workflow every project has: `doctrines.yml`

Two jobs, on every push and pull request.

**`enforce`** runs `scripts/check_doctrines.sh --range <base>..<tip>`: every commit the push or
pull request introduces is judged against its own parent, with its real message. So a subject
without a work-unit id, an unowned change or a stale pointer is refused in CI even if the local
hook was bypassed. A push to a new branch, with no known base, judges the tip only.

Before that, one guard: a repository not named `bedrock` that still carries `MAINTAINING.md` was
created from the template and never bootstrapped; the job fails with the instruction to run the
bootstrap. (The Initial commit GitHub makes for a new repository fails this on purpose; the
bootstrap commit that follows passes.)

**`enforcer-selftest`** runs the enforcer's own tests: a syntax pass over every script, each
gate's `--self-test`, the two probe drivers, and shellcheck (errors block; the full report is
advisory). In bedrock itself it also runs the conformance suite, on Linux and macOS; in a
project the suite does not apply and the macOS leg is skipped, so a private project pays for
Linux minutes only.

The workflow pins its actions by commit and requests read-only permissions.

## The contract epoch

`ci_range_since` in `.doctrine/config` names a commit at or before which CI does not re-judge
history: those commits were judged by the gate they shipped with. bedrock sets it at its 1.0.0
commit. In a project it is empty; your whole history is under the contract you received. If you
ever adopt a stricter contract and want CI to start judging from that commit on, set it there,
in a governed change.

## A pack's workflow

The Rust pack adds `rust.yml`: fmt, clippy with warnings denied, and the tests, through
`scripts/run check`, with the toolchain pinned by `rust-toolchain.toml`. Other packs may add
theirs.

## The two settings you must set yourself

Settings live on the hosting platform, not in files, so no script can set them for you inside
the repository. Both are in `docs/REPOSITORY_SETTINGS.md` with the exact commands.

### 1. Make a red run block a merge

GitHub: Settings → Branches → a protection rule for the default branch, requiring the
`enforce` status check (and the self-test if you want it required too), with force pushes and
deletion refused. Or with the CLI:

```bash
gh api -X PUT repos/<owner>/<repo>/branches/main/protection --input - <<'JSON'
{ "required_status_checks": { "strict": false, "contexts": ["enforce"] },
  "enforce_admins": false, "required_pull_request_reviews": null, "restrictions": null,
  "allow_force_pushes": false, "allow_deletions": false }
JSON
```

Then, two ways of working:

- `enforce_admins: false`: administrators keep pushing to `main` directly; everyone else lands
  through a pull request whose check is green. CI still runs on the admin's push.
- `enforce_admins: true`: nobody pushes directly. Work on a branch, `gh pr create --fill`, and
  `gh pr merge --rebase --auto`. Use rebase or a merge commit, never squash: the contract judges
  each commit by its own subject and leaf.

Branch protection belongs to one repository. A project created from a template copies files,
never settings; each child sets its own.

### 2. For bedrock itself: the template flag

Settings → General → *Template repository*, ticked. GitHub's "Use this template" button and
`scripts/new_project.sh` need it. bedrock also enables GitHub Pages (source: GitHub Actions) so
this guide is published by the `book.yml` workflow.

## Reading a red run

Open the failed job. The enforcer's output is the same as in the hook: the commit being judged,
each gate, `❌` with its reason. Fix on your branch, commit under the same leaf (an open leaf may
own several commits) and push again.
