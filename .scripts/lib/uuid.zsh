#------------------------------------------------------------------------------
# uuid.zsh
# Тип: Library
# Назначение: генерация UUID-имен файлов
#------------------------------------------------------------------------------

zk_uuid() {
  if [[ "$(uname)" == "Linux" ]]; then
    uuidgen -t
  else
    uuid
  fi
}

zk_new_adoc_filename() {
  local id

  id="$(zk_uuid)" || return 1
  [[ -n "$id" ]] || return 1

  print -r -- "${id}.adoc"
}
