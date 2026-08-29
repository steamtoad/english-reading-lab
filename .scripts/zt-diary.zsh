#!/bin/zsh

#------------------------------------------------------------------------------
# zt-diary.zsh
# Тип: Diary
# Назначение: создание дневниковой записи
#------------------------------------------------------------------------------

emulate -L zsh

script_dir="${0:A:h}"

source "$script_dir/lib/paths.zsh"
source "$script_dir/lib/uuid.zsh"
source "$script_dir/lib/asciidoc.zsh"

zk_ensure_dirs
zk_cd_notes

last_diary_file="$(zk_last_diary_file)"

last=""
[[ -f "$last_diary_file" ]] && last="$(< "$last_diary_file")"

fname="$(zk_new_adoc_filename)"
title="Diary - $(date +"%d-%m-%Y")"
link="$(zk_link "$fname" "$title")"
next_link="$(zk_link "$fname" "Следующая запись")"

zk_today_entry "$fname" "$title" >> "$(zk_today_file)"

{
  zk_metadata "$fname" "$title" "diary" "diary"

  if [[ -n "$last" && -f "$last" ]]; then
    print -r -- ""
    print -r -- "$(zk_link "$last" "Предыдущая запись")"
  fi

  print -r -- ""
} > "$fname"

if [[ -n "$last" && -f "$last" ]]; then
  print -r -- "| $next_link" >> "$last"
fi

print -r -- "$fname" > "$last_diary_file"

vim "$fname"

print -r -- "$link"