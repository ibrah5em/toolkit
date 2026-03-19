# Contributing

Thanks for your interest in contributing! Here's how to get started.

## Adding a New Script

1. Read [`docs/AUTHORING.md`](docs/AUTHORING.md) — it covers every convention
2. Use the boilerplate:
   ```bash
   #!/usr/bin/env bash
   # =====================================================
   # Script Name - Short description
   # =====================================================

   _SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
   _TOOLKIT_DIR="$(dirname "${_SCRIPT_DIR}")"
   source "${_TOOLKIT_DIR}/lib/config.sh"
   source "${_TOOLKIT_DIR}/lib/ui.sh"
   source "${_TOOLKIT_DIR}/lib/utils.sh"
   ```
3. Place it in the right category folder (`system/`, `dev/`, `general/`, or `net/`)
4. Make it executable: `chmod +x your-script.sh`
5. Test it: `tool your-script`

## Rules

- **No emojis** — use `$NF_*` Nerd Font icon variables from `lib/ui.sh`
- **No raw ANSI codes** — use the color variables from `lib/colors.sh`
- **No hardcoded paths** — use `$HOME`, `$SCRIPTS_DIR`, config variables
- **Use status functions** — `print_success`, `print_error`, not raw `echo`
- **Include a help menu** if the script has multiple subcommands
- **Check dependencies** with `require_command` before using external tools

## Submitting

1. Fork the repo
2. Create a branch: `git checkout -b add-my-script`
3. Commit with a clear message: `git commit -m "Add network-speed script"`
4. Open a PR with a short description of what the script does

## Improving Existing Scripts

Bug fixes, better error handling, new subcommands — all welcome. Just explain what changed and why in the PR.

## Improving the Library

Changes to `lib/` affect every script, so be careful. If you're adding a new icon, utility function, or color variable, make sure the naming is consistent with what's already there.
