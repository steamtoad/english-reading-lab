#!/bin/zsh

#------------------------------------------------------------------------------
# zt-read.zsh
# Тип: Search
# Назначение: чтение найденных заметок
#------------------------------------------------------------------------------

emulate -L zsh
setopt null_glob

script_dir="${0:A:h}"
source "$script_dir/lib/paths.zsh"
source "$script_dir/lib/asciidoc.zsh"

read -r "?Введите ключевое слово для поиска: " key

[[ -z "$key" ]] && exit 1

zk_cd

print -r -- "= Листинг заметок по ключевому слову $key от $(date +"%d-%m-%Y")"
print -r -- ":date: $(date +"%Y-%m-%d")"
print -r -- ":keywords: $key, list"
print -r -- ":type: list"
print -r -- ":description: Листинг заметок по ключевому слову $key от $(date +"%d-%m-%Y")"
print -r -- ""

for file in notes/*.adoc; do
  zk_is_deprecated "$file" && continue
  grep -qi -- "$key" "$file" || continue

  cat "$file"
  print -r -- ""
done
