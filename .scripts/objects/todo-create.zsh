#!/bin/zsh

#------------------------------------------------------------------------------
# todo-create.zsh
# Тип: Object Constructor
# Назначение: создание корректного объекта Todo в notes/
#------------------------------------------------------------------------------

source "${${(%):-%N}:A:h}/../lib/paths.zsh"
source "${${(%):-%N}:A:h}/../lib/uuid.zsh"
source "${${(%):-%N}:A:h}/../lib/asciidoc.zsh"

zk_todo_create() {
  emulate -L zsh

  local title="$1"
  local keywords="${2:-todo}"
  local description="${3:-$title}"
  local fname
  local target_path
  local attr
  local -a extra_attrs

  extra_attrs=("${@:4}")

  [[ -n "$title" ]] || {
    print -ru2 -- "ERROR todo title is empty"
    return 1
  }

  zk_validate_extra_attrs "${extra_attrs[@]}" || return 1

  zk_ensure_notes_dir || return 1
  fname="$(zk_new_adoc_filename)" || return 1
  target_path="$(zk_note_path "$fname")"

  [[ ! -e "$target_path" ]] || {
    print -ru2 -- "ERROR target already exists: $target_path"
    return 1
  }

  {
    zk_metadata "$fname" "$title" "$keywords" "todo" "$description"

    for attr in "${extra_attrs[@]}"; do
      [[ -n "$attr" ]] && print -r -- "$attr"
    done

    print -r -- ""
    print -r -- "== TODO"
    print -r -- ""
    print -r -- "* [ ] "
  } > "$target_path" || {
    rm -f "$target_path"
    return 1
  }

  print -r -- "$fname"
}

if [[ "$ZSH_EVAL_CONTEXT" == "toplevel" ]]; then
  zk_todo_create "$@"
fi
