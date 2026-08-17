## Which of my hooks prevent, and which only detect

## What I predicted wrong in Task B

## The bypass I found, and what closes it

## Evidence

Tool-use log lines:
```
```

First `ls` output (Task D):
```
```

Second `ls` output (Task D):
```
```

Refusal from own codebase (Task E step 4):
```
```

Agent's reaction to lint gate:
```
```

## Success Criteria

- [ ] You can name, from your own raw log, the exact field for the tool name and where content sits for `Write` versus `Edit`
- [ ] The raw dump was deleted and `.agent-logs/` is gitignored
- [ ] The Task B table has predictions filled in **before** the observations, all seven rows
- [ ] You can explain what happens to stderr on exit 0, and why that matters for a warning hook
- [ ] You can state what happens when a `PreToolUse` hook hangs, and how that differs from a crash
- [ ] Five hooks exist in `.claude/settings.json`, committed, and `/hooks` shows all five
- [ ] Every hook was provoked with a test that would have been safe if the hook had failed, and the log line is in the pull request
- [ ] Every deny message is written for the model and names an alternative
- [ ] The secret scanner was demonstrably too late on `PostToolUse`, and the file does not exist after the move to `PreToolUse`
- [ ] One bypass of the command deny is documented, plus a `permissions.deny` entry or server-side control that closes it
- [ ] The lint feedback reached the agent, and the agent's reaction is documented, whether it repaired the code or not
- [ ] The commit gate refused a commit on **your own** codebase, with the refusal text quoted
- [ ] `docs/agents/hooks.md` exists, prevention and detection labelled correctly, `Verified` dates filled
- [ ] The Trifecta audit names one real weakness in your own setup and one measure

---

Paste text, not screenshots.
