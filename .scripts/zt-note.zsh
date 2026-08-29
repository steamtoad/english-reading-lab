#!/bin/zsh

#------------------------------------------------------------------------------
# zt-note.zsh
# Тип: Note
# Назначение: создание note с опциональной привязкой к memo
#------------------------------------------------------------------------------

emulate -L zsh
setopt null_glob

script_dir="${0:A:h}"

source "$script_dir/lib/paths.zsh"
source "$script_dir/lib/uuid.zsh"
source "$script_dir/lib/asciidoc.zsh"

sep=$'\x1f'

select_memo_binding() {
  {
    print -r -- "Нет"
    print -r -- "Да"
  } | fzf --prompt='Привязать note к memo? '
}

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
      --prompt='memo> '
}

zk_keywords_for_note_from_memo() {
  local keywords="$1"

  print -r -- "$keywords" |
    awk '
      BEGIN {
        FS = ","
        add("note")
      }

      {
        for (i = 1; i <= NF; i++) {
          item = $i
          gsub(/^[[:space:]]+/, "", item)
          gsub(/[[:space:]]+$/, "", item)

          if (item == "") continue
          if (item == "memo") continue
          add(item)
        }

        for (i = 1; i <= count; i++) {
          if (i > 1) printf ", "
          printf "%s", order[i]
        }

        printf "\n"
      }

      function add(item) {
        if (!(item in seen)) {
          seen[item] = 1
          order[++count] = item
        }
      }
    '
}

zk_ensure_dirs
zk_cd_notes

read -r "?Введите название для новой заметки: " key

[[ -z "$key" ]] && exit 1

memo_file=""
memo_key_line=""
memo_keywords=""
note_keywords="note"

binding="$(select_memo_binding)"

if [[ "$binding" == "Да" ]]; then
  selected="$(select_memo_file)"

  if [[ -n "$selected" ]]; then
    selected="${selected%%$'\n'*}"
    memo_file="${selected##*$sep}"

    memo_key_line="$(zk_attr_line "$memo_file" "key-topic")"
    memo_keywords="$(zk_attr_value "$memo_file" "keywords")"

    if [[ -n "$memo_keywords" ]]; then
      note_keywords="$(zk_keywords_for_note_from_memo "$memo_keywords")"
    fi
  fi
fi

fname="$(zk_new_adoc_filename)"
title="$key"
link="$(zk_link "$fname" "$title")"

zk_today_entry "$fname" "$title" >> "$(zk_today_file)"

{
  zk_metadata "$fname" "$title" "$note_keywords" "note"

  if [[ -n "$memo_key_line" ]]; then
    print -r -- "$memo_key_line"
  fi

  print -r -- ""
  print -r -- ""
} > "$fname"

if [[ -n "$memo_file" ]]; then
  memo_description="$(zk_link_description "$memo_file")"
  note_description="$(zk_link_description "$fname")"

  memo_link="$(zk_link "$memo_file" "$memo_description")"
  note_link="$(zk_link "$fname" "$note_description")"

  zk_append_related_link "$fname" "== Связи" "Memo" "$memo_link"
  zk_append_related_link "$memo_file" "== Связанные note" "" "$note_link"
fi

vim "$fname"

print -r -- "$link"