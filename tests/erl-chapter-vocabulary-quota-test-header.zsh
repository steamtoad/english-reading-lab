#!/bin/zsh

#------------------------------------------------------------------------------
# erl-chapter-vocabulary-quota-test-header.zsh
# Тип: ERL test hygiene regression test
# Назначение: проверить canonical header и исходные quota assertions целевого теста
#------------------------------------------------------------------------------

emulate -L zsh
setopt errexit pipe_fail no_unset

repo="${0:A:h:h}"
target="$repo/tests/erl-chapter-vocabulary-quota.zsh"

[[ "$(sed -n '1p' "$target")" == '#!/usr/bin/env zsh' ]] || {
  print -ru2 -- 'FAIL: unexpected target shebang'
  exit 1
}
[[ -z "$(sed -n '2p' "$target")" ]] || {
  print -ru2 -- 'FAIL: target header is not separated from shebang'
  exit 1
}
[[ "$(sed -n '3p' "$target")" == '#------------------------------------------------------------------------------' ]] || {
  print -ru2 -- 'FAIL: missing opening header separator'
  exit 1
}
[[ "$(sed -n '4p' "$target")" == '# erl-chapter-vocabulary-quota.zsh' ]] || {
  print -ru2 -- 'FAIL: header does not contain the full filename'
  exit 1
}
[[ "$(sed -n '5p' "$target")" == '# Тип: ERL OpenSpec regression test' ]] || {
  print -ru2 -- 'FAIL: unexpected header type'
  exit 1
}
[[ "$(sed -n '6p' "$target")" == '# Назначение: проверить отсутствие Candidate quota в Chapter extraction policy' ]] || {
  print -ru2 -- 'FAIL: unexpected header purpose'
  exit 1
}
[[ "$(sed -n '7p' "$target")" == '#------------------------------------------------------------------------------' ]] || {
  print -ru2 -- 'FAIL: missing closing header separator'
  exit 1
}

"$target"

print -r -- 'PASS: Chapter vocabulary quota test header'
