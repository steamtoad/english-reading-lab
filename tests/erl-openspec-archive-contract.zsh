#!/bin/zsh

#------------------------------------------------------------------------------
# erl-openspec-archive-contract.zsh
# Тип: ERL OpenSpec regression test
# Назначение: проверить полноту archival delta contract OS-ARCHIVE-001..005
#------------------------------------------------------------------------------

emulate -L zsh
setopt errexit pipe_fail no_unset
repo="${0:A:h:h}"
change="$repo/openspec/changes/add-openspec-archive-contract"
spec="$change/specs/openspec-governance/spec.md"

for artifact in proposal.md design.md tasks.md specs/openspec-governance/spec.md; do
  [[ -f "$change/$artifact" ]] || { print -ru2 -- "FAIL: missing archive-contract artifact: $artifact"; exit 1; }
done
for n in 001 002 003 004 005; do
  [[ "$(rg -c "^### Requirement: OS-ARCHIVE-$n —" "$spec")" == 1 ]] || {
    print -ru2 -- "FAIL: OS-ARCHIVE-$n must occur exactly once"
    exit 1
  }
done
[[ "$(rg -c '^#### Scenario:' "$spec")" == 5 ]] || { print -ru2 -- 'FAIL: every archive requirement needs a Scenario'; exit 1; }
rg -qF '`openspec/specs/` SHALL оставаться source of truth' "$spec" || { print -ru2 -- 'FAIL: canonical specs authority is missing'; exit 1; }
print -r -- 'PASS: ERL OpenSpec archive contract'
