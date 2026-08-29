#!/bin/zsh

#------------------------------------------------------------------------------
# zt-scripts-patch.zsh
# Тип: Maintenance
# Назначение: исправление оформления shell-скриптов
#------------------------------------------------------------------------------

cd "$HOME/zettelkasten/.scripts" || exit 1

for f in ./*.zsh; do
  [[ -f "$f" ]] || continue

  if [[ "$(tail -c 1 "$f")" != $'\n' ]]; then
    print -r -- "" >> "$f"
    print -r -- "patched: ${f#./}"
  else
    print -r -- "ok: ${f#./}"
  fi
done
