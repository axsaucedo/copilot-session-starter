# Copilot Session Picker — source this file from your .zshrc
# Usage: copilot-sessions-{small,medium,large} [copilot flags...]
# Example: copilot-sessions-medium --allow-all-tools

_COPILOT_SESSION_DIR="${HOME}/.copilot/session-state"

# Helper: build session list lines (shared by all variants)
# Format: <uuid> | <short_date> | <project> | <plan_first_line>
_copilot_session_list() {
  ls -td "$_COPILOT_SESSION_DIR"/*/ 2>/dev/null | while read -r d; do
    local uuid=$(basename "$d")
    local git_root=$(grep '^git_root:' "$d/workspace.yaml" 2>/dev/null | sed 's/^git_root: //')
    local cwd=$(grep '^cwd:' "$d/workspace.yaml" 2>/dev/null | sed 's/^cwd: //')
    local project=$(basename "${git_root:-${cwd:--}}")
    local modified=$(stat -f "%Sm" -t "%b %d %H:%M" "$d/workspace.yaml" 2>/dev/null)
    local plan_line=""
    if [ -f "$d/plan.md" ]; then
      plan_line=$(head -1 "$d/plan.md" | sed 's/^#* *//')
    fi
    echo "$uuid | ${modified:--} | ${project:--} | ${plan_line:--}"
  done
}

# --- Small: bare-bones ---
copilot-sessions-small() {
  local id
  id=$(_copilot_session_list | fzf \
    --delimiter ' \| ' --with-nth=2.. --preview-window=right:50%:wrap \
    --preview 'd='"$_COPILOT_SESSION_DIR"'/{1}
      cat "$d/workspace.yaml" 2>/dev/null
      echo "---"
      bat --style=plain --color=always -l md "$d/plan.md" 2>/dev/null || cat "$d/plan.md" 2>/dev/null') || return 0
  copilot --resume="${id%% |*}" "$@"
}

# --- Medium: coloured list + structured preview ---
copilot-sessions-medium() {
  local id
  id=$(_copilot_session_list | while IFS='|' read -r uuid dt proj plan; do
    printf "\033[2m%s\033[0m | \033[33m%s\033[0m | \033[36m%s\033[0m | \033[35m%s\033[0m\n" \
      "$uuid" "$dt" "$proj" "$plan"
  done | fzf --ansi --header "Enter: resume | Esc: cancel" \
    --delimiter ' \| ' --with-nth=2.. --preview-window=right:55%:wrap \
    --preview 'd='"$_COPILOT_SESSION_DIR"'/{1}
      printf "\033[1;34m📅 Last Modified\033[0m\n"
      printf "   \033[33m%s\033[0m\n" "$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$d/workspace.yaml" 2>/dev/null)"
      echo ""
      printf "\033[1;34m📋 Workspace\033[0m\n"
      printf "   \033[2mID:\033[0m  %s\n" "$(grep "^id:" "$d/workspace.yaml" 2>/dev/null | sed "s/^id: //")"
      printf "   \033[2mCWD:\033[0m %s\n" "$(grep "^cwd:" "$d/workspace.yaml" 2>/dev/null | sed "s/^cwd: //")"
      summary=$(grep "^summary:" "$d/workspace.yaml" 2>/dev/null | head -1 | sed "s/^summary: //")
      [ -n "$summary" ] && printf "   \033[1;33mSummary:\033[0m %s\n" "$summary"
      if [ -f "$d/plan.md" ]; then
        echo ""
        printf "\033[1;34m📝 Plan\033[0m\n"
        bat --style=plain --color=always -l md "$d/plan.md" 2>/dev/null | sed "s/^/   /" || sed "s/^/   /" "$d/plan.md" 2>/dev/null
      fi') || return 0
  copilot --resume="${id%% |*}" "$@"
}

# --- Large: full-featured with colours, --help, --dry-run, fzf check ---
copilot-sessions-large() {
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
  id=$(_copilot_session_list | while IFS='|' read -r uuid dt proj plan; do
    printf "\033[2m%s\033[0m | \033[33m%s\033[0m | \033[1;36m%s\033[0m | \033[35m%s\033[0m\n" \
      "$uuid" "$dt" "$proj" "$plan"
  done | fzf --ansi --header "Enter: resume | Esc: cancel | Type to search" \
    --delimiter ' \| ' --with-nth=2.. --preview-window=right:55%:wrap \
    --preview 'd='"$_COPILOT_SESSION_DIR"'/{1}
      printf "\033[1;34m📅 Last Modified\033[0m\n"
      mod=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$d/workspace.yaml" 2>/dev/null)
      printf "   \033[33m%s\033[0m" "$mod"
      days=$(( ( $(date +%s) - $(stat -f "%m" "$d/workspace.yaml" 2>/dev/null) ) / 86400 ))
      if [ "$days" -eq 0 ]; then printf " \033[32m(today)\033[0m\n";
      elif [ "$days" -eq 1 ]; then printf " \033[33m(yesterday)\033[0m\n";
      else printf " \033[31m(%d days ago)\033[0m\n" "$days"; fi
      echo ""
      printf "\033[1;34m📋 Workspace\033[0m\n"
      printf "   \033[2mID:\033[0m       %s\n" "$(grep "^id:" "$d/workspace.yaml" 2>/dev/null | sed "s/^id: //")"
      printf "   \033[2mCWD:\033[0m      %s\n" "$(grep "^cwd:" "$d/workspace.yaml" 2>/dev/null | sed "s/^cwd: //")"
      summary=$(grep "^summary:" "$d/workspace.yaml" 2>/dev/null | head -1 | sed "s/^summary: //")
      [ -n "$summary" ] && printf "   \033[1;33mSummary:\033[0m  %s\n" "$summary"
      branch=$(grep "^branch:" "$d/workspace.yaml" 2>/dev/null | sed "s/^branch: //")
      [ -n "$branch" ] && printf "   \033[2mBranch:\033[0m   \033[36m%s\033[0m\n" "$branch"
      if [ -f "$d/plan.md" ]; then
        echo ""
        printf "\033[1;34m📝 Plan\033[0m\n"
        bat --style=plain --color=always -l md "$d/plan.md" 2>/dev/null | sed "s/^/   /" || sed "s/^/   /" "$d/plan.md" 2>/dev/null
      fi') || return 0

  local session_id="${id%% |*}"
  if $dry_run; then
    echo "copilot --resume=$session_id ${copilot_args[*]}"
  else
    copilot --resume="$session_id" "${copilot_args[@]}"
  fi
}
