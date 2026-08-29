#!/bin/zsh

#------------------------------------------------------------------------------
# zt-scripts-review.zsh
# Тип: Maintenance
# Назначение: вывод всех shell-скриптов Zettelkasten для ревизии
#------------------------------------------------------------------------------

emulate -L zsh
setopt null_glob

zk="${ZK_HOME:-$HOME/zettelkasten}"
scripts_dir="$zk/.scripts"

[[ -d "$scripts_dir" ]] || {
  print -ru2 -- "ERROR .scripts not found: $scripts_dir"
  exit 1
}

cd "$scripts_dir" || exit 1

for f in ./*.zsh ./lib/*.zsh; do
  [[ -f "$f" ]] || continue

  print -r -- ""
  print -r -- "=============================================================================="
  print -r -- "FILE: ${f#./}"
  print -r -- "=============================================================================="
  cat "$f"
done

exit 0
