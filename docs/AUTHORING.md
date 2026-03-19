# Script Authoring Guide

> How to write scripts that integrate seamlessly with the toolkit. Follow these conventions for consistent style, icons, colors, and structure.


---

## 1. Environment Overview

- **OS:** Linux (tested on Ubuntu 24.04 LTS and WSL2)
- **Shell:** Scripts written in Bash, compatible with Zsh
- **Terminal font:** A Nerd Font (all Nerd Font glyphs render correctly)
- **Editor:** `$EDITOR` (defaults to nano)
- **Toolkit location:** `~/scripts/` — managed by the `tool` launcher
- **Config file:** `~/scripts/config/toolkit.conf`

---

## 2. Directory Structure

```
~/scripts/
├── tool                    # Main launcher (runs any script by name)
├── config/
│   └── toolkit.conf        # Key-value config (PROJECTS_DIR, NOTES_DIR, etc.)
├── lib/
│   ├── colors.sh           # Color variables (BRIGHT_*, ACCENT_*, GRADIENT_*, BOLD, DIM, RESET)
│   ├── ui.sh               # NF icon constants, print_success/error/warning/info/loading, draw_box_*, print_header, print_*_line
│   ├── config.sh           # Loads toolkit.conf, exports SCRIPTS_DIR
│   └── utils.sh            # command_exists, require_command, validate_name, confirm_action
├── system/                 # System admin: health-check, update-all, cleanup, sysmon, port-manager, docker-cleanup, ollama-manager
├── dev/                    # Dev tools: git-helper, venv-manager, project-init
├── general/                # General: ff, extract, notes, bookmark, cheat, weather
└── net/                    # Network: ip-lookup, ssl-check, holehe-check, qr, passmorph
```

New scripts go into one of these category directories. The `tool` launcher auto-discovers them.

---

## 3. Critical Rule: No Emojis — Nerd Font Icons Only

**NEVER use emojis anywhere** — not in output, not in comments, not in generated files. The toolkit uses **Nerd Font icons** exclusively.

### Available `$NF_*` variables (defined in `lib/ui.sh`):

| Variable | Codepoint | Use for |
|---|---|---|
| `$NF_CHECK` | `\uf00c` | Success, done, pass |
| `$NF_CROSS` | `\uf00d` | Error, failure, fail |
| `$NF_WARN` | `\uf071` | Warning |
| `$NF_INFO` | `\uf05a` | Info messages |
| `$NF_SPINNER` | `\uf252` | Loading / in-progress |
| `$NF_ROCKET` | `\uf135` | Launch, deploy, start |
| `$NF_FOLDER` | `\uf07b` | Directory (closed) |
| `$NF_FOLDER_OPEN` | `\uf07c` | Directory (open), listing |
| `$NF_PACKAGE` | `\uf466` | Packages, dependencies |
| `$NF_WRENCH` | `\uf0ad` | Config, tools, settings |
| `$NF_TARGET` | `\uf05b` | Goals, targets |
| `$NF_TRASH` | `\uf1f8` | Delete, remove |
| `$NF_SEARCH` | `\uf002` | Search, find, inspect |
| `$NF_PENCIL` | `\uf044` | Edit, notes, write |
| `$NF_FILE_TEXT` | `\uf15c` | Files, documents |
| `$NF_REFRESH` | `\uf021` | Update, sync, reload |
| `$NF_FLOPPY` | `\uf0c7` | Save, backup, disk |
| `$NF_GLOBE` | `\uf0ac` | Network, web, internet |
| `$NF_SHIELD` | `\uf132` | Security, protection |
| `$NF_LOCK` | `\uf023` | Lock |
| `$NF_UNLOCK` | `\uf09c` | Unlock |
| `$NF_BOLT` | `\uf0e7` | Lightning, fast, energy |
| `$NF_ERASER` | `\uf12d` | Cleanup, prune |
| `$NF_DOCKER` | `\uf308` | Docker |
| `$NF_PLUG` | `\uf1e6` | Ports, connections |
| `$NF_CHART` | `\uf080` | Stats, graphs |
| `$NF_DESKTOP` | `\uf108` | Desktop, display |
| `$NF_HOME` | `\uf015` | Home directory |
| `$NF_LINK` | `\uf0c1` | Links |
| `$NF_PYTHON` | `\ue606` | Python |
| `$NF_CLIPBOARD` | `\uf0ea` | Clipboard, paste |
| `$NF_FLASK` | `\uf0c3` | Testing, experiment |
| `$NF_BOOK` | `\uf02d` | Documentation |
| `$NF_BAN` | `\uf05e` | Block, deny |
| `$NF_PLAY` | `\uf04b` | Run, execute |
| `$NF_DOWNLOAD` | `\uf019` | Download, add |
| `$NF_UPLOAD` | `\uf093` | Upload |
| `$NF_GIT` | `\uf1d3` | Git |
| `$NF_TERMINAL` | `\uf489` | Terminal, shell, bash |
| `$NF_CHEVRON` | `\uf054` | Arrow, prompt |
| `$NF_SERVER` | `\uf233` | Server, system |
| `$NF_KEY` | `\uf084` | Keys, SSH, auth |
| `$NF_COG` | `\uf013` | CPU, processing |
| `$NF_PAINT` | `\uf1fc` | GUI, design |
| `$NF_STAR` | `\uf005` | Highlight, favorite |
| `$NF_HEARTBEAT` | `\uf21e` | Health, monitoring |
| `$NF_CUBE` | `\uf1b2` | Models, packages, containers |
| `$NF_TAG` | `\uf02b` | Tags, labels |
| `$NF_NETWORK` | `\uf0c8` | Network node |
| `$NF_BULLHORN` | `\uf0a1` | Announce, verbose |

