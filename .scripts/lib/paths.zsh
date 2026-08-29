#!/bin/zsh

#------------------------------------------------------------------------------
# paths.zsh
# Тип: Library
# Назначение: нейтральные пути и storage-примитивы zettelkasten-cli
#------------------------------------------------------------------------------

zk_home() {
  print -r -- "${ZK_HOME:-$HOME/zettelkasten}"
}

zk_notes_dir() {
  print -r -- "$(zk_home)/notes"
}

zk_note_path() {
  local fname="$1"

  print -r -- "$(zk_notes_dir)/$fname"
}

zk_cd() {
  cd "$(zk_home)" || return 1
}

zk_cd_notes() {
  cd "$(zk_notes_dir)" || return 1
}

zk_scripts_dir() {
  print -r -- "$(zk_home)/.scripts"
}

zk_lib_dir() {
  print -r -- "$(zk_scripts_dir)/lib"
}

zk_ensure_notes_dir() {
  mkdir -p "$(zk_notes_dir)"
}
