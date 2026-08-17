## Which of my hooks prevent, and which only detect

## What I predicted wrong in Task B

## The bypass I found, and what closes it

## Evidence

Preflight output (copilot --version, platform, etc):
```
```

Tool-use log lines:
```
```

Both `ls` outputs from Task D (before and after):
```
```

Refusal from own codebase (Task E step 4):
```
```

Agent's reaction to lint gate:
```
```

## Success Criteria

- [ ] Preflight output in the PR: CLI version, platform, route
- [ ] You can say whether `toolArgs` is an object or a string in your setup, from your own log
- [ ] Your normaliser handles all six probe shapes, and the three invalid ones produce a deny with a reason rather than silence
- [ ] Every hook that inspects tool arguments uses the normalised `$args`. Stable top-level metadata such as `toolName` may be read directly
- [ ] Task B part 1 has predictions written **before** observations, all eight rows
- [ ] You can state what happens when a hook hangs, and how that differs from a crash
- [ ] Five hooks exist, committed, and none mixes the two payload formats
- [ ] Every hook was provoked with a test that would have been safe if the hook had failed
- [ ] Your deny hooks return a reason the agent can act on, not a bare exit code
- [ ] The secret scanner was demonstrably too late on `postToolUse`, and the file does not exist after the move
- [ ] At least two bypasses documented, one of them a route the agent chose while honouring the rule
- [ ] One bypass was addressed one rung up, with the result recorded
- [ ] The lint feedback reached the agent and its reaction is documented, repaired or not
- [ ] The commit gate refused a commit on **your own** codebase, refusal text quoted
- [ ] `docs/agents/hooks.md` exists, prevention and detection labelled correctly, `Verified` dates filled

---

Text, not screenshots.
