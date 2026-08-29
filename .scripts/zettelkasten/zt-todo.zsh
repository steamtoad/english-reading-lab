#!/bin/zsh

#------------------------------------------------------------------------------
# zt-todo.zsh
# Тип: Todo Workflow
# Назначение: интерактивное создание Todo по правилам Zettelkasten
#------------------------------------------------------------------------------

emulate -L zsh

script_dir="${0:A:h}"
scripts_dir="${script_dir:h}"

source "$scripts_dir/lib/paths.zsh"
source "$scripts_dir/lib/asciidoc.zsh"
source "$scripts_dir/objects/todo-create.zsh"
source "$script_dir/lib/today.zsh"

read -r "?Введите название для нового списка дел Todo: " key
[[ -n "$key" ]] || exit 1

title="TODO - $key от $(date +"%d-%m-%Y")"
fname="$(zk_todo_create "$title" "todo" "$title")" || exit 1
link="$(zk_link "$fname" "$title")"

zt_today_append "$fname" "$title" || exit 1
vim "$(zk_note_path "$fname")"
print -r -- "$link"
