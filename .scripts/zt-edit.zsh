#!/bin/zsh

#------------------------------------------------------------------------------
# zt-edit.zsh
# Тип: Navigation
# Назначение: выбор заметки по :description: и открытие в vim
#------------------------------------------------------------------------------

emulate -L zsh
setopt null_glob

script_dir="${0:A:h}"
source "$script_dir/lib/paths.zsh"
source "$script_dir/lib/asciidoc.zsh"

sep=$'\x1f'

zk_cd_notes || exit 1

selected="$(
  for file in *.adoc; do
    zk_is_deprecated "$file" && continue

    description="$(zk_attr_value "$file" "description")"

    [[ -n "$description" ]] || continue

    print -r -- "${description} - ${file}${sep}${file}"
  done |
  fzf \
    --delimiter="$sep" \
    --with-nth=1 \
    --prompt='zettel> '
)"

[[ -n "$selected" ]] || exit 0

selected="${selected%%$'\n'*}"
file="${selected##*$sep}"

vim "$file"
