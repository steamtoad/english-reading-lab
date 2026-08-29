#!/bin/zsh

#------------------------------------------------------------------------------
# zt-workspace-create.zsh
# Тип: Workspace
# Назначение: создание рабочей области в workspaces/
#------------------------------------------------------------------------------

emulate -L zsh

script_dir="${0:A:h}"
source "$script_dir/lib/paths.zsh"
source "$script_dir/lib/workspace.zsh"

read -r "?Введите название рабочего места: " title
title="${title#"${title%%[![:space:]]*}"}"
title="${title%"${title##*[![:space:]]}"}"

fname="$(zk_workspace_filename "$title")" || {
  print -ru2 -- "ERROR invalid workspace title"
  exit 1
}

zk="$(zk_home)"
workspaces_dir="$(zk_workspaces_dir)"
workspace_path="$workspaces_dir/$fname"

[[ -d "$zk" ]] || {
  print -ru2 -- "ERROR Zettelkasten not found: $zk"
  exit 1
}

mkdir -p "$workspaces_dir" || exit 1

if [[ -e "$workspace_path" ]]; then
  print -ru2 -- "ERROR workspace already exists: workspaces/$fname"
  exit 1
fi

{
  print -r -- "= $title"
  print -r -- ""
  print -r -- "== Документы"
  print -r -- ""
} > "$workspace_path" || exit 1

print -r -- "workspaces/$fname"
