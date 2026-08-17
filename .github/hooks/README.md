# Your Copilot CLI hooks go here

Empty on purpose. Task A onwards fills it.

Copilot loads every `*.json` file in this directory, plus the scripts they point
at. The same files drive the Copilot cloud agent once they are on the default
branch, which is the reason this lives in the repository rather than in
`~/.copilot/hooks/`.

Verify what you build with:

```bash
scripts/verify-hooks.sh copilot
```
