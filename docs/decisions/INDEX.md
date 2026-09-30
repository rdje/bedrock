# Decision & Fact Records — Index (memory layer C)

Durable, cross-cutting facts and decisions live here, **one record per file**
(ADR-style). This index is the discoverable entry point: every record must be listed
below (the `MEMORY-ARCH` doctrine check enforces it).

Write a record when you establish something that must survive and is not obvious from the
code or git history: a constraint, a convention, a hard-won learning ("tried X, failed
because Y"), an environment quirk, a user preference, a deliberate trade-off. Convert
relative dates to absolute. Supersede — never silently rewrite — a record that changes;
note the supersession.

New record: copy [`TEMPLATE.md`](TEMPLATE.md) → `<type>_<short-kebab-slug>.md`, fill it in,
and add its row here.

| Record | Type | One-line hook |
| --- | --- | --- |
| [`reference_bedrock_provenance.md`](reference_bedrock_provenance.md) | reference | bedrock is PGEN's neutral spine (PGEN = `../pgen`, a separate repo); the neutral/project-specific boundary + how to transfer general PGEN improvements. See `MAINTAINING.md`. |
| [`decision_neutral_spine_and_packs.md`](decision_neutral_spine_and_packs.md) | decision | the spine is project-, harness- and language-neutral; Rust, mdBook and harness files are opt-in packs; `AGENTS.md` is the only required agent file; the admission test has three axes (2026-09-30) |
| [`decision_ownership_contract.md`](decision_ownership_contract.md) | decision | a leaf owns a commit only if that commit's evidence is in it: deny-by-default governance, leaf bound by the subject, evidence new in the diff, config from the before-snapshot, exceptions as trailers, exit 2 = REFUSED (2026-09-30) |
| [`decision_licence.md`](decision_licence.md) | decision | the spine is LGPL-2.1-or-later (the FFmpeg model); seed files are 0BSD; a child's own work is not covered (2026-09-30) |
