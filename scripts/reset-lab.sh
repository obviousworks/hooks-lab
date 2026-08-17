#!/usr/bin/env bash
#
# reset-lab.sh: put the working tree back to a known state.
#
# Use it between attempts, or after an experiment leaves the repository dirty.
# It touches lab scratch state only. Your hooks and your configuration are left
# exactly as they are.
#
# It does not need a git repository. Everything it undoes is a file it can
# delete, which is deliberate: the lab is often used from an extracted archive
# with no history to restore from.
set -uo pipefail

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Resetting lab state..."

rm -f config/local.json        && echo "  removed config/local.json"
rm -f docs/build-context.md    && echo "  removed docs/build-context.md"
rm -f src/_lint_break.js       && echo "  removed the break-lint file"
rm -f src/_verify_lintfail.js  && echo "  removed the verify scratch file"

rm -rf .agent-logs && mkdir -p .agent-logs && chmod 700 .agent-logs \
  && echo "  emptied .agent-logs/ (directory kept)"

mkdir -p tmp/hook-delete-test
printf 'This file exists so you have something safe to try to delete.\n' \
  > tmp/hook-delete-test/do-not-care.txt
echo "  recreated tmp/hook-delete-test/"

if [ ! -f .env ]; then
  cp .env.demo .env
  echo "  recreated .env from .env.demo (fake values)"
fi

# Older versions of break-lint.sh appended to src/format.js, which could not be
# undone without git. Repair that here so an affected clone heals itself.
if grep -q "^export function debugItem" src/format.js 2>/dev/null; then
  python3 - <<'PY' 2>/dev/null || sed -i '/^export function debugItem/,$d' src/format.js
import pathlib
p = pathlib.Path("src/format.js")
s = p.read_text()
i = s.find("\nexport function debugItem")
if i != -1:
    p.write_text(s[:i].rstrip() + "\n")
PY
  echo "  repaired src/format.js (leftover from an older break-lint.sh)"
fi

if npm run --silent lint >/dev/null 2>&1; then
  echo "  linter is green"
else
  echo
  echo "  The linter is still red after the reset. That is not normal."
  echo "  Something outside lab scratch state was changed. Run 'npm run lint'"
  echo "  to see which file, and restore it from git or from a fresh extract."
  npm run --silent lint 2>&1 | tail -8
  exit 1
fi

echo "Done."
