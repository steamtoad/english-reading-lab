#!/bin/zsh

#------------------------------------------------------------------------------
# zt-keytopic.zsh
# Тип: Topic Workflow
# Назначение: интерактивное создание ключевой Topic по правилам Zettelkasten
#------------------------------------------------------------------------------

emulate -L zsh

script_dir="${0:A:h}"
scripts_dir="${script_dir:h}"

source "$scripts_dir/lib/paths.zsh"
source "$scripts_dir/lib/asciidoc.zsh"
source "$scripts_dir/objects/topic-create.zsh"
source "$script_dir/lib/today.zsh"

read -r "?Введите название для новой ключевой темы: " key
[[ -n "$key" ]] || exit 1

title="$key - ключевая тема"
fname="$(zk_topic_create "$title" "$key" "topic" "$title")" || exit 1
link="$(zk_link "$fname" "$title")"

zt_today_append "$fname" "$title" || exit 1
vim "$(zk_note_path "$fname")"
print -r -- "$link"
