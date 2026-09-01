#!/bin/zsh

#------------------------------------------------------------------------------
# erl-skill-distribution-artifact-hygiene.zsh
# Тип: ERL distribution hygiene regression test
# Назначение: проверить clean skills tree и диагностику запрещённых artifacts
#------------------------------------------------------------------------------

emulate -L zsh
setopt errexit pipe_fail no_unset

repo="${0:A:h:h}"
checker="$repo/.scripts/erl/dev/erl-skills-check.zsh"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/erl-skill-artifact-hygiene.XXXXXX")"
trap 'rm -rf -- "$fixture"' EXIT HUP INT TERM
mkdir -p "$fixture/tests"

reset_fixture() {
  rm -rf -- "$fixture/skills"
  cp -R "$repo/skills" "$fixture/skills"
}

expect_artifact_failure() {
  local expected_path="$1"
  local output
  local rc

  set +e
  output="$(ERL_SKILLS_DIR="$fixture/skills" ERL_TESTS_DIR="$fixture/tests" "$checker" 2>&1)"
  rc=$?
  set -e

  [[ "$rc" == 10 ]] || {
    print -ru2 -- "FAIL: expected checker exit 10 for $expected_path, got $rc"
    print -ru2 -- "$output"
    return 1
  }
  [[ "$output" == *"distribution artifact is not allowed: $expected_path"* ]] || {
    print -ru2 -- "FAIL: missing exact artifact diagnostic: $expected_path"
    print -ru2 -- "$output"
    return 1
  }
}

git -C "$repo" check-ignore -q -- skills/.DS_Store || {
  print -ru2 -- 'FAIL: repository ignore policy does not cover skills/.DS_Store'
  exit 1
}

reset_fixture
ERL_SKILLS_DIR="$fixture/skills" ERL_TESTS_DIR="$fixture/tests" "$checker" >/dev/null

reset_fixture
touch "$fixture/skills/.DS_Store"
expect_artifact_failure "$fixture/skills/.DS_Store"

reset_fixture
mkdir -p "$fixture/skills/erl-book-ingest/.openclaw"
touch "$fixture/skills/erl-book-ingest/.openclaw/source-origin.json"
expect_artifact_failure "$fixture/skills/erl-book-ingest/.openclaw/source-origin.json"

reset_fixture
mkdir -p "$fixture/skills/.openclaw-install-backups"
expect_artifact_failure "$fixture/skills/.openclaw-install-backups"

print -r -- 'PASS: ERL skill distribution artifact hygiene'
