#!/bin/zsh

#------------------------------------------------------------------------------
# bindings.zsh
# Тип: Zettelkasten Library
# Назначение: Topic→Memo и Memo→Note binding policy
#------------------------------------------------------------------------------

zt_require_fzf() {
  command -v fzf >/dev/null 2>&1 || {
    print -ru2 -- "ERROR required command not found: fzf"
    return 1
  }
}

zt_select_yes_no() {
  local prompt="$1"

  {
    print -r -- "Нет"
    print -r -- "Да"
  } | fzf --prompt="$prompt"
}

zt_select_file_by_type() {
  emulate -L zsh
  setopt local_options null_glob

  local type="$1"
  local prompt="$2"
  local sep=$'\x1f'
  local candidate_path
  local file
  local description

  for candidate_path in "$(zk_notes_dir)"/*.adoc; do
    [[ -f "$candidate_path" ]] || continue
    zk_is_deprecated "$candidate_path" && continue
    [[ "$(zk_attr_value "$candidate_path" "type")" == "$type" ]] || continue
    if [[ "$type" == "topic" ]]; then
      [[ -n "$(zk_attr_value "$candidate_path" "key-topic")" ]] || continue
    fi

    file="${candidate_path:t}"
    description="$(zk_link_description "$candidate_path")"
    print -r -- "${file} - ${description}${sep}${file}"
  done |
    fzf \
      --delimiter="$sep" \
      --with-nth=1 \
      --prompt="$prompt"
}

zt_select_memo_binding() {
  zt_select_yes_no 'Привязать note к memo? '
}

zt_select_topic_binding() {
  zt_select_yes_no 'Привязать memo к key topic? '
}

zt_select_memo_file() {
  zt_select_file_by_type "memo" "memo> "
}

zt_select_keytopic_file() {
  zt_select_file_by_type "topic" "topic> "
}

zt_selected_filename() {
  local selected="$1"
  local sep=$'\x1f'

  selected="${selected%%$'\n'*}"
  print -r -- "${selected##*$sep}"
}

zt_keywords_for_note_from_memo() {
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

zt_keywords_for_type_from_topic() {
  local keywords="$1"
  local new_type="$2"

  print -r -- "$keywords" |
    awk -v new_type="$new_type" '
      BEGIN {
        FS = ","
      }

      {
        add(new_type)

        for (i = 1; i <= NF; i++) {
          item = $i
          gsub(/^[[:space:]]+/, "", item)
          gsub(/[[:space:]]+$/, "", item)

          if (item == "") continue
          if (item == "topic") continue
          if (item == new_type) continue
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

zt_bind_note_to_memo() {
  local note_fname="$1"
  local memo_fname="$2"
  local note_file="$(zk_note_path "$note_fname")"
  local memo_file="$(zk_note_path "$memo_fname")"
  local memo_description
  local note_description
  local memo_link
  local note_link

  [[ -f "$note_file" ]] || {
    print -ru2 -- "ERROR note target not found: $note_file"
    return 1
  }

  [[ -f "$memo_file" ]] || {
    print -ru2 -- "ERROR memo target not found: $memo_file"
    return 1
  }

  memo_description="$(zk_link_description "$memo_file")"
  note_description="$(zk_link_description "$note_file")"
  memo_link="$(zk_link "$memo_fname" "$memo_description")"
  note_link="$(zk_link "$note_fname" "$note_description")"

  zk_append_related_link "$note_file" "== Связи" "Memo" "$memo_link" || return 1
  zk_append_related_link "$memo_file" "== Связанные note" "" "$note_link"
}

zt_bind_memo_to_topic() {
  local memo_fname="$1"
  local topic_fname="$2"
  local memo_file="$(zk_note_path "$memo_fname")"
  local topic_file="$(zk_note_path "$topic_fname")"
  local topic_description
  local memo_description
  local topic_link
  local memo_link

  [[ -f "$memo_file" ]] || {
    print -ru2 -- "ERROR memo target not found: $memo_file"
    return 1
  }

  [[ -f "$topic_file" ]] || {
    print -ru2 -- "ERROR topic target not found: $topic_file"
    return 1
  }

  topic_description="$(zk_link_description "$topic_file")"
  memo_description="$(zk_link_description "$memo_file")"
  topic_link="$(zk_link "$topic_fname" "$topic_description")"
  memo_link="$(zk_link "$memo_fname" "$memo_description")"

  zk_append_related_link "$memo_file" "== Связи" "Topic" "$topic_link" || return 1
  zk_append_related_link "$topic_file" "== Связанные memo" "" "$memo_link"
}
