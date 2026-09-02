#!/bin/zsh

#------------------------------------------------------------------------------
# erl-delta-primary-test-contract.zsh
# Тип: ERL development-contract regression test
# Назначение: проверить обязательный primary test и deterministic change-prefix mapping
#------------------------------------------------------------------------------

emulate -L zsh
setopt errexit pipe_fail no_unset

repo="${0:A:h:h}"
checker="$repo/.scripts/erl/dev/erl-delta-test-naming-check.zsh"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/erl-delta-primary-test.XXXXXX")"
trap 'rm -rf -- "$fixture"' EXIT HUP INT TERM

write_completed_change() {
  local change_name="$1"
  mkdir -p "$fixture/repo/openspec/changes/$change_name"
  print -r -- '## 1. Fixture

- [x] 1.1 Complete implementation' > "$fixture/repo/openspec/changes/$change_name/tasks.md"
}

reset_fixture() {
  rm -rf -- "$fixture/repo"
  mkdir -p "$fixture/repo/openspec/changes" "$fixture/repo/tests"
}

for fixture_case in \
  'fix-alpha:erl-alpha.zsh' \
  'add-beta:erl-beta.zsh' \
  'change-gamma:erl-gamma.zsh' \
  'update-delta:erl-delta.zsh' \
  'migrate-epsilon:erl-epsilon.zsh' \
  'refactor-zeta:erl-zeta.zsh' \
  'implement-eta:erl-eta.zsh' \
  'remove-theta:erl-theta.zsh' \
  'custom-iota:erl-custom-iota.zsh' \
  'fix-add-kappa:erl-add-kappa.zsh'; do
  change_name="${fixture_case%%:*}"
  expected_test="${fixture_case#*:}"
  reset_fixture
  write_completed_change "$change_name"
  touch "$fixture/repo/tests/$expected_test"
  "$checker" "$fixture/repo" >/dev/null
done

# The active removal delta uses the existing canonical test without a duplicate
# filename that retains the action prefix.
reset_fixture
write_completed_change remove-chapter-vocabulary-quota
touch "$fixture/repo/tests/erl-remove-chapter-vocabulary-quota.zsh"
set +e
output="$("$checker" "$fixture/repo" 2>&1)"
rc=$?
set -e
[[ "$rc" == 10 && "$output" == *'remove-chapter-vocabulary-quota'* && "$output" == *'erl-chapter-vocabulary-quota.zsh'* ]] || {
  print -ru2 -- 'FAIL: remove- diagnostic did not require the canonical derived test'
  exit 1
}
touch "$fixture/repo/tests/erl-chapter-vocabulary-quota.zsh"
"$checker" "$fixture/repo" >/dev/null

# Planning-only changes remain non-blocking until their implementation tasks
# are complete.
reset_fixture
mkdir -p "$fixture/repo/openspec/changes/fix-planning"
print -r -- '## 1. Fixture

- [ ] 1.1 Implement behavior' > "$fixture/repo/openspec/changes/fix-planning/tasks.md"
"$checker" "$fixture/repo" >/dev/null
sed -i.bak 's/- \[ \]/- [x]/' "$fixture/repo/openspec/changes/fix-planning/tasks.md"
rm -f -- "$fixture/repo/openspec/changes/fix-planning/tasks.md.bak"
set +e
output="$("$checker" "$fixture/repo" 2>&1)"
rc=$?
set -e
[[ "$rc" == 10 && "$output" == *'fix-planning'* && "$output" == *'erl-planning.zsh'* ]] || {
  print -ru2 -- 'FAIL: completed change without primary test was not blocked'
  exit 1
}

rg -q 'fix-/add-/change-/update-/migrate-/refactor-/implement-/remove-' "$repo/.scripts/erl/docs/requirements.md"
rg -q 'каждая ERL OpenSpec delta содержит task на derived primary regression test' "$repo/AGENTS.MD"
rg -q 'primary regression test текущей delta существует и успешно запущен до completion/archive' "$repo/AGENTS.MD"

print -r -- 'PASS: ERL delta primary-test contract'
