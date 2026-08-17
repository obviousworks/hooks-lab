#!/usr/bin/env bash
#
# verify-hooks.sh: provoke every hook without spending an agent turn.
#
# Feeds recorded payloads into your hook scripts and checks what they do.
# A hook that has never fired is a wish, not a control, and this is the cheap
# way to fire all of them.
#
# Usage:
#   scripts/verify-hooks.sh copilot [hooks-dir]     default dir: .github/hooks
#   scripts/verify-hooks.sh claude  [hooks-dir]     default dir: .claude/hooks
#
# What this does NOT prove: that your JSON config wires the hook to the right
# event with the right matcher. Only a real session proves that. This checks the
# script logic, which is where most of the mistakes are.
#
set -uo pipefail

TRACK="${1:-}"
case "$TRACK" in
  copilot) HOOKS_DIR="${2:-.github/hooks}" ;;
  claude)  HOOKS_DIR="${2:-.claude/hooks}" ;;
  *) echo "usage: $0 {copilot|claude} [hooks-dir]" >&2; exit 64 ;;
esac

FIX="test/fixtures/$TRACK"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [ ! -d "$FIX" ]; then
  echo "Fixtures not found at $FIX. Run this from the repository root." >&2
  exit 66
fi

PASS=0; FAIL=0; SKIP=0; OPEN=0
BONUS_NOTE=""
RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; DIM=$'\033[2m'; OFF=$'\033[0m'
[ -t 1 ] || { RED=""; GREEN=""; YELLOW=""; DIM=""; OFF=""; }

WORK="$(mktemp -d)"
LINT_SCRATCH="src/_verify_lintfail.js"
cleanup() {
  rm -rf "$WORK"
  rm -f tmp/verify-secret.json "$LINT_SCRATCH"
}
trap cleanup EXIT

# --- scratch files the fixtures point at -----------------------------------
# The secret file exists so the deliberately-too-late post-tool scanner has
# something on disk to find. The lint file lives under src/ because that is
# what eslint.config.js covers, and it is removed again on exit.
mkdir -p tmp .agent-logs
printf '{ "apiKey": "DEMOSECRET_AAAAAAAAAAAAAAAA" }\n' > tmp/verify-secret.json
printf 'var unusedThing = 1;\n' > "$LINT_SCRATCH"

# A hook may write its log wherever it likes. Watch both the sandbox path this
# script suggests and the default one the use case hard-codes.
log_bytes() {
  local a=0 b=0
  [ -f "$WORK/logs/tool-use.log" ] && a=$(wc -c < "$WORK/logs/tool-use.log")
  [ -f ".agent-logs/tool-use.log" ] && b=$(wc -c < ".agent-logs/tool-use.log")
  echo $((a + b))
}
LOG_BEFORE=$(log_bytes)

blocked() {
  # $1 = exit code, $2 = stdout file, $3 = stderr file
  #
  # A block counts only if the agent also learns why. A bare exit code stops the
  # call and leaves the model to guess, which usually means it tries the same
  # idea again in a different shape.
  local code="$1" out="$2" err="$3"
  if [ "$TRACK" = "claude" ]; then
    [ "$code" -eq 2 ] && [ -s "$err" ]
  else
    jq -e '.permissionDecision == "deny" and (.permissionDecisionReason | type == "string" and length > 10)' \
      "$out" >/dev/null 2>&1
  fi
}

has_feedback() {
  local code="$1" out="$2" err="$3"
  if [ "$TRACK" = "claude" ]; then
    [ "$code" -eq 2 ] && [ -s "$err" ]
  else
    jq -e '.additionalContext != null' "$out" >/dev/null 2>&1
  fi
}

valid_output() {
  # Copilot parses stdout as JSON. Empty is fine; anything else must parse.
  local out="$1"
  [ "$TRACK" != "copilot" ] && return 0
  [ -s "$out" ] || return 0
  jq -e . "$out" >/dev/null 2>&1
}

