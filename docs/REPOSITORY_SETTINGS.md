# Repository settings the spine cannot set for you

Everything the spine enforces lives in files: hooks, CI, checks. Two guarantees it makes depend on
settings of the hosting platform, which no file can carry (review item BK-23). Set them once per
repository, and record that you did in `docs/decisions/`.

## 1. A failing gate must block a merge

On GitHub: **Settings → Branches → Branch protection rule** for the default branch:

- **Require status checks to pass before merging**, and add `doctrines / enforce` (and
  `doctrines / enforcer-selftest` if you run it there) as required checks. A required check that
  never reports blocks the merge, so a deleted workflow cannot pass by absence.
- **Do not allow bypassing the above settings**, and restrict direct pushes to the default branch.

Without this, a red CI run is a report, not a gate: `--no-verify` locally plus a direct push lands
non-compliant work, whatever the hooks say.

### The exact setting, and how you push afterwards

```bash
# required checks on the default branch; admins may still push directly (tighten with enforce_admins=true)
gh api -X PUT repos/<owner>/<repo>/branches/main/protection --input - <<'JSON'
{ "required_status_checks": { "strict": false, "contexts": ["enforce"] },
  "enforce_admins": false, "required_pull_request_reviews": null, "restrictions": null,
  "allow_force_pushes": false, "allow_deletions": false }
JSON
```

- With `enforce_admins: false` the repository's admins keep pushing to the default branch as before
  (CI still runs and is visible); everyone else lands through a pull request whose `enforce` check is green.
- With `enforce_admins: true` nobody pushes directly: `git push -u origin <branch>`, `gh pr create --fill`,
  `gh pr merge --rebase --auto`. Use **rebase** (or a merge commit), never squash: the ownership contract
  judges each commit by its own subject and leaf.
- These are settings of ONE repository. A project created from a template copies files, never settings:
  each child sets its own.

## 2. For bedrock itself: the template flag

On the template repository: **Settings → General → Template repository**, ticked. GitHub's *Use
this template* button and `gh repo create --template` (what `scripts/new_project.sh` runs) need it.

## What these settings do not change

The spine's checks run identically without them — locally through the hooks and in CI per commit.
The settings turn "the build is red" into "it cannot merge". Nothing here affects licence, name
or release clearance (`VISIBILITY.md`).
