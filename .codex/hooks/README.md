# Your Codex hook scripts go here

Empty on purpose. The use case fills it.

The scripts live here, the wiring lives in `.codex/hooks.json` one level up.
Codex runs a hook only after you have reviewed and trusted it in `/hooks`, and
it skips a new or changed hook until you trust it again. Project hooks load only
when you trust the project.

Verify what you build with:

```bash
scripts/verify-hooks.sh codex
```
