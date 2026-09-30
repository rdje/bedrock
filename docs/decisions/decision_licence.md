# Licence: the spine is LGPL-2.1-or-later; seed files are 0BSD; a child's own work is its own

- **Type:** `decision`
- **Date:** `2026-09-30`
- **Status:** `active`
- **Owner / source:** maintainer instruction 2026-09-30 (*"the same type of licence as FFmpeg or
  QEMU … people shall be able to use the project but of course keep the copyright"*), review
  item BR-20

## The fact / decision

- The spine (scripts, hooks, checks, workflows, doctrine documents, templates) is licensed under
  the **GNU Lesser General Public License v2.1 or later** (`LICENSE`), the licence FFmpeg uses by
  default. Anyone may use it in any project, including closed-source ones; modified spine files
  must stay under the same licence and keep the copyright notices.
- **Seed files** (content the template creates for the child to own and rewrite) are provided
  under **0BSD**, so a child can keep, change or relicense them without obligation.
- **A child project's own code and content are not covered.** The licensor states that governing
  a project with the spine does not make the project a derivative work of the spine (`NOTICE`).
- A file's class (spine, seed-once, project-owned) is the manifest's class; the licence follows
  the class. Undeclared files are spine files.

## Why

The tree declared `MIT OR Apache-2.0` in Cargo metadata and shipped no licence file, so the
grant was undefined (BR-20). The maintainer's intent is copyleft on the spine with free use of
the projects built on it. LGPL 2.1+ is the less restrictive of the two named models (QEMU is
GPL-2.0) and matches "usable by anyone, copyright kept". A template needs the extra rule about
seed files and children because the spine is copied into every child rather than linked.

## How to apply

- New spine scripts carry `SPDX-License-Identifier: LGPL-2.1-or-later` in their header.
- Pack starter files (the Rust crate, the mdBook skeleton) are seed files; their manifests do not
  declare a licence on the child's behalf.
- Bootstrap keeps `LICENSE` and `NOTICE` in the child, because the spine files it copies are
  covered by them; the child adds its own licence for its own work.
- Related: [[decision_neutral_spine_and_packs]].
