# Copilot Session Picker — source this file from your .zshrc
# Usage: copilot-sessions-{small,medium,large} [copilot flags...]
# Example: copilot-sessions-medium --allow-all-tools

_COPILOT_SESSION_DIR="${HOME}/.copilot/session-state"

# --- Small: bare-bones, ~10 lines ---
copilot-sessions-small() {
  local id
  id=$(ls -td "$_COPILOT_SESSION_DIR"/*/ 2>/dev/null | while read -r d; do
    local uuid=$(basename "$d")
    local summary=$(grep '^summary:' "$d/workspace.yaml" 2>/dev/null | head -1 | sed 's/^summary: //')
    local cwd=$(grep '^cwd:' "$d/workspace.yaml" 2>/dev/null | sed 's/^cwd: //')
    echo "$uuid | ${summary:--} | ${cwd:--}"
  done | fzf --preview 'd='"$_COPILOT_SESSION_DIR"'/{1}; cat "$d/workspace.yaml" 2>/dev/null; echo; echo "---"; cat "$d/plan.md" 2>/dev/null' \
    --delimiter ' \| ' --with-nth=1.. --preview-window=right:50%:wrap) || return 0
  copilot --resume="${id%% |*}" "$@"
}

# --- Medium: formatted entries + nicer preview, ~25 lines ---
copilot-sessions-medium() {
  local id
  id=$(ls -td "$_COPILOT_SESSION_DIR"/*/ 2>/dev/null | while read -r d; do
    local uuid=$(basename "$d")
    local summary=$(grep '^summary:' "$d/workspace.yaml" 2>/dev/null | head -1 | sed 's/^summary: //')
    local branch=$(grep '^branch:' "$d/workspace.yaml" 2>/dev/null | sed 's/^branch: //')
    local cwd=$(grep '^cwd:' "$d/workspace.yaml" 2>/dev/null | sed 's/^cwd: //')
    echo "$uuid | ${summary:--} | ${branch:--} | ${cwd:--}"
  done | fzf --header "Enter: resume session | Esc: cancel" \
    --delimiter ' \| ' --with-nth=1.. --preview-window=right:55%:wrap \
    --preview 'd='"$_COPILOT_SESSION_DIR"'/{1}
      echo "📅 Last Modified"
      stat -f "   %Sm" -t "%Y-%m-%d %H:%M" "$d/workspace.yaml" 2>/dev/null
      echo ""
      echo "📋 Workspace"
      sed "s/^/   /" "$d/workspace.yaml" 2>/dev/null
      if [ -f "$d/plan.md" ]; then
        echo ""
        echo "📝 Plan"
        sed "s/^/   /" "$d/plan.md" 2>/dev/null
      fi
    ') || return 0
  copilot --resume="${id%% |*}" "$@"
}

# --- Large: colors, --help, --dry-run, fzf check, ~50 lines ---
copilot-sessions-large() {
  # Handle flags
  local dry_run=false
  local -a copilot_args=()
  for arg in "$@"; do
    case "$arg" in
      --help)
        echo "Usage: copilot-sessions-large [--dry-run] [--help] [copilot flags...]"
        echo ""
        echo "Interactive session picker for GitHub Copilot CLI."
        echo "Flags after selection are passed to 'copilot --resume=<id>'."
        echo ""
        echo "Options:"
        echo "  --dry-run   Print the copilot command instead of running it"
        echo "  --help      Show this help"
        return 0 ;;
      --dry-run) dry_run=true ;;
      *) copilot_args+=("$arg") ;;
    esac
  done

  if ! command -v fzf &>/dev/null; then
    echo "Error: fzf is required. Install with: brew install fzf" >&2
    return 1
  fi

  local id
  id=$(ls -td "$_COPILOT_SESSION_DIR"/*/ 2>/dev/null | while read -r d; do
    local uuid=$(basename "$d")
    local summary=$(grep '^summary:' "$d/workspace.yaml" 2>/dev/null | head -1 | sed 's/^summary: //')
    local branch=$(grep '^branch:' "$d/workspace.yaml" 2>/dev/null | sed 's/^branch: //')
    local cwd=$(grep '^cwd:' "$d/workspace.yaml" 2>/dev/null | sed 's/^cwd: //')
    local updated=$(grep '^updated_at:' "$d/workspace.yaml" 2>/dev/null | sed 's/^updated_at: //')
    printf "\033[1m%s\033[0m | \033[33m%s\033[0m | \033[36m%s\033[0m | %s | \033[2m%s\033[0m\n" \
      "$uuid" "${summary:--}" "${branch:--}" "${cwd:--}" "${updated:--}"
  done | fzf --ansi --header "Enter: resume | Esc: cancel | Type to search" \
    --delimiter ' \| ' --with-nth=1.. --preview-window=right:55%:wrap \
    --preview 'd='"$_COPILOT_SESSION_DIR"'/{1}
      echo "📅 Last Modified"
      mod=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$d/workspace.yaml" 2>/dev/null)
      echo "   $mod"
      days=$(( ( $(date +%s) - $(stat -f "%m" "$d/workspace.yaml" 2>/dev/null) ) / 86400 ))
      if [ "$days" -eq 0 ]; then echo "   (today)";
      elif [ "$days" -eq 1 ]; then echo "   (yesterday)";
      else echo "   (${days} days ago)"; fi
      echo ""
      echo "📋 Workspace"
      sed "s/^/   /" "$d/workspace.yaml" 2>/dev/null
      if [ -f "$d/plan.md" ]; then
        echo ""
        echo "📝 Plan"
        sed "s/^/   /" "$d/plan.md" 2>/dev/null
      fi
    ') || return 0

  local session_id="${id%% |*}"
  if $dry_run; then
    echo "copilot --resume=$session_id ${copilot_args[*]}"
  else
    copilot --resume="$session_id" "${copilot_args[@]}"
  fi
}
