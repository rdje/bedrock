# Ownership contract: a leaf owns a commit only if the evidence for that commit is in it

- **Type:** `decision`
- **Date:** `2026-09-30`
- **Status:** `active`
- **Owner / source:** granted by the maintainer 2026-09-30 on the recommendation in the review
  (`docs/reviews/2026-09-30-consolidated-review.md` §6, items BK-01, BK-03, BK-05, BK-06,
  BK-08, BR-02, BR-03, BR-04, BR-08)

## The fact / decision

1. **Governed change.** Every change is governed except declared documentation
   (deny-by-default). Spine paths are always governed and a project cannot exempt them.
2. **Binding.** A governed commit names exactly one leaf in its subject, `(leaf <ID>)`. That
   leaf exists in a top-level `docs/tasks/<TREE>.md`, and its section changes in the same
   commit.
3. **An open leaf may own several commits; a done leaf may own none.** Each commit an open
   leaf owns must add lines to that leaf's section: a commit-log row and the evidence for this
   change. A leaf whose status is `done` with a recorded commit cannot own a new commit; a
   follow-up is a **child leaf** with its own root cause and evidence, never an edit of the
   parent's finished record.
4. **Evidence is new in the commit.** The three hard-gated boxes are ticked, their labels are
   anchored at the start of the box, exactly one per label per leaf, and their evidence lines
   are among the lines the commit adds or modifies. Evidence is a command and its output in a
   code span or fenced block; a bare version number or tool name is not evidence.
5. **Configuration comes from the before-snapshot.** Gate-defining configuration (`.doctrine/`,
   caps) is read from `HEAD` locally and from the parent commit in CI, so a commit cannot loosen
   the gate that judges it. A configuration change takes effect from the next commit and is
   itself governed.
6. **Exceptions are trailers, not environment variables.** `Spine-Exception: <reason>` in the
   commit message is honoured by every check identically, is stored in history, and is listed
   and counted by CI. `SPINE_ALLOW_UNOWNED` is removed.
7. **Errors are refusals.** A check exits 0 (holds), 1 (breach) or 2 (cannot evaluate). The
   driver reports 2 as `REFUSED` and fails. A git failure, a missing dependency, an invalid
   pattern or a lost executable bit never produces a pass.
8. **CI judges every introduced commit** with `before` = its parent and `after` = the commit,
   plus final-tree invariants on the tip. Merge commits are exempt from binding only.

## Why

Before this contract, any old ticked checklist in any staged tree file satisfied the gate for
any new code change (BK-01), the box matcher took the first box mentioning a keyword (BK-03),
the hooks, workflows and gate configuration could be changed with no leaf (BK-05, BK-06), CI ran
the driver on an empty index so eight of thirteen checks passed vacuously (BR-04), and bedrock's
own last fourteen leaves were validated against leaf `.2.4`'s boxes (BK-02). Binding evidence to
the change is the only rule that closes all of these at once.

Why a done leaf cannot own a new commit: the gate can only check what exists at commit time. A
done leaf already carries a ticked checklist, so a later commit naming it is indistinguishable
from yesterday's evidence answering for today's change. An open leaf has no such ambiguity, and
a child leaf keeps the parent's finished record honest.

## How to apply

- Write a leaf's checklist inside the leaf, one per leaf (`docs/tasks/TEMPLATE.md`), with the
  labels `ROOT CAUSE`, `ADDRESSED`, `NO REGRESSION` at the start of each box.
- Cite evidence as `` `command` → `output` ``; use `scripts/evidence -- <command>` for a stamped
  line CI can re-run.
- A follow-up to a done leaf is a new child leaf (`<ID>.<n>`), with the parent's commit named in
  its root cause.
- Related: [[decision_neutral_spine_and_packs]], [[decision_licence]].
