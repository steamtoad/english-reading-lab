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
source "$script_dir/lib/asciidoc.zsh"
source "$script_dir/objects/memo-create.zsh"
source "$script_dir/zettelkasten/lib/today.zsh"
source "$script_dir/zettelkasten/lib/bindings.zsh"

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

zk_ensure_notes_dir || exit 1
zt_ensure_today || exit 1
zk_cd_notes || exit 1
zt_require_fzf || exit 1

selected="$(zt_select_file_by_type "memo" "continue memo> ")" || exit 0
[[ -n "$selected" ]] || exit 0

source_file="$(zt_selected_filename "$selected")"

existing_next="$(extract_memo_chain_link "$source_file" "Следующее memo")"

read -r "?Введите название продолжения memo: " key
[[ -n "$key" ]] || exit 1

source_keywords="$(zk_attr_value "$source_file" "keywords")"
source_key_topic_line="$(zk_attr_line "$source_file" "key-topic")"

title="Memo - $key от $(date +"%d-%m-%Y")"
new_description="$title"

previous_link="$(zk_link "$source_file" "Предыдущее memo")"

typeset -a extra_attrs
extra_attrs=()
[[ -n "$source_key_topic_line" ]] && extra_attrs+=("$source_key_topic_line")

new_fname="$(zk_memo_create "$title" "$source_keywords" "$new_description" "${extra_attrs[@]}")" || exit 1
new_link="$(zk_link "$new_fname" "$new_description")"

if [[ -n "$existing_next" ]]; then
  forward_link="$(zk_link "$new_fname" "Ветка: ${new_description}")"
else
  forward_link="$(zk_link "$new_fname" "Следующее memo")"
fi

zt_today_append "$new_fname" "$title" || exit 1

{
  print -r -- "$previous_link"
} >> "$new_fname" || exit 1

print -r -- "| $forward_link" >> "$source_file"

vim "$new_fname"

print -r -- "$new_link"
