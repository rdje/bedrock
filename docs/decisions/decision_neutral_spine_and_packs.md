# The spine is project-, harness- and language-neutral; everything else is a pack

- **Type:** `decision`
- **Date:** `2026-09-30`
- **Status:** `active`
- **Owner / source:** maintainer contract stated 2026-09-30 and decisions granted the same day
  (review `docs/reviews/2026-09-30-consolidated-review.md`, items NT-01 to NT-14, BR-19, BR-13)

## The fact / decision

bedrock must be usable by **any project, in any language, driven by any harness or by a
human**. Therefore:

1. **The default child contains no language, no docs tool and no harness file.** Rust, mdBook
   and the `Makefile` leave the spine and become opt-in packs under `packs/` (`packs/lang/rust`,
   `packs/docs/mdbook`, `packs/harness/<name>`). A pack is copied into a child only when
   selected at bootstrap (or added later); unselected packs are **not** copied, so a child
   carries no inactive payload.
2. **`AGENTS.md` is the canonical, complete agent instruction file and the only required one.**
   A harness file such as `CLAUDE.md` is an optional adapter that only points at `AGENTS.md`.
   No check may name a vendor file as mandatory.
3. **Spine logic may not name a language, a build tool, a docs tool or a harness.** Such
   knowledge is data a pack or the project declares under `.doctrine/` (commands, evidence
   signatures, agent identities, hand-off exclusions), never a branch in a check.
4. **The admission test has three axes.** Before Q1 in `MAINTAINING.md`: *does its logic name a
   language, tool or harness? Then it belongs in a pack, not the spine.* Q1 itself reads: *would
   it help a new project in any language, driven by any harness or by a human, on day one?*

## Why

The reviewed tree (`bedrock-scaffold 0.6.1`, re-verified at 0.10.0) shipped a Rust project to
every child, classified code by Rust paths so Dart, Perl and Julia sources passed the ownership
gates with no leaf, matched test output of no ecosystem but Rust, and required `CLAUDE.md`.
Each of those is a gate reporting success without judging the change, in every non-Rust child.
The contract the maintainer stated makes those correctness defects, not packaging choices.

## How to apply

- A new doctrine or file first answers the pack gate above; anything language-, tool- or
  harness-shaped goes under `packs/` with its own install hook, commands, evidence tokens and
  CI workflow.
- Bootstrap records the selected packs in `.bedrock/project`; the updater refreshes the spine
  plus the installed packs only.
- Neutrality is tested mechanically in bedrock's CI: a lint over spine logic lines, and a
  generation matrix (no pack, each pack, each harness adapter) that bootstraps, commits, and
  refuses an unowned change in the pack's own language.
- Related: [[decision_ownership_contract]], [[decision_licence]], [[reference_bedrock_provenance]].
