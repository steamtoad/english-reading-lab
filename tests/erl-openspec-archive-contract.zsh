#!/bin/zsh

#------------------------------------------------------------------------------
# erl-openspec-archive-contract.zsh
# Тип: ERL OpenSpec regression test
# Назначение: проверить readiness, synchronization и полноту OpenSpec archive
#------------------------------------------------------------------------------

emulate -L zsh
setopt errexit pipe_fail no_unset
repo="${0:A:h:h}"
checker="$repo/.scripts/erl/dev/erl-openspec-archive-check.zsh"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/erl-openspec-archive.XXXXXX")"
trap 'rm -rf -- "$fixture"' EXIT HUP INT TERM

make_tools() {
  mkdir -p "$fixture/bin"
  print -r -- '#!/bin/zsh
exit 0' > "$fixture/bin/openspec"
  chmod +x "$fixture/bin/openspec"
}

make_repo() {
  local change="$1" test_name="$2" root="$fixture/repo"
  rm -rf -- "$root"
  mkdir -p "$root/openspec/changes/$change/specs/governance" "$root/openspec/specs/governance" "$root/tests"
  print -r -- 'proposal' > "$root/openspec/changes/$change/proposal.md"
  print -r -- 'design' > "$root/openspec/changes/$change/design.md"
  print -r -- '## 1. Verification

- [x] 1.1 Verify behavior' > "$root/openspec/changes/$change/tasks.md"
  print -r -- '## ADDED Requirements

### Requirement: TEST-001 — Fixture requirement

Fixture MUST remain testable.

#### Scenario: Fixture is checked

- **WHEN** fixture is checked
- **THEN** validation SHALL pass' > "$root/openspec/changes/$change/specs/governance/spec.md"
  print -r -- '#!/bin/zsh
exit 0' > "$root/tests/$test_name"
  chmod +x "$root/tests/$test_name"
}

expect_failure() {
  local expected="$1"; shift
  local output rc
  set +e
  output="$(PATH="$fixture/bin:$PATH" "$checker" "$@" 2>&1)"
  rc=$?
  set -e
  [[ "$rc" == 10 && "$output" == *"$expected"* ]] || {
    print -ru2 -- "FAIL: expected archive diagnostic: $expected"
    print -ru2 -- "$output"
    exit 1
  }
}

make_tools

# Completed, verified Change is ready; incomplete tasks and missing primary test block it.
make_repo add-fixture erl-fixture.zsh
PATH="$fixture/bin:$PATH" "$checker" --repo "$fixture/repo" --pre --change add-fixture >/dev/null
sed -i.bak 's/- \[x\]/- [ ]/' "$fixture/repo/openspec/changes/add-fixture/tasks.md"
rm -f -- "$fixture/repo/openspec/changes/add-fixture/tasks.md.bak"
expect_failure 'Change has incomplete tasks' --repo "$fixture/repo" --pre --change add-fixture
sed -i.bak 's/- \[ \]/- [x]/' "$fixture/repo/openspec/changes/add-fixture/tasks.md"
rm -f -- "$fixture/repo/openspec/changes/add-fixture/tasks.md.bak" "$fixture/repo/tests/erl-fixture.zsh"
expect_failure 'missing executable primary regression test' --repo "$fixture/repo" --pre --change add-fixture

# Agent setup archive readiness additionally requires reference-skill synchronization.
make_repo add-openclaw-agent-setup erl-openclaw-agent-setup.zsh
mkdir -p "$fixture/repo/.scripts/erl/dev" "$fixture/repo/skills"
print -r -- '#!/bin/zsh
if [[ "$1" == --check-reference-skills ]]; then
  exit 10
fi
exit 0' > "$fixture/repo/.scripts/erl/dev/erl-openclaw-agent-setup.zsh"
chmod +x "$fixture/repo/.scripts/erl/dev/erl-openclaw-agent-setup.zsh"
expect_failure 'embedded Lexi skills differ from reference skills' \
  --repo "$fixture/repo" --pre --change add-openclaw-agent-setup
print -r -- '#!/bin/zsh
exit 0' > "$fixture/repo/.scripts/erl/dev/erl-openclaw-agent-setup.zsh"
PATH="$fixture/bin:$PATH" "$checker" --repo "$fixture/repo" --pre --change add-openclaw-agent-setup >/dev/null

# Post-archive validation requires complete history and synchronized canonical requirements.
make_repo add-fixture erl-fixture.zsh
archive="$fixture/repo/openspec/changes/archive/2026-09-02-add-fixture"
mkdir -p "${archive:h}"
mv "$fixture/repo/openspec/changes/add-fixture" "$archive"
cp "$archive/specs/governance/spec.md" "$fixture/repo/openspec/specs/governance/spec.md"
PATH="$fixture/bin:$PATH" "$checker" --repo "$fixture/repo" --post --archive "$archive" >/dev/null

print -r -- '# governance Specification' > "$fixture/repo/openspec/specs/governance/spec.md"
expect_failure 'delta requirement is not synchronized' --repo "$fixture/repo" --post --archive "$archive"
cp "$archive/specs/governance/spec.md" "$fixture/repo/openspec/specs/governance/spec.md"
rm -f -- "$archive/design.md"
expect_failure 'missing Change artifact: design.md' --repo "$fixture/repo" --post --archive "$archive"

# The delta itself remains structurally complete and defines all stable IDs.
change="$repo/openspec/changes/add-openspec-archive-contract"
if [[ ! -d "$change" ]]; then
  archived_changes=("$repo"/openspec/changes/archive/<->-<->-<->-add-openspec-archive-contract(N))
  (( ${#archived_changes} )) || { print -ru2 -- 'FAIL: archive-contract Change history is missing'; exit 1; }
  change="${archived_changes[-1]}"
fi
spec="$change/specs/openspec-governance/spec.md"
for artifact in proposal.md design.md tasks.md specs/openspec-governance/spec.md; do
  [[ -f "$change/$artifact" ]] || { print -ru2 -- "FAIL: missing archive-contract artifact: $artifact"; exit 1; }
done
for n in 001 002 003 004 005; do
  [[ "$(rg -c "^### Requirement: OS-ARCHIVE-$n —" "$spec")" == 1 ]] || {
    print -ru2 -- "FAIL: OS-ARCHIVE-$n must occur exactly once"
    exit 1
  }
  [[ "$(rg -c "^OS-ARCHIVE-$n$" "$repo/.scripts/erl/docs/requirements.md")" == 1 ]] || {
    print -ru2 -- "FAIL: legacy traceability must contain OS-ARCHIVE-$n exactly once"
    exit 1
  }
done
rg -qF '`openspec/specs/` SHALL оставаться source of truth' "$spec"
rg -qF 'erl-openspec-archive-check.zsh --pre --change CHANGE_NAME' "$repo/AGENTS.MD"
rg -qF 'active и archived deltas служат change planning/history' "$repo/AGENTS.MD"

print -r -- 'PASS: ERL OpenSpec archive contract'
