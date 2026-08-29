#!/bin/zsh

#------------------------------------------------------------------------------
# zt-todo.zsh
# Тип: TODO
# Назначение: создание списка задач
#------------------------------------------------------------------------------

emulate -L zsh

script_dir="${0:A:h}"

source "$script_dir/lib/paths.zsh"
source "$script_dir/lib/uuid.zsh"
source "$script_dir/lib/asciidoc.zsh"

zk_ensure_dirs
zk_cd_notes

read -r "?Введите название для нового списка дел Todo: " key

[[ -z "$key" ]] && exit 1

fname="$(zk_new_adoc_filename)"
title="TODO - $key от $(date +"%d-%m-%Y")"
link="$(zk_link "$fname" "$title")"

zk_today_entry "$fname" "$title" >> "$(zk_today_file)"

{
  zk_metadata "$fname" "$title" "todo" "todo"
  print -r -- ""
  print -r -- "== TODO"
  print -r -- ""
  print -r -- "* [ ] "
} > "$fname"

vim "$fname"

print -r -- "$link"