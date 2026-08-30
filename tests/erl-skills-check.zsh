#!/bin/zsh

#------------------------------------------------------------------------------
# erl-skills-check.zsh
# Тип: ERL static-checker regression test
# Назначение: доказать обнаружение routing, executable, authorization и reference regressions
#------------------------------------------------------------------------------

emulate -L zsh
setopt errexit pipe_fail no_unset

repo="${0:A:h:h}"
checker="$repo/.scripts/erl/dev/erl-skills-check.zsh"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/erl-skills-check-test.XXXXXX")"
trap 'rm -rf -- "$fixture"' EXIT HUP INT TERM

run_failure_case() {
  local expected="$1" output rc
  set +e
  output="$(ERL_SKILLS_DIR="$fixture/skills" "$checker" 2>&1)"
  rc=$?
  set -e
  [[ "$rc" == 10 ]] || {
    print -ru2 -- "FAIL: expected static checker exit 10, got $rc"
    print -ru2 -- "$output"
    return 1
  }
  [[ "$output" == *"$expected"* ]] || {
    print -ru2 -- "FAIL: missing expected diagnostic: $expected"
    print -ru2 -- "$output"
    return 1
  }
}

reset_fixture() {
  rm -rf -- "$fixture/skills"
  cp -R "$repo/skills" "$fixture/skills"
}

reset_fixture
ERL_SKILLS_DIR="$fixture/skills" "$checker" >/dev/null

sed -i.bak 's/^description:.*/description: "Use canonical ERL .zsh executables."/' \
  "$fixture/skills/erl-book-ingest/SKILL.md"
rm -f -- "$fixture/skills/erl-book-ingest/SKILL.md.bak"
run_failure_case 'description does not provide the canonical routing contract'

reset_fixture
sed -i.bak 's#<command>\.zsh#<command>#' \
  "$fixture/skills/erl-check/references/erl-agent-contract-v1.md"
rm -f -- "$fixture/skills/erl-check/references/erl-agent-contract-v1.md.bak"
run_failure_case 'extensionless executable template in common contract'

reset_fixture
sed -i.bak 's/^Authorization: L2\.$/Authorization: L1./' \
  "$fixture/skills/erl-book-ingest/SKILL.md"
rm -f -- "$fixture/skills/erl-book-ingest/SKILL.md.bak"
run_failure_case 'authorization level or scope drift'

reset_fixture
print -r -- '\nreference drift' >> \
  "$fixture/skills/erl-vocabulary-ingest/references/skill-authorization-policy-v1.md"
run_failure_case 'authorization policy hash drift'

print -r -- 'PASS: ERL static checker negative fixtures'