### File extension icons (used by the `tool` launcher's `get_icon` function):

| Extension | Codepoint | Variable in `get_icon` |
|---|---|---|
| `sh` / `bash` | `\uf489` | Bash terminal |
| `py` | `\ue606` | Python |
| `js` | `\ue60c` | JavaScript |
| `ts` | `\ue628` | TypeScript |
| `go` | `\ue627` | Go |
| `rs` | `\ue7a8` | Rust |
| `rb` | `\ue21e` | Ruby |
| `json` | `\ue60b` | JSON |
| `yaml`/`yml` | `\ue6d8` | YAML |
| `md` | `\ue609` | Markdown |
| `html` | `\ue60e` | HTML |
| `css` | `\ue60d` | CSS |

If a needed icon doesn't exist in `$NF_*`, you can add a new `readonly NF_NEWNAME=$'\uXXXX'` line to `lib/ui.sh`. Look up codepoints at [nerdfonts.com/cheat-sheet](https://www.nerdfonts.com/cheat-sheet).

---

## 4. Script Boilerplate

Every new toolkit script **must** start with this exact boilerplate:

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

This gives you access to all colors, NF icons, print functions, and utility helpers.

If the script needs a tool installed, check it immediately:

```bash
require_command docker "Install Docker: https://docs.docker.com/engine/install" || exit 1
```

---

## 5. Color Palette (available variables)

### Base and bright (standard ANSI):
`BLACK` `RED` `GREEN` `YELLOW` `BLUE` `MAGENTA` `CYAN` `WHITE`
`BRIGHT_BLACK` `BRIGHT_RED` `BRIGHT_GREEN` `BRIGHT_YELLOW` `BRIGHT_BLUE` `BRIGHT_MAGENTA` `BRIGHT_CYAN` `BRIGHT_WHITE`

### Effects:
`BOLD` `DIM` `ITALIC` `UNDERLINE`

### Gradients (256-color, white-to-charcoal):
`GRADIENT_1` (white) → `GRADIENT_2` → `GRADIENT_3` → `GRADIENT_4` → `GRADIENT_5` (charcoal)

### Accents (256-color):
`ACCENT_BLUE` `ACCENT_GREEN` `ACCENT_ORANGE` `ACCENT_PURPLE` `ACCENT_TEAL` `ACCENT_PINK` `ACCENT_GOLD`

### Reset:
`RESET` or `NC` (alias)

### Color usage conventions:

