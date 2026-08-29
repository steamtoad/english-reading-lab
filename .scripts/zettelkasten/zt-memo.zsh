#!/bin/zsh

#------------------------------------------------------------------------------
# zt-memo.zsh
# Тип: Memo Workflow
# Назначение: интерактивное создание Memo по правилам Zettelkasten
#------------------------------------------------------------------------------

emulate -L zsh

script_dir="${0:A:h}"
scripts_dir="${script_dir:h}"

source "$scripts_dir/lib/paths.zsh"
source "$scripts_dir/lib/asciidoc.zsh"
source "$scripts_dir/objects/memo-create.zsh"
source "$script_dir/lib/today.zsh"
source "$script_dir/lib/bindings.zsh"

read -r "?Введите название для нового Memo: " key
[[ -n "$key" ]] || exit 1

zt_require_fzf || exit 1

topic_file=""
topic_key_line=""
memo_keywords="memo"

binding="$(zt_select_topic_binding)" || exit 0

if [[ "$binding" == "Да" ]]; then
  selected="$(zt_select_keytopic_file)" || exit 0
  [[ -n "$selected" ]] || exit 0

  if [[ -n "$selected" ]]; then
    topic_file="$(zt_selected_filename "$selected")"
    topic_path="$(zk_note_path "$topic_file")"
    topic_key_line="$(zk_attr_line "$topic_path" "key-topic")"
    topic_keywords="$(zk_attr_value "$topic_path" "keywords")"

    [[ -n "$topic_key_line" ]] || {
      print -ru2 -- "ERROR selected topic has no header :key-topic:: $topic_file"
      exit 1
    }

    if [[ -n "$topic_keywords" ]]; then
      memo_keywords="$(zt_keywords_for_type_from_topic "$topic_keywords" "memo")"
    fi
  fi
fi

title="Memo - $key от $(date +"%d-%m-%Y")"
typeset -a extra_attrs
extra_attrs=()
[[ -n "$topic_key_line" ]] && extra_attrs+=("$topic_key_line")

fname="$(zk_memo_create "$title" "$memo_keywords" "$title" "${extra_attrs[@]}")" || exit 1
link="$(zk_link "$fname" "$title")"

zt_today_append "$fname" "$title" || exit 1

if [[ -n "$topic_file" ]]; then
  zt_bind_memo_to_topic "$fname" "$topic_file" || exit 1
fi

vim "$(zk_note_path "$fname")"
print -r -- "$link"
