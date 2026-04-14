# Copilot Session Picker — paste into your .zshrc
# Usage: copilot-sessions [copilot flags...]
# Example: copilot-sessions --allow-all-tools

copilot-sessions() {
  local sdir="${HOME}/.copilot/session-state"
  local id
  id=$(ls -td "$sdir"/*/ 2>/dev/null | while read -r d; do
    local uuid=$(basename "$d")
    local git_root=$(grep '^git_root:' "$d/workspace.yaml" 2>/dev/null | sed 's/^git_root: //')
    local cwd=$(grep '^cwd:' "$d/workspace.yaml" 2>/dev/null | sed 's/^cwd: //')
    local project=$(basename "${git_root:-${cwd:--}}")
    local modified=$(stat -f "%Sm" -t "%b %d %H:%M" "$d/workspace.yaml" 2>/dev/null)
    local plan_line=""
    [ -f "$d/plan.md" ] && plan_line=$(head -1 "$d/plan.md" | sed 's/^#* *//')
    printf "\033[2m%s\033[0m | \033[33m%s\033[0m | \033[36m%s\033[0m | \033[35m%s\033[0m\n" \
      "$uuid" "${modified:--}" "${project:--}" "${plan_line:--}"
  done | fzf --ansi --header "Enter: resume | Esc: cancel" \
    --delimiter ' \| ' --with-nth=2.. --preview-window=right:55%:wrap \
    --preview 'd='"$sdir"'/{1}
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
