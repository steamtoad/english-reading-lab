#!/bin/zsh

#------------------------------------------------------------------------------
# uuid.zsh
# Тип: Library
# Назначение: генерация UUID-имен файлов
#------------------------------------------------------------------------------

zk_uuid() {
  emulate -L zsh

  local os

  os="$(uname -s 2>/dev/null)" || {
    print -ru2 -- "ERROR cannot determine operating system for UUID generation"
    return 1
  }

  case "$os" in
    Linux)
      command -v uuidgen >/dev/null 2>&1 || {
        print -ru2 -- "ERROR required command not found: uuidgen"
        return 1
      }
      uuidgen -t
      ;;
    Darwin)
      command -v uuid >/dev/null 2>&1 || {
        print -ru2 -- "ERROR required command not found: uuid"
        return 1
      }
      uuid
      ;;
    *)
      print -ru2 -- "ERROR unsupported operating system for UUID v1 generation: $os"
      return 1
      ;;
  esac
}

zk_new_adoc_filename() {
  emulate -L zsh

  local id

  id="$(zk_uuid)" || return 1
  [[ -n "$id" ]] || return 1

  print -r -- "${id}.adoc"
}
