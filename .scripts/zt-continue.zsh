#!/bin/zsh

#------------------------------------------------------------------------------
# zt-continue.zsh
# Тип: Memo Chain
# Назначение: создание memo-продолжения с двусторонней навигацией
#------------------------------------------------------------------------------

emulate -L zsh
setopt null_glob

script_dir="${0:A:h}"

source "$script_dir/lib/paths.zsh"
source "$script_dir/lib/uuid.zsh"
source "$script_dir/lib/asciidoc.zsh"

sep=$'\x1f'

select_memo_file() {
  local file
  local description

  for file in *.adoc; do
    zk_is_deprecated "$file" && continue
    [[ "$(zk_attr_value "$file" "type")" == "memo" ]] || continue

    description="$(zk_link_description "$file")"
    print -r -- "${file} - ${description}${sep}${file}"
  done |
    fzf \
      --delimiter="$sep" \
      --with-nth=1 \
      --prompt='continue memo> '
}

extract_memo_chain_link() {
  local file="$1"
  local label="$2"

  awk -v label="$label" '
    index($0, label) {
      if (match($0, /link:[^[]+\.adoc\[/)) {
        print substr($0, RSTART + 5, RLENGTH - 6)
        exit
      }
    }
  ' "$file"
}

zk_ensure_dirs
zk_cd_notes

selected="$(select_memo_file)"
[[ -n "$selected" ]] || exit 0

selected="${selected%%$'\n'*}"
source_file="${selected##*$sep}"

existing_next="$(extract_memo_chain_link "$source_file" "Следующее memo")"

read -r "?Введите название продолжения memo: " key
[[ -n "$key" ]] || exit 1

source_description="$(zk_link_description "$source_file")"
source_keywords="$(zk_attr_value "$source_file" "keywords")"
source_key_topic_line="$(zk_attr_line "$source_file" "key-topic")"

new_fname="$(zk_new_adoc_filename)" || exit 1
title="Memo - $key от $(date +"%d-%m-%Y")"

new_description="$title"

new_link="$(zk_link "$new_fname" "$new_description")"
previous_link="$(zk_link "$source_file" "Предыдущее memo")"

if [[ -n "$existing_next" ]]; then
  forward_link="$(zk_link "$new_fname" "Ветка: ${new_description}")"
else
  forward_link="$(zk_link "$new_fname" "Следующее memo")"
fi

zk_today_entry "$new_fname" "$title" >> "$(zk_today_file)"

{
  zk_metadata "$new_fname" "$title" "$source_keywords" "memo"

  if [[ -n "$source_key_topic_line" ]]; then
    print -r -- "$source_key_topic_line"
  fi

  print -r -- ""
  print -r -- ""
  print -r -- "$previous_link"
} > "$new_fname"

print -r -- "| $forward_link" >> "$source_file"

vim "$new_fname"

print -r -- "$new_link"