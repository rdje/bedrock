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

## 2. For bedrock itself: the template flag

On the template repository: **Settings → General → Template repository**, ticked. GitHub's *Use
this template* button and `gh repo create --template` (what `scripts/new_project.sh` runs) need it.

## What these settings do not change

The spine's checks run identically without them — locally through the hooks and in CI per commit.
The settings turn "the build is red" into "it cannot merge". Nothing here affects licence, name
or release clearance (`VISIBILITY.md`).
