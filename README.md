# Copilot Session Picker

Interactive fzf-based session picker for [GitHub Copilot CLI](https://gh.io/copilot-cli). Browse, preview, and resume sessions sorted by most recent.

## Prerequisites

- [fzf](https://github.com/junegunn/fzf) — `brew install fzf`
- [GitHub Copilot CLI](https://gh.io/copilot-cli)

## Setup

Add to your `.zshrc`:

```zsh
source /path/to/copilot-sessions.zsh
```

## Usage

Three variants at different complexity levels:

| Function | Lines | Features |
|----------|-------|----------|
| `copilot-sessions-small` | ~10 | UUID + summary + cwd, raw preview |
| `copilot-sessions-medium` | ~25 | + branch, preview headers, last-modified date |
| `copilot-sessions-large` | ~50 | + colors, `--help`, `--dry-run`, fzf check, session age |

```bash
# Basic usage
copilot-sessions-medium

# Pass flags through to copilot
copilot-sessions-medium --allow-all-tools

# Large: preview command without running
copilot-sessions-large --dry-run

# Large: help
copilot-sessions-large --help
```

## What it does

1. Scans `~/.copilot/session-state/` for session directories
2. Sorts by most recently modified
3. Opens fzf with a preview pane showing `workspace.yaml` and `plan.md`
4. On selection, runs `copilot --resume=<session-id>` with any extra flags
