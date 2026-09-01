#!/bin/zsh

#------------------------------------------------------------------------------
# erl-delta-test-naming-gate.zsh
# Тип: ERL development-check regression test
# Назначение: проверить lifecycle-aware gate primary regression tests OpenSpec changes
#------------------------------------------------------------------------------

emulate -L zsh
setopt errexit pipe_fail no_unset

repo="${0:A:h:h}"
checker="$repo/.scripts/erl/dev/erl-delta-test-naming-check.zsh"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/erl-delta-test-naming-gate.XXXXXX")"
trap 'rm -rf -- "$fixture"' EXIT HUP INT TERM

reset_fixture() {
  rm -rf -- "$fixture/repo"
  mkdir -p "$fixture/repo/openspec/changes" "$fixture/repo/tests"
}

write_tasks() {
  local change_name="$1"
  local task_lines="$2"
  mkdir -p "$fixture/repo/openspec/changes/$change_name"
  print -r -- "## 1. Fixture

$task_lines" > "$fixture/repo/openspec/changes/$change_name/tasks.md"
}

expect_failure() {
  local expected="$1"
  local output
  local rc

  set +e
  output="$("$checker" "$fixture/repo" 2>&1)"
  rc=$?
  set -e

  [[ "$rc" == 10 ]] || {
    print -ru2 -- "FAIL: expected naming checker exit 10, got $rc"
    print -ru2 -- "$output"
    return 1
  }
  [[ "$output" == *"$expected"* ]] || {
    print -ru2 -- "FAIL: missing expected diagnostic: $expected"
    print -ru2 -- "$output"
    return 1
  }
}

reset_fixture
write_tasks add-openclaw-agent-setup '- [ ] 1.1 Implement setup regression'
write_tasks fix-partial $'- [x] 1.1 Implement first part\n- [ ] 1.2 Complete implementation'
mkdir -p "$fixture/repo/openspec/changes/no-tasks-yet"
"$checker" "$fixture/repo" >/dev/null

reset_fixture
write_tasks fix-completed '- [x] 1.1 Complete implementation'
expect_failure 'OpenSpec change fix-completed requires regression test erl-completed.zsh'

touch "$fixture/repo/tests/erl-completed-extra.zsh"
expect_failure 'OpenSpec change fix-completed requires regression test erl-completed.zsh'

touch "$fixture/repo/tests/erl-completed.zsh"
"$checker" "$fixture/repo" >/dev/null

for fixture_case in \
  'fix-alpha:erl-alpha.zsh' \
  'add-beta:erl-beta.zsh' \
  'custom-gamma:erl-custom-gamma.zsh' \
  'fix-add-delta:erl-add-delta.zsh'; do
  change_name="${fixture_case%%:*}"
  expected_test="${fixture_case#*:}"
  reset_fixture
  write_tasks "$change_name" '- [x] 1.1 Complete implementation'
  touch "$fixture/repo/tests/$expected_test"
  "$checker" "$fixture/repo" >/dev/null
done

reset_fixture
mkdir -p "$fixture/repo/openspec/changes/archive/completed/tasks"
"$checker" "$fixture/repo" >/dev/null

print -r -- 'PASS: ERL delta test naming lifecycle gate'