| Element | Color |
|---|---|
| Primary headers / titles | `${BRIGHT_CYAN}${BOLD}` |
| Labels (key names) | `${BRIGHT_CYAN}` |
| Values (strings, names) | `${BRIGHT_WHITE}` |
| Success values | `${BRIGHT_GREEN}` |
| Warning values | `${BRIGHT_YELLOW}` |
| Error values | `${BRIGHT_RED}` |
| Paths, timestamps, secondary info | `${DIM}` |
| Separators, table borders | `${BRIGHT_BLACK}` |
| Section titles | `${BRIGHT_MAGENTA}${BOLD}` or `${GRADIENT_3}${BOLD}` |

---

## 6. Output Functions

### Status messages — always use these, never raw echo for status:

```bash
print_success "Task completed"        # green  + NF_CHECK
print_error   "Something failed"      # red    + NF_CROSS
print_warning "Heads up"              # yellow + NF_WARN
print_info    "FYI note"              # cyan   + NF_INFO
print_loading "Working on it..."      # blue   + NF_SPINNER
```

Aliases `log_success`, `log_error`, `log_warning`, `log_info` also exist.

### Headers:

```bash
print_header "${NF_DOCKER} Docker Cleanup"    # Cyan bold, NF icon prefix
```

Always prefix `print_header` text with a relevant `$NF_*` icon.

### Divider lines:

```bash
print_double_line     # ═══ bright cyan
print_single_line     # ─── bright black (dim)
```

### Info blocks (draw_box_*):

```bash
draw_box_top
draw_box_line "${BRIGHT_WHITE}${BOLD}Title${RESET}"
draw_box_middle
draw_box_line "${BRIGHT_CYAN}  Label:${RESET}  ${BRIGHT_WHITE}value${RESET}"
draw_box_line "${BRIGHT_CYAN}  Path:${RESET}   ${DIM}/some/path${RESET}"
draw_box_bottom
```

Currently box borders are no-ops (content prints without borders). Use `draw_box_line` for structured key-value display.

### Confirmation prompts:

```bash
if confirm_action "Delete this file?"; then
    rm "$file"
fi
```

---

## 7. Help Menu Pattern

Every multi-command script has a `show_help` function using this exact format:

```bash
show_help() {
    print_header "${NF_RELEVANT_ICON} Script Name"
    echo
    printf "  ${BRIGHT_GREEN}%-18s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" "command"       "Description of command"
    printf "  ${BRIGHT_GREEN}%-18s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" "other <arg>"   "Description with argument"
    echo
}
```

Key points:
- 2-space left indent
- Command in `BRIGHT_GREEN`, padded to fixed width
- `│` separator in `BRIGHT_BLACK`
- Description in `BRIGHT_WHITE`

---

## 8. Main / Subcommand Pattern

Scripts with multiple subcommands follow this structure:

```bash
main() {
    local cmd="${1:-default_cmd}"
    shift || true

    case "$cmd" in
        command|alias1|alias2)  function_name "$@" ;;
        other|alt)              other_function "$@" ;;
        help|--help|-h)         show_help ;;
        *)
            print_error "Unknown command: $cmd"
            echo
            show_help
            exit 1
            ;;
    esac
}

main "$@"
```

Always provide short aliases (`l` for `list`, `s` for `search`, etc.).

---

## 9. Table / List Output Pattern

For tabular data, use `printf` with color formatting:

```bash
# Header row
printf "  ${BRIGHT_CYAN}%-20s %-12s %s${RESET}\n" "Name" "Status" "Details"
print_single_line

# Data rows
printf "  ${BRIGHT_GREEN}%-20s${RESET} ${BRIGHT_WHITE}%-12s${RESET} ${DIM}%s${RESET}\n" \
    "$name" "$status" "$details"

# Footer
echo
echo -e "${BRIGHT_CYAN}  Total: ${BOLD}${BRIGHT_GREEN}${count}${RESET}"
echo
```

---

## 10. Coding Conventions

