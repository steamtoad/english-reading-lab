#!/bin/zsh

#------------------------------------------------------------------------------
# erl-delta-test-naming-check.zsh
# Тип: ERL development check
# Назначение: проверить deterministic naming primary regression tests OpenSpec changes
#------------------------------------------------------------------------------

emulate -L zsh
setopt errexit pipe_fail no_unset

repo="${1:-${0:A:h:h:h:h}}"
[[ -d "$repo/openspec/changes" && -d "$repo/tests" ]] || {
  print -ru2 -- "FAIL: invalid ERL repository layout: $repo"
  exit 2
}

for change_dir in "$repo/openspec/changes"/*(/N); do
  [[ "${change_dir:t}" == archive ]] && continue
  change_name="${change_dir:t}"
  tasks_file="$change_dir/tasks.md"

  [[ -f "$tasks_file" ]] || continue
  rg -q '^- \[[ xX]\] [0-9]+\.[0-9]+ ' "$tasks_file" || continue
  rg -q '^- \[ \] [0-9]+\.[0-9]+ ' "$tasks_file" && continue

  behavior_slug="$(print -r -- "$change_name" | sed -E 's/^(fix|add|change|update|migrate|refactor|implement)-//')"
  expected_regression="$repo/tests/erl-$behavior_slug.zsh"
  [[ -f "$expected_regression" ]] || {
    print -ru2 -- "FAIL: OpenSpec change $change_name requires regression test ${expected_regression:t}"
    exit 10
  }
done

print -r -- 'PASS: ERL OpenSpec regression-test naming'
