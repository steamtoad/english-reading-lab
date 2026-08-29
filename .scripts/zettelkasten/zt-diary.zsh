#!/bin/zsh

#------------------------------------------------------------------------------
# zt-diary.zsh
# Тип: Diary Workflow
# Назначение: создание Diary и ведение diary-chain по правилам Zettelkasten
#------------------------------------------------------------------------------

emulate -L zsh

script_dir="${0:A:h}"
scripts_dir="${script_dir:h}"

source "$scripts_dir/lib/paths.zsh"
source "$scripts_dir/lib/asciidoc.zsh"
source "$scripts_dir/objects/diary-create.zsh"
source "$script_dir/lib/today.zsh"

zt_diary_state_file() {
  print -r -- "$(zk_home)/.last-diary"
}

last_diary_file="$(zt_diary_state_file)"
last=""
[[ -f "$last_diary_file" ]] && last="$(< "$last_diary_file")"

if [[ -n "$last" && "$last" == */* ]]; then
  print -ru2 -- "ERROR invalid .last-diary value: $last"
  exit 1
fi

last_path=""
if [[ -n "$last" ]]; then
  last_path="$(zk_note_path "$last")"
fi

title="Diary - $(date +"%d-%m-%Y")"
fname="$(zk_diary_create "$title" "diary" "$title")" || exit 1
diary_path="$(zk_note_path "$fname")"
link="$(zk_link "$fname" "$title")"
next_link="$(zk_link "$fname" "Следующая запись")"

zt_today_append "$fname" "$title" || exit 1

if [[ -n "$last" && -f "$last_path" ]]; then
  {
    print -r -- "$(zk_link "$last" "Предыдущая запись")"
    print -r -- ""
  } >> "$diary_path" || exit 1

  print -r -- "| $next_link" >> "$last_path" || exit 1
fi

print -r -- "$fname" > "$last_diary_file" || exit 1

vim "$diary_path"
print -r -- "$link"
