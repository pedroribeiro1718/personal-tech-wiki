---
name: playwright-cli
description: Inspect and test browser behavior with the installed Playwright CLI.
allowed-tools: Bash(playwright-cli:*)
---

# Playwright CLI

Read [the pinned upstream CLI guide](references/cli.md) for full usage and the
other files under `references/` for specialized workflows.

Common shapes:

```text
playwright-cli open URL
playwright-cli snapshot [TARGET]
playwright-cli fill TARGET TEXT
playwright-cli click TARGET
playwright-cli press KEY
playwright-cli console [LEVEL]
playwright-cli run-code 'async page => { ... }'
playwright-cli close
```

`TARGET` is a snapshot ref (`e7`), CSS selector, or Playwright locator such as
`getByRole('button', { name: 'Login' })`; it is not snapshot prose such as
`textbox "User Name"`. `fill` focuses its target, and `press` accepts only a key.

Prefer direct commands. Use `run-code` only when they cannot express the check.
Close the browser when finished. Do not use `npx`, installers, or helper scripts.
Do not repeat a submitted action because later evidence collection failed.
