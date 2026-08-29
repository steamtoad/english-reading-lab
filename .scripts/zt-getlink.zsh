#!/bin/zsh

#------------------------------------------------------------------------------
# zt-getlink.zsh
# Тип: Link
# Назначение: генерация AsciiDoc-ссылки на заметку по :description:
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

    print -r -- "${description} - ${file}${sep}${file}${sep}${description}"
  done |
  fzf \
    --delimiter="$sep" \
    --with-nth=1 \
    --prompt='link> '
)"

[[ -n "$selected" ]] || exit 0

selected="${selected%%$'\n'*}"
file="${${selected#*$sep}%%$sep*}"
description="${selected##*$sep}"

zk_link "$file" "$description"
