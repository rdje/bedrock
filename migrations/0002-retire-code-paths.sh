#!/usr/bin/env bash
# migration 0002 — retire .doctrine/code_paths.txt: governance is deny-by-default (REVIEW-2026-09.4).
# since: 0.14.0
# SPDX-License-Identifier: LGPL-2.1-or-later
# The old allow-list is kept as a comment inside docs_paths.txt so nothing the project wrote is lost;
# what it listed as CODE is governed anyway, and only DOCUMENTATION needs declaring now.
set -uo pipefail
if [ -f .doctrine/code_paths.txt ]; then
  mkdir -p .doctrine
  [ -f .doctrine/docs_paths.txt ] || printf '# .doctrine/docs_paths.txt — extra DOCUMENTATION paths, one extended regular expression per line.\n' > .doctrine/docs_paths.txt
  { echo "# migration 0002: the retired .doctrine/code_paths.txt read (code is governed by default; declare DOCUMENTATION here):"
    sed 's/^/#   /' .doctrine/code_paths.txt; } >> .doctrine/docs_paths.txt
  git rm -q --cached .doctrine/code_paths.txt 2>/dev/null; rm -f .doctrine/code_paths.txt
  echo "migration 0002: .doctrine/code_paths.txt retired (its content is kept as a comment in .doctrine/docs_paths.txt)"
else
  echo "migration 0002: nothing to do"
fi
