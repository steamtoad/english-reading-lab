#!/bin/zsh

#------------------------------------------------------------------------------
# zt-workspace-open.zsh
# Тип: Workspace
# Назначение: выбор рабочей области и просмотр через cat
#------------------------------------------------------------------------------

emulate -L zsh
setopt null_glob

script_dir="${0:A:h}"
source "$script_dir/lib/paths.zsh"
source "$script_dir/lib/workspace.zsh"

sep=$'\x1f'

zk_require_workspaces || exit 1

selected="$(zk_select_workspace 'workspace> ')"

[[ -n "$selected" ]] || exit 0

selected="${selected%%$'\n'*}"
file="${selected##*$sep}"

[[ -f "$file" ]] || {
  print -ru2 -- "ERROR workspace not found: $file"
  exit 1
}

cat -- "$file"
