## Which of my hooks prevent, and which only detect

## Which hook turned out weaker than I predicted

## The bypass I could only close outside the hook

## Evidence

Tool, version and platform ("Before you start"):
```
```

The seven normaliser probe results (Task A):
```
```

Lines from `.agent-logs/tool-use.log`:
```
```

Refusals from Task C, and what the control outside the hook did:
```
```

The agent's reaction to the commit gate (Task D):
```
```

Refusal from my own codebase (Task D, step 4):
```
```

## Success criteria

- [ ] "Before you start" output in the PR: tool, version, platform
- [ ] I can say in which shape my tool sends tool arguments, from my own log
- [ ] My normaliser returns a command for the four valid probes and refuses the three invalid ones with a reason
- [ ] Task B part 1 has predictions written **before** observations, all eight rows
- [ ] I can state what my tool does when a hook hangs, and how that differs from a crash
- [ ] My Task B part 2 table says whether my gate ran without a human
- [ ] At least two bypasses documented, one of them a route the agent chose while keeping the rule
- [ ] One bypass was addressed by a control outside the hook, with the result recorded, including any way around it I found
- [ ] The agent's reaction to the commit gate is recorded as one of the four outcomes, and the gate refused a commit in my own codebase
- [ ] `docs/agents/hooks.md` exists with `Verified` dates, and my Trifecta audit names one weakness and one measure

---

Text, not screenshots.
