#!/bin/zsh

#------------------------------------------------------------------------------
# zt-memo.zsh
# Тип: Memo
# Назначение: создание memo с опциональной привязкой к key topic
#------------------------------------------------------------------------------

emulate -L zsh
setopt null_glob

script_dir="${0:A:h}"

source "$script_dir/lib/paths.zsh"
source "$script_dir/lib/uuid.zsh"
source "$script_dir/lib/asciidoc.zsh"

sep=$'\x1f'

select_topic_binding() {
  {
    print -r -- "Нет"
    print -r -- "Да"
  } | fzf --prompt='Привязать memo к key topic? '
}

select_keytopic_file() {
  local file
  local description

  for file in *.adoc; do
    zk_is_deprecated "$file" && continue
    [[ "$(zk_attr_value "$file" "type")" == "topic" ]] || continue

    description="$(zk_link_description "$file")"

    print -r -- "${file} - ${description}${sep}${file}"
  done |
    fzf \
      --delimiter="$sep" \
      --with-nth=1 \
      --prompt='topic> '
}

zk_ensure_dirs
zk_cd_notes

read -r "?Введите название для нового Memo: " key

[[ -z "$key" ]] && exit 1

topic_file=""
topic_key_line=""
topic_keywords=""
memo_keywords="memo"

binding="$(select_topic_binding)"

if [[ "$binding" == "Да" ]]; then
  selected="$(select_keytopic_file)"

  if [[ -n "$selected" ]]; then
    selected="${selected%%$'\n'*}"
    topic_file="${selected##*$sep}"

    topic_key_line="$(zk_attr_line "$topic_file" "key-topic")"
    topic_keywords="$(zk_attr_value "$topic_file" "keywords")"

    if [[ -n "$topic_keywords" ]]; then
      memo_keywords="$(zk_keywords_for_type_from_topic "$topic_keywords" "memo")"
    fi
  fi
fi

fname="$(zk_new_adoc_filename)"
title="Memo - $key от $(date +"%d-%m-%Y")"
link="$(zk_link "$fname" "$title")"

zk_today_entry "$fname" "$title" >> "$(zk_today_file)"

{
  zk_metadata "$fname" "$title" "$memo_keywords" "memo"

  if [[ -n "$topic_key_line" ]]; then
    print -r -- "$topic_key_line"
  fi

  print -r -- ""
  print -r -- ""
} > "$fname"

if [[ -n "$topic_file" ]]; then
  topic_description="$(zk_link_description "$topic_file")"
  memo_description="$(zk_link_description "$fname")"

  topic_link="$(zk_link "$topic_file" "$topic_description")"
  memo_link="$(zk_link "$fname" "$memo_description")"

  zk_append_related_link "$fname" "== Связи" "Topic" "$topic_link"
  zk_append_related_link "$topic_file" "== Связанные memo" "" "$memo_link"
fi

vim "$fname"

print -r -- "$link"