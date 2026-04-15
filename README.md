# Copilot Session Picker

Interactive [fzf](https://github.com/junegunn/fzf)-based session picker for [GitHub Copilot CLI](https://gh.io/copilot-cli). Browse, preview, and resume sessions sorted by most recent.

## Prerequisites

- [fzf](https://github.com/junegunn/fzf) — `brew install fzf`
- [bat](https://github.com/sharkdp/bat) *(optional, for markdown highlighting)* — `brew install bat`
- [GitHub Copilot CLI](https://gh.io/copilot-cli)

## Install

### Oh My Zsh

```bash
git clone https://github.com/axsaucedo/copilot-session-starter.git \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/copilot-sessions
```

Then add `copilot-sessions` to your plugins in `~/.zshrc`:

```zsh
plugins=(... copilot-sessions)
```

### Zinit

```zsh
zinit light axsaucedo/copilot-session-starter
```

### Zplug

```zsh
zplug "axsaucedo/copilot-session-starter"
```

### Antidote

Add to `~/.zsh_plugins.txt`:

```
axsaucedo/copilot-session-starter
```

### Manual (source)

```bash
git clone https://github.com/axsaucedo/copilot-session-starter.git \
  ~/.zsh/copilot-sessions
```

Add to `~/.zshrc`:

```zsh
source ~/.zsh/copilot-sessions/copilot-sessions.plugin.zsh
```

## Usage

```bash
copilot-sessions                      # open session picker
copilot-sessions --allow-all-tools    # pass flags through to copilot
```

## What it does

1. Scans `~/.copilot/session-state/` for session directories
2. Sorts by most recently modified
3. Shows a coloured list with date, project name, and plan title
4. Preview pane with workspace metadata and syntax-highlighted plan
5. On selection, runs `copilot --resume=<session-id>` with any extra flags
