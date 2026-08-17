# Hooks Lab

Reference repository for the use case **Hooks: Determinism Instead of Trust**
(Pillar 7, Security and Hooks).

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
| `.github/hooks/` | **empty. Your Copilot hooks go here** |
| `.claude/hooks/` | **empty. Your Claude Code hooks go here** |
| `test/fixtures/` | recorded hook payloads for both tools |
| `scripts/verify-hooks.sh` | fires every hook you wrote, without spending an agent turn |
| `scripts/break-lint.sh` | introduces one lint error on purpose |
| `scripts/reset-lab.sh` | puts the working tree back to a known state |
| `docs/agents/hooks.md.template` | the hook register you fill in for Task F |
| `tmp/hook-delete-test/` | a folder that exists to be deleted at |
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
scripts/verify-hooks.sh copilot     # reads .github/hooks/
scripts/verify-hooks.sh claude      # reads .claude/hooks/
```

It feeds recorded payloads into your scripts and checks what came back: did it
block, did it stay quiet, did the agent get a reason it can act on. Eighteen
checks per track.

Four results, and only one of them is bad news:

| | Meaning |
|---|---|
| `PASS` | the hook did what a hook of that kind should do |
| `FAIL` | fix this. The line underneath says what went wrong |
| `OPEN` | it works, and there is a sharper version. Bring it to the weekly |
| `SKIP` | that hook does not exist yet. Expected until you write it |

Two things it deliberately does not do.

It does not prove your JSON configuration is right. Event names, matchers and
timeouts are only proven by a real session, so provoke your hooks there as well.

It does not treat every failure as a bug. One check expects a bypass to succeed,
because that bypass is real and Task C is about finding it.

---

## Safety rules for this lab

1. **Everything you break, you break here.** Nothing in Tasks A to F touches a
   customer or production repository. One step in Task E asks you to port a
   single hook to your own codebase; that one is read-and-refuse, and it changes
   nothing.
2. **A failed security experiment must still be safe.** Test the push rule with
   `git push --dry-run`, never a real push. Test the delete rule against
   `tmp/hook-delete-test/`, never a real directory. If your hook is broken,
   the experiment should be boring rather than expensive.
3. **The credentials are fake and stay fake.** Never put a real value in `.env`
   here, not even briefly, not even to see whether the scanner catches it. The
   scanner does not care whether the value is real.
4. **`.agent-logs/` is gitignored for a reason.** A raw hook payload can contain
   file contents, command arguments and tool output. Delete the raw dump when
   Task A is done.

---

## How to submit your work

This repository is a template. Click **"Use this template"** to create your own copy.

**⚠️ Your copy must be private.** The Trifecta audit in Task F names real security weaknesses in your own working environment. A private repository keeps them there. If you accidentally make your copy public, delete it immediately and create a new one.

Clone your private copy, work on a branch, and open a PR against your own `main` when you are done. Bring the PR link to the weekly.

---

## Resetting

```bash
scripts/reset-lab.sh
```

Removes lab scratch files, restores `src/` from git, recreates the throwaway
folder and the `.env`, and tells you whether the linter is green again. It does
not touch your hooks or your configuration.

---

## Troubleshooting

- npm run lint fails immediately after cloning
  - Run `npm install` and copy `.env` from `.env.demo` (`cp .env.demo .env`). The linter needs a clean baseline.

- `jq: command not found`
  - Install `jq`: `brew install jq` / `sudo apt install jq` / `winget install jqlang.jq`.

- The `.env` file is missing
  - Copy `.env.demo` to `.env`. Never put real secrets here; the file is gitignored.


## If something is wrong with the repository itself

Say so in the weekly rather than working around it. A broken baseline wastes
everybody's afternoon, and it has usually broken for all twelve of you.
