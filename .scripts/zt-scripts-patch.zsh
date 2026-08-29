#!/bin/zsh

#------------------------------------------------------------------------------
# zt-scripts-patch.zsh
# Тип: Maintenance
# Назначение: исправление завершающего LF во всех shell-скриптах CLI
#------------------------------------------------------------------------------

emulate -L zsh
setopt extended_glob null_glob

script_dir="${0:A:h}"

for f in "$script_dir"/**/*.zsh(N); do
  [[ -f "$f" ]] || continue

  if [[ "$(tail -c 1 "$f")" != $'\n' ]]; then
    print -r -- "" >> "$f"
    print -r -- "patched: ${f#$script_dir/}"
  else
    print -r -- "ok: ${f#$script_dir/}"
  fi
done
