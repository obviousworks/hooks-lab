#!/usr/bin/env bash
#
# break-lint.sh: introduce one deterministic lint error.
#
# For provoking the commit gate without asking an agent to write bad code on
# purpose. It adds a separate throwaway file rather than editing real source, so
# undoing it is a delete and never depends on git.
#
# Undo with scripts/reset-lab.sh, or just delete the file it names.
set -uo pipefail

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TARGET="src/_lint_break.js"

cat > "$TARGET" <<'EOF'
// Throwaway file created by scripts/break-lint.sh.
// It exists to make the linter fail on demand. Delete it, or run
// scripts/reset-lab.sh, and the linter goes green again.

export function brokenHelper(value) {
  var unusedLabel = "this violates no-var and no-unused-vars";
  return value;
}
EOF

echo "Created $TARGET. The linter should now be red:"
npm run --silent lint 2>&1 | tail -8 || true
echo
echo "Undo with: scripts/reset-lab.sh   (or: rm $TARGET)"
