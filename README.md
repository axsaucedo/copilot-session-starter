# Copilot Session Picker

Interactive fzf-based session picker for [GitHub Copilot CLI](https://gh.io/copilot-cli). Browse, preview, and resume sessions sorted by most recent.

## Prerequisites

- [fzf](https://github.com/junegunn/fzf) — `brew install fzf`
- [bat](https://github.com/sharkdp/bat) — `brew install bat` (optional, for markdown highlighting in preview)
- [GitHub Copilot CLI](https://gh.io/copilot-cli)

## Setup

Copy the `copilot-sessions` function from `copilot-sessions.zsh` into your `~/.zshrc`.

## Usage

```bash
# Open the session picker
copilot-sessions

# Pass flags through to copilot
copilot-sessions --allow-all-tools
```

## What it does

1. Scans `~/.copilot/session-state/` for session directories
2. Sorts by most recently modified
3. Opens fzf with a coloured list showing date, project name, and plan title
4. Preview pane shows workspace metadata and syntax-highlighted plan
5. On selection, runs `copilot --resume=<session-id>` with any extra flags
