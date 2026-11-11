# Hooks Lab

Reference repository for the use case **Hooks: Determinism Instead of Trust**
(Pillar 7, Security and Hooks), in both versions: the compact version and the
deep dive that builds on it. It works with Claude Code, GitHub Copilot CLI and
OpenAI Codex CLI.

It is a deliberately small shopping-cart module with a configured linter, a few
things that are safe to break, and a set of recorded hook payloads you can test
against. Everything dangerous in this repository is fake.

---

## Before you start

```bash
npm install
cp .env.demo .env
npm run lint      # must be clean, exit 0
```

If `npm run lint` is not clean on a fresh clone, stop and say so in the weekly.
Every task after this one assumes a green baseline.

You also need `jq`:

```bash
brew install jq          # macOS
sudo apt install jq      # Debian, Ubuntu
winget install jqlang.jq # Windows
```

---

## What is where

| Path | What it is |
|---|---|
| `src/` | the code. Cart maths, formatting, composition |
| `eslint.config.js` | five rules, all errors, no warnings. `npm run lint` is your quality gate |
| `AGENTS.md` | repository conventions, including four rules worth testing |
| `.claude/hooks/` | **empty. Your Claude Code hook scripts go here**, the wiring in `.claude/settings.json` |
| `.github/hooks/` | **empty. Your Copilot hook scripts and their `*.json` files go here** |
| `.codex/hooks/` | **empty. Your Codex hook scripts go here**, the wiring in `.codex/hooks.json` |
| `test/fixtures/` | recorded hook payloads for all three tools |
| `scripts/verify-hooks.sh` | fires every hook you wrote, without spending an agent turn |
| `scripts/break-lint.sh` | introduces one lint error on purpose |
| `scripts/reset-lab.sh` | puts the lab scratch state back to a known state |
| `docs/agents/hooks.md.template` | the hook register you fill in during the deep dive |
| `tmp/hook-delete-test/` | a folder that exists to be deleted |
| `.env` | fake credentials, gitignored, shaped like the real thing |

---

## Read `AGENTS.md` first

It contains four rules: no `rm -rf`, no push to main, no credentials in files,
no reading `.env`.

Before you write a single hook, open a session and ask the agent to break one of
them. Note what happens. That measurement is the baseline the whole use case
argues against, and it is more convincing when you took it yourself than when
somebody told you about it.

---

## Verifying your hooks

```bash
scripts/verify-hooks.sh claude      # reads .claude/hooks/
scripts/verify-hooks.sh copilot     # reads .github/hooks/
scripts/verify-hooks.sh codex       # reads .codex/hooks/
```

It feeds recorded payloads into your scripts and checks what came back: did it
block, did it stay quiet, did the agent get a reason it can act on. It looks for
the scripts of both versions by name, about twenty checks per tool:

- compact version: `deny-main-push.sh`, `warn-secret-after.sh`, `block-secret-before.sh`
- deep dive: `log-tool-use.sh`, `deny-dangerous.sh` (with `normalise.sh`), `lint-feedback.sh`, `lint-commit-gate.sh`

Three results:

| | Meaning |
|---|---|
| `PASS` | the hook did what a hook of that kind should do |
| `FAIL` | fix this. The line underneath says what went wrong |
| `SKIP` | that hook does not exist yet. Expected until you write it |

For Copilot, a refusal counts only if the reason is in the JSON on standard
output, because that is where Copilot reads it. For Claude Code and Codex, a
refusal is exit `2` with the reason on standard error.

Two things it deliberately does not do.

It does not prove your configuration is right. Event names, matchers and
timeouts are only proven by a real session, so provoke your hooks there as well.

It does not treat every pass as good news. One check expects a bypass to get
through, because that bypass is real and Task C of the deep dive is about it.

---

## Safety rules for this lab

1. **Everything you break, you break here.** Nothing in this lab touches a
   customer or production repository. One step in the deep dive (Task D, step 4)
   asks you to port the commit gate to your own codebase; that one refuses a
   commit and changes nothing.
2. **A failed security experiment must still be safe.** Test the push rule with
   `git push --dry-run`, never a real push. Test the delete rule against
   `tmp/hook-delete-test/`, never a real directory. If your hook is broken,
   the experiment should be boring rather than expensive.
3. **The credentials are fake and stay fake.** Never put a real value in `.env`
   here, not even briefly, not even to see whether a scanner catches it. The
   scanner does not care whether the value is real.
4. **`.agent-logs/` is gitignored for a reason.** A raw hook payload can contain
   file contents, command arguments and tool output. Delete the raw dump when
   Task A of the deep dive is done.

---

## How to submit your work

This repository is a template. Click **"Use this template"** to create your own copy.

**⚠️ Your copy must be private.** The Lethal Trifecta audit in the deep dive
(Task E) names real security weaknesses in your own working environment. A
private repository keeps them there. If you accidentally make your copy public,
delete it and create a new one.

Clone your private copy, work on a branch, and open a pull request against your
own `main` when you are done. Bring the link to the weekly.

---

## Resetting

```bash
scripts/reset-lab.sh
```

Removes lab scratch files, recreates the throwaway folder and the `.env`, and
tells you whether the linter is green again. It does not need git, and it does
not touch your hooks or your configuration.

---

## If something is wrong with the repository itself

Say so in the weekly rather than working around it. A broken baseline wastes
everybody's afternoon, and it has usually broken for all of you.

---

## Three things that fail silently

No warning in the chat, no error, and the agent carries on.

| Symptom | Cause |
|---|---|
| Nothing happens at all | The script is not executable, or your shell cannot run it. `chmod +x` your hook scripts, then `ls -l`. In Claude Code a script that cannot start lets the call through |
| Your change had no effect | Copilot loads hook files at startup: restart it. Codex skips a changed hook until you trust it again in `/hooks`. Claude Code shows what it loaded in `/hooks` |
| A security hook lets something through | Your parser returned nothing and the hook defaulted to allow. Task A of the deep dive fixes this |

And one thing that is not a failure: **the permission prompt is not your hook.**
"Do you want to run this command?" comes from your tool's permission system and
appears with no hooks installed. If you cancel there, the tool call never starts
and your hook never decides. Answer yes, then watch.

---

## Hooks and git

Hook configuration and hook scripts belong in the repository:
`.claude/settings.json` and `.claude/hooks/`, `.github/hooks/`, `.codex/hooks.json`
and `.codex/hooks/`. They are policy, appear in pull requests, get reviewed, and
apply to every developer. Copilot's cloud agent reads only the hooks in
`.github/hooks/` of the repository.

Of everything around your hooks, only `.agent-logs/` is gitignored. Hook
payloads can contain file contents and tool output, so logs never belong in
git. Configuration, scripts and your evidence are committed. The other entries
in `.gitignore` are dependencies, the fake `.env` and scratch files.

Commit a hook as soon as it works. An untracked script is the first thing a
cleanup removes, and in some tools a hook that is gone, cannot start or crashes
lets every call through without a word. The deep dive measures in Task B what
your tool does in each of these cases.
