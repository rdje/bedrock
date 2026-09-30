#!/usr/bin/env bash
# scripts/check_doctrines.project.sh — THE PROJECT-SPECIFIC DOCTRINE SLOT.
# SPDX-License-Identifier: LGPL-2.1-or-later
#
# This is where a project instantiated from the template adds ITS OWN mechanizable doctrine
# checks: its build gates, format checks, invariant proofs, source-of-truth rules.
#
# It runs LAST in scripts/check_doctrines.sh, through bash (its executable bit does not matter).
# Exit 0 = every project doctrine holds; 1 (with a message on stderr) = a breach that blocks the
# commit; 2 = cannot evaluate (REFUSED — the driver fails on it; never report green on an error).
#
# The template ships this as a passing no-op. Add checks below as your project grows; keep each
# cheap, deterministic, and self-describing. Read the change through scripts/lib/spine.sh so a
# check judges the index or the commit, never the worktree. For anything heavier than a few
# seconds, gate it in CI instead and keep this hook fast.
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib/spine.sh"; spine_init PROJECT-SPECIFIC

# --- add project-specific checks here ---
# Example — a formatter gate over the source files this change touches:
#   if spine_changed_paths | grep -qE '\.py$'; then
#     for f in $(spine_changed_paths | grep -E '\.py$'); do
#       spine_read "$f" | black --check -q - 2>/dev/null || { spine_fail "$f is not formatted (black)"; exit 1; }
#     done
#   fi

exit 0
