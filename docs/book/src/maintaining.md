# Maintaining and extending bedrock

This chapter is for whoever works on bedrock itself, person or agent. The complete guide is
`MAINTAINING.md` at bedrock's root; it is the first thing to read, and it is removed from every
project created from the template. What follows is the orientation.

## Where things are

| Piece | Where | Read this first |
| --- | --- | --- |
| the contract | four decision records under `docs/decisions/` | neutral spine and packs; ownership; the updater's classes; the licence |
| the architecture in one screen | `MAINTAINING.md` | the library, the driver, the contract, the seams, the manifest, the updater, the packs, the setup, the suite, the hand-off |
| the recipes | `MAINTAINING.md` | add a doctrine, add a pack, add a migration, cut a release, port an improvement, run everything |
| the admission test | `MAINTAINING.md` | Q0, the pack gate; Q1, value for any project on day one; Q2, no domain nouns |
| the backlog | `docs/tasks/BEDROCK-MAINTENANCE.md`, leaf `.4` | ranked candidates for the next enhancement |
| the review that shaped 1.0 | `docs/reviews/2026-09-30-consolidated-review.md` | every item is cited by id in the tree that closed it |

## The regression harness

`scripts/tests/spine_tests.sh` is how a change to bedrock is proven. It builds children from the
working tree the way a user would (no pack, each pack, the guided questions, `new_project.sh`,
children from old bedrock versions upgraded), and runs every scenario as an arm with an expected
outcome. An arm that a change breaks fails the run; an arm registered as "expected to fail"
that starts passing fails the run too, so the list of open items is kept honest by execution.
Run it under bash 5 and under stock bash 3.2 (`/bin/bash` on a Mac); CI runs it on Linux and
macOS.

```bash
scripts/tests/spine_tests.sh              # everything, about five minutes
scripts/tests/spine_tests.sh --list       # the arms and their expectation
scripts/tests/spine_tests.sh --only <arm> # one arm, its child kept for inspection
```

## Adding something, in short

1. Open a leaf under `BEDROCK-MAINTENANCE`.
2. Pass the admission test. If the thing names a language, a tool or a harness, it is a pack.
3. Write it with the library; add its `--self-test`; register it; mirror it in
   `DOCTRINE_ENFORCEMENT.md`; classify it in `.bedrock/manifest`; add suite arms; name it in this
   guide (the `BOOK-COVERAGE` gate insists); ship a migration if it changes the shape of what
   older templates created.
4. Suite green under both bashes; `scripts/gate`; `scripts/handoff`.
5. Bump `DOCTRINE_VERSION`; write the changelog entry with its "for existing children" paragraph;
   push; watch the GitHub run; tag.

The first push of 1.0.0 was red for two reasons no local run could show, so the last step is
not optional: a change to bedrock's CI is verified on GitHub.

## Transfer runs both ways

A project that hardens a check sends the improvement back: neutralised, with its own arm, under a
maintenance leaf. A raw diff between a project's copy and bedrock's is not the trigger, because
the two are meant to differ; a comparison of *behaviour* on one fixture is.
