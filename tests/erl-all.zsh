#!/bin/zsh

#------------------------------------------------------------------------------
# erl-all.zsh
# Тип: ERL test suite
# Назначение: запустить syntax, skill, static-checker, validation, CLI и optional live routing tests
#------------------------------------------------------------------------------

emulate -L zsh
setopt errexit pipe_fail no_unset

repo="${0:A:h:h}"

while IFS= read -r shell_file; do
  zsh -n "$shell_file"
done < <(find "$repo/.scripts/erl" "$repo/tests" -type f -name '*.zsh' | sort)

"$repo/.scripts/erl/dev/erl-skills-check.zsh"
"$repo/tests/erl-skills-check.zsh"
"$repo/tests/erl-check.zsh"
"$repo/tests/erl-cli.zsh"
"$repo/tests/erl-agent-routing.zsh"

git -C "$repo" diff --check
print -r -- 'PASS: complete ERL test suite'
