#!/bin/zsh

#------------------------------------------------------------------------------
# topic-create.zsh
# Тип: Object Constructor
# Назначение: создание и запись корректного объекта Topic
#------------------------------------------------------------------------------

source "${${(%):-%N}:A:h}/../lib/paths.zsh"
source "${${(%):-%N}:A:h}/../lib/uuid.zsh"
source "${${(%):-%N}:A:h}/../lib/asciidoc.zsh"

zk_topic_write() {
  emulate -L zsh

  local output_file="$1"
  local fname="$2"
  local title="$3"
  local key_topic="$4"
  local keywords="${5:-topic}"
  local description="${6:-$title}"

  [[ -n "$output_file" ]] || {
    print -ru2 -- "ERROR topic output file is empty"
    return 1
  }

  [[ -n "$fname" ]] || {
    print -ru2 -- "ERROR topic filename is empty"
    return 1
  }

  [[ -n "$title" ]] || {
    print -ru2 -- "ERROR topic title is empty"
    return 1
  }

  [[ -n "$key_topic" ]] || {
    print -ru2 -- "ERROR :key-topic: is empty"
    return 1
  }

  {
    zk_metadata "$fname" "$title" "$keywords" "topic" "$description"
    print -r -- ":key-topic: $key_topic"
    print -r -- ""
    print -r -- ""
  } > "$output_file"
}

zk_topic_create() {
  emulate -L zsh

  local title="$1"
  local key_topic="$2"
  local keywords="${3:-topic}"
  local description="${4:-$title}"
  local fname
  local target_path

  zk_ensure_notes_dir || return 1
  fname="$(zk_new_adoc_filename)" || return 1
  target_path="$(zk_note_path "$fname")"

  [[ ! -e "$target_path" ]] || {
    print -ru2 -- "ERROR target already exists: $target_path"
    return 1
  }

  zk_topic_write "$target_path" "$fname" "$title" "$key_topic" "$keywords" "$description" || {
    rm -f "$target_path"
    return 1
  }

  print -r -- "$fname"
}

if [[ "$ZSH_EVAL_CONTEXT" == "toplevel" ]]; then
  zk_topic_create "$@"
fi
