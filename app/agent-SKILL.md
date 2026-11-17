---
name: omadials-settings
description: Inspect omadials settings through the standalone app without a display.
---

Use `omadials-settings check --json` to validate the current user's config with the shared plugin schema. Exit 0 means no problems. Exit 1 provides JSON errors and a message on stderr. This command does not write the config.

Use `omadials-settings open` for the graphical editor. Every edit applies immediately. The GUI offers Undo for 10 seconds, config error reporting, plugin status and Show on screen.

The config contract is `~/.config/omadials/config.json`. Preserve unknown keys. Never repair malformed JSON, downgrade a newer version or reset settings without explicit user instructions. Use a temporary HOME for tests. Status uses the read-only command `omarchy-shell omadials status`. Show on screen runs `omarchy-shell omadials open` and should only be used when the user wants the corner opened.
