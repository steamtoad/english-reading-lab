#!/bin/zsh

#------------------------------------------------------------------------------
# zt-todo.zsh
# Тип: Compatibility Entrypoint
# Назначение: совместимый запуск канонического workflow из zettelkasten/
#------------------------------------------------------------------------------

script_dir="${0:A:h}"
exec "$script_dir/zettelkasten/zt-todo.zsh" "$@"