- **Shebang:** `#!/usr/bin/env bash`
- **Error handling:** `set -euo pipefail` for deployment/critical scripts; looser for interactive ones
- **Private functions:** prefix with `_` (e.g., `_pid_on_port`)
- **Local variables:** always `local` inside functions
- **Path detection:** use the `_SCRIPT_DIR` / `_TOOLKIT_DIR` pattern, never hardcode `~/scripts`
- **Config values:** read from `toolkit.conf` via the config library, with fallback defaults: `NOTES_DIR="${NOTES_DIR:-$HOME/notes}"`
- **Comment style:** `# ── Section Name ──────────` for visual section dividers inside files
- **File header comment:**
  ```bash
  # =====================================================
  # Script Name - Brief description
  # =====================================================
  ```

---

## 11. What NOT to Do

1. **No emojis.** Not in output, not in comments, not in generated README/markdown/HTML files. Use `$NF_*` Nerd Font variables for terminal output. For generated files meant for web/markdown viewing, use plain text (no icons at all).
2. **No raw ANSI codes** — always use the color variables from `colors.sh`.
3. **No inline color definitions** — don't define `RED='\033[...'` inside scripts that source the toolkit libs.
4. **No `echo` for status** — use `print_success`, `print_error`, etc.
5. **No hardcoded paths** — use `$SCRIPTS_DIR`, `$PROJECTS_DIR`, `$HOME`, etc.
6. **No missing help** — every multi-command script needs `show_help`.

---

## 12. Example: Complete Minimal Script

```bash
#!/usr/bin/env bash
# =====================================================
# Wifi Scanner - Scan nearby wifi networks
# =====================================================

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_TOOLKIT_DIR="$(dirname "${_SCRIPT_DIR}")"
source "${_TOOLKIT_DIR}/lib/config.sh"
source "${_TOOLKIT_DIR}/lib/ui.sh"
source "${_TOOLKIT_DIR}/lib/utils.sh"

require_command nmcli "Install NetworkManager: sudo apt install network-manager" || exit 1

scan_networks() {
    print_header "${NF_GLOBE} Nearby Networks"
    echo

    print_loading "Scanning..."
    local results
    results=$(nmcli -t -f SSID,SIGNAL,SECURITY device wifi list 2>/dev/null)

    if [ -z "$results" ]; then
        print_warning "No networks found"
        return
    fi

    printf "  ${BRIGHT_CYAN}%-30s %-8s %s${RESET}\n" "SSID" "Signal" "Security"
    print_single_line

    echo "$results" | sort -t: -k2 -rn | while IFS=: read -r ssid signal security; do
        [ -z "$ssid" ] && continue
        local color="${BRIGHT_GREEN}"
        [ "$signal" -lt 50 ] && color="${BRIGHT_YELLOW}"
        [ "$signal" -lt 25 ] && color="${BRIGHT_RED}"
        printf "  ${BRIGHT_WHITE}%-30s${RESET} ${color}%-8s${RESET} ${DIM}%s${RESET}\n" \
            "$ssid" "${signal}%" "$security"
    done

    echo
    print_success "Scan complete"
    echo
}

show_help() {
    print_header "${NF_GLOBE} Wifi Scanner"
    echo
    printf "  ${BRIGHT_GREEN}%-18s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" "scan"    "Scan nearby wifi networks"
    printf "  ${BRIGHT_GREEN}%-18s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" "help"    "Show this help message"
    echo
}

main() {
    local cmd="${1:-scan}"
    shift || true

    case "$cmd" in
        scan|s)         scan_networks ;;
        help|--help|-h) show_help ;;
        *)
            print_error "Unknown command: $cmd"
            echo
            show_help
            exit 1
            ;;
    esac
}

main "$@"
```

---

## 13. Adding a New Icon

If the existing `$NF_*` set doesn't cover your needs:

1. Find the glyph at [nerdfonts.com/cheat-sheet](https://www.nerdfonts.com/cheat-sheet)
2. Add to `~/scripts/lib/ui.sh`:
   ```bash
   readonly NF_NEWICON=$'\uXXXX'    # description
   ```
3. Use as `${NF_NEWICON}` in your script

---

## 14. Registering with the Toolkit

New scripts are auto-discovered. Just:

1. Place the `.sh` file in the appropriate category folder under `~/scripts/`
2. Make it executable: `chmod +x ~/scripts/category/script-name.sh`
3. Run via: `tool script-name` (extension is optional)

Alternatively: `tool add /path/to/script.sh` and choose a category.