run_case() {
  local hook="$1" fixture="$2" expect="$3" label="$4"
  local script="$HOOKS_DIR/$hook"

  if [ ! -x "$script" ]; then
    if [ -f "$script" ]; then
      printf '%s SKIP %s %s (not executable: chmod +x %s)\n' "$YELLOW" "$OFF" "$label" "$script"
    else
      printf '%s SKIP %s %s %s(%s not found)%s\n' "$YELLOW" "$OFF" "$label" "$DIM" "$script" "$OFF"
    fi
    SKIP=$((SKIP+1)); return
  fi

  local out="$WORK/out" err="$WORK/err" code=0
  HOOKS_LAB_LOG_DIR="$WORK/logs" "$script" < "$FIX/$fixture" > "$out" 2> "$err" || code=$?

  local ok=1 why=""

  if ! valid_output "$out"; then
    ok=0; why="stdout is not valid JSON (Copilot discards the whole output)"
  else
    case "$expect" in
      block)
        if ! blocked "$code" "$out" "$err"; then
          ok=0
          if [ "$TRACK" = "copilot" ] && [ "$code" -eq 2 ]; then
            why="it blocks, but with no reason the agent can read. Exit 0 and return permissionDecision plus permissionDecisionReason instead"
          elif [ "$TRACK" = "copilot" ] && jq -e '.permissionDecision == "deny"' "$out" >/dev/null 2>&1; then
            why="deny returned without a usable permissionDecisionReason"
          elif [ "$TRACK" = "claude" ] && [ "$code" -eq 2 ]; then
            why="it blocks, but stderr is empty, so Claude is told nothing. Write the reason to stderr before exit 2"
          else
            why="expected a block, got exit $code and no deny decision"
          fi
        fi ;;
      pass)
        if blocked "$code" "$out" "$err"; then ok=0; why="expected it to pass, got a block"; fi
        if [ "$code" -ne 0 ] && [ "$code" -ne 2 ]; then ok=0; why="unexpected exit $code"; fi ;;
      feedback)
        has_feedback "$code" "$out" "$err" || { ok=0; why="expected feedback to the model, found none"; } ;;
      quiet)
        if has_feedback "$code" "$out" "$err"; then ok=0; why="expected silence, got feedback"; fi ;;
      log)
        if [ "$(log_bytes)" -le "$LOG_BEFORE" ]; then
          ok=0
          why="no log line was written. Check the directory exists: a hook that appends to .agent-logs/ fails silently after a reset unless it runs mkdir -p first"
        fi ;;
      bonus)
        if ! blocked "$code" "$out" "$err"; then
          ok=2
        fi ;;
    esac
  fi

  if [ "$ok" -eq 2 ]; then
    printf '%s OPEN %s %s\n        %s%s%s\n' "$YELLOW" "$OFF" "$label" "$DIM" "$BONUS_NOTE" "$OFF"
    OPEN=$((OPEN+1))
  elif [ "$ok" -eq 1 ]; then
    printf '%s PASS %s %s\n' "$GREEN" "$OFF" "$label"
    PASS=$((PASS+1))
  else
    printf '%s FAIL %s %s\n        %s%s%s\n' "$RED" "$OFF" "$label" "$DIM" "$why" "$OFF"
    [ -s "$err" ] && printf '        %sstderr: %s%s\n' "$DIM" "$(head -c 200 "$err" | tr '\n' ' ')" "$OFF"
    [ -s "$out" ] && printf '        %sstdout: %s%s\n' "$DIM" "$(head -c 200 "$out" | tr '\n' ' ')" "$OFF"
    FAIL=$((FAIL+1))
  fi
}

echo
echo "Track: $TRACK    Hooks: $HOOKS_DIR"
echo

echo "1. log-tool-use: writes a line, blocks nothing"
run_case log-tool-use.sh post-bash-any.json log   "writes a log line for a shell call"
run_case log-tool-use.sh post-bash-any.json pass  "never blocks"

echo
echo "2. deny-dangerous: prevention"
run_case deny-dangerous.sh pre-bash-rm.json        block "refuses rm -rf"
run_case deny-dangerous.sh pre-bash-push-main.json block "refuses a push to main"
run_case deny-dangerous.sh pre-bash-safe.json      pass  "lets npm test through"
run_case deny-dangerous.sh pre-create-secret.json  pass  "ignores calls with no command"

echo
echo "3. scan-secrets: prevention, and the known-too-late version"
run_case scan-secrets.sh pre-create-secret.json        block "refuses a secret in file content"
run_case scan-secrets.sh pre-bash-heredoc-secret.json  block "refuses a secret written by heredoc"
BONUS_NOTE="Not a failure. Your hook names the keys it expects, which is what Task A teaches. Ask in the weekly what happens when a tool renames one."
run_case scan-secrets.sh pre-create-unknown-key.json   bonus "catches a secret under an unexpected key name"
BONUS_NOTE=""
run_case scan-secrets.sh pre-create-clean.json         pass  "lets a placeholder through"
run_case scan-secrets-post.sh post-create-secret.json  feedback "post version only reports, after the fact"

echo
echo "4. lint gate: feedback and enforcement"
run_case lint-feedback.sh    post-edit-lintfail.json feedback "sends lint errors to the model"
run_case lint-feedback.sh    post-edit-clean.json    quiet    "stays silent on clean code"
run_case lint-feedback.sh    post-bash-any.json      quiet    "ignores non-source tools"
run_case lint-commit-gate.sh pre-bash-safe.json      pass     "ignores anything that is not a commit"
run_case lint-commit-gate.sh pre-bash-commit.json    block    "refuses a commit while the linter is red"

# Same gate, same fixture, clean tree. If this one blocks too, the gate is not
# reading the linter, it is just always saying no.
rm -f "$LINT_SCRATCH"
run_case lint-commit-gate.sh pre-bash-commit.json    pass     "allows the same commit once the linter is green"

echo
echo "5. documented bypass: this SHOULD pass, that is the point"
run_case deny-dangerous.sh pre-bash-bypass.json pass "rm -r -f still gets through (known, see hooks.md)"

echo
printf 'passed %s   failed %s   open %s   skipped %s\n' "$PASS" "$FAIL" "$OPEN" "$SKIP"
echo
if [ "$FAIL" -gt 0 ]; then
  echo "A failure here is information, not a verdict. Read the hook, fix it, run again."
  exit 1
fi
if [ "$SKIP" -gt 0 ] && [ "$PASS" -eq 0 ]; then
  echo "Nothing ran. Check that your hooks are in $HOOKS_DIR and executable."
  exit 1
fi
echo "This checks script logic only. Your JSON config, event names and matchers"
echo "are only proven by a real session. Go provoke them there too."
