<p align="center">
  <img src="https://img.shields.io/badge/bash-5.0+-4EAA25?logo=gnubash&logoColor=white" alt="Bash 5.0+">
  <img src="https://img.shields.io/badge/python-3.8+-3776AB?logo=python&logoColor=white" alt="Python 3.8+">
  <img src="https://img.shields.io/badge/platform-Linux%20%7C%20WSL2-FCC624?logo=linux&logoColor=black" alt="Linux | WSL2">
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT License">
</p>

<br>

<h1 align="center">Toolkit</h1>

<p align="center">
  <strong>25 shell scripts under one command.<br>System admin, dev tools, networking — all with a unified TUI.</strong>
</p>

<img width="941" height="556" alt="image" src="https://github.com/user-attachments/assets/7e26d5ad-ec4c-47c8-87e2-455528ad1580" />


## Why Toolkit?

Most of us end up with a `~/scripts` folder full of disconnected shell scripts. Toolkit turns that mess into a structured, discoverable, and consistent system:

- **One command to rule them all** — `tool <anything>` finds and runs your script by name, no paths needed
- **Auto-discovery** — drop a script into a category folder and it's instantly available
- **Shared library** — colors, icons, UI components, and utilities are built-in so every script looks consistent
- **Nerd Font powered** — 50+ icon variables for beautiful terminal output, zero emojis
- **Portable** — works on any Linux distro and WSL2

<br>

## Quick Start

```bash
git clone https://github.com/ibrah5em/toolkit.git ~/scripts
chmod +x ~/scripts/tool

# Add to your shell
echo 'export PATH="$HOME/scripts:$PATH"' >> ~/.bashrc  # or ~/.zshrc
source ~/.bashrc

# Try it
tool list
tool health-check
tool ff file "*.py"
```

<br>

## What's Inside

### System

| Script | What it does |
|--------|-------------|
| `health-check` | Full system health report — CPU, memory, disk, services, Docker, network |
| `update-all` | Update everything at once — apt, pip, Docker images, Ollama models |
| `cleanup` | Reclaim disk space — apt cache, journals, temp files, Docker dangling |
| `disk-analyzer` | Find what's eating your storage with interactive breakdown |
| `docker-cleanup` | Safe Docker resource cleanup — images, containers, volumes, networks |
| `port-manager` | List open ports, find what's using a port, kill processes by port |
| `proc-top` | Top processes by CPU and memory with clean formatting |
| `service-status` | Quick overview of all running services |
| `sysmon` | Compact real-time system monitor |
| `ollama-manager` | Manage Ollama models — pull, delete, status, with auto-retry |

### Dev

| Script | What it does |
|--------|-------------|
| `git-helper` | Git dashboard — status, log, branch cleanup, multi-repo scan |
| `project-init` | Scaffold new projects — Python, Node, Go, Rust, with git + venv |
| `venv-manager` | Overview and management of all Python virtual environments |

### General

| Script | What it does |
|--------|-------------|
| `ff` | Fast finder — search files by name, grep contents, find recent files, detect duplicates |
| `extract` | Universal archive extractor — tar, zip, 7z, rar, deb, rpm, zst |
| `notes` | Terminal note-taking organized by date |
| `bookmark` | Save and jump to directories instantly |
| `cheat` | Quick command reference sheets via cheat.sh |
| `weather` | Terminal weather reports via wttr.in |

### Net

| Script | What it does |
|--------|-------------|
| `ip-lookup` | IP intelligence — geolocation, ASN, abuse reports, threat scoring |
| `ssl-check` | Certificate expiry and health monitoring for your domains |
| `holehe-check` | OSINT email lookup — find which services an email is registered on |
| `qr` | Generate QR codes directly in the terminal |
| `passmorph` | Learn password patterns from a list and generate similar ones |

<br>

## Architecture

```
~/scripts/
├── tool                    # Main launcher — the only thing in your PATH
├── config/
│   └── toolkit.conf        # All user-configurable paths
├── lib/
│   ├── colors.sh           # 30+ color variables, gradients, accents
│   ├── ui.sh               # 50+ Nerd Font icons, print functions, box drawing
│   ├── config.sh           # Config loader with env override support
│   └── utils.sh            # command_exists, require_command, confirm_action
├── system/                 # System administration
├── dev/                    # Developer tools
├── general/                # General utilities
└── net/                    # Networking & security
```

The shared library (`lib/`) is the backbone. Every script sources it and gets:

- **Consistent colors** — ANSI variables so you never hardcode escape codes
- **Nerd Font icons** — `$NF_CHECK`, `$NF_ROCKET`, `$NF_DOCKER`, and 50 more
- **Status functions** — `print_success`, `print_error`, `print_warning`, `print_info`
- **UI components** — headers, dividers, box drawing, tables
- **Utilities** — dependency checking, input validation, confirmation prompts
- **Config system** — cascading config with env variable override

<br>

## Writing Your Own Scripts

Every script follows the same pattern:

```bash
#!/usr/bin/env bash
# =====================================================
# My Script - What it does in one line
# =====================================================

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_TOOLKIT_DIR="$(dirname "${_SCRIPT_DIR}")"
source "${_TOOLKIT_DIR}/lib/config.sh"
source "${_TOOLKIT_DIR}/lib/ui.sh"
source "${_TOOLKIT_DIR}/lib/utils.sh"

# Check dependencies
require_command curl "Install with: sudo apt install curl" || exit 1

# Your logic here
print_header "${NF_ROCKET} My Script"
print_success "It works!"
```

Drop it into any category folder, make it executable, and `tool my-script` just works.

See [`docs/AUTHORING.md`](docs/AUTHORING.md) for the full style guide.

<br>

## Configuration

Edit `~/scripts/config/toolkit.conf` to set your paths:

```bash
PROJECTS_DIR="$HOME/projects"
NOTES_DIR="$HOME/notes"
```

Configuration priority: environment variables > `~/.config/toolkit/config` > `config/toolkit.conf`

<br>

## Requirements

- **Bash 5.0+** (standard on Ubuntu 20.04+, macOS with Homebrew bash)
- **A Nerd Font** — the icons won't render without one. Grab one from [nerdfonts.com](https://www.nerdfonts.com/font-downloads) (recommendation: JetBrainsMono Nerd Font)
- **Python 3.8+** for the Python script (`passmorph`)
- Individual scripts may require specific tools (Docker, Ollama, etc.) — they'll tell you what's missing

<br>

## License

MIT — do whatever you want with it. See [LICENSE](LICENSE).

<br>

---

<p align="center">
  If this saved you time, a star would mean a lot.
</p>
