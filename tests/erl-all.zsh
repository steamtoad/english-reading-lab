#!/bin/zsh

#------------------------------------------------------------------------------
# erl-all.zsh
# Тип: ERL test suite
# Назначение: запустить syntax, skill, static-checker, validation, CLI и optional live routing tests
#------------------------------------------------------------------------------

emulate -L zsh
setopt errexit pipe_fail no_unset

repo="${0:A:h:h}"

forbidden_host_files="$(git -C "$repo" ls-files -- '.scripts/lib/**' '.scripts/objects/**' '.scripts/zettelkasten/**' '.scripts/docs/**' '.scripts/zt-*' 'zcreate' 2>/dev/null)"
[[ -z "$forbidden_host_files" ]] || {
  print -ru2 -- 'FAIL: ERL repository tracks production host implementation:'
  print -ru2 -- "$forbidden_host_files"
  exit 1
}
if rg -n '\$script_dir/\.\./(objects|lib|zettelkasten)|fixtures/host-contract' "$repo/.scripts/erl" >/dev/null 2>&1; then
  print -ru2 -- 'FAIL: production ERL runtime contains repository-relative host fallback'
  exit 1
fi
if rg -n '\$vault/vault/(notes|\.state)|"\$vault"/\*\.adoc' \
  "$repo/.scripts/erl" --glob '!erl-home-layout-migrate.zsh' --glob '!erl-check.zsh' >/dev/null 2>&1; then
  print -ru2 -- 'FAIL: production ERL runtime contains nested-vault or root-document fallback'
  exit 1
fi

while IFS= read -r shell_file; do
  zsh -n "$shell_file"
done < <(find "$repo/.scripts/erl" "$repo/tests" -type f -name '*.zsh' | sort)

"$repo/.scripts/erl/dev/erl-skills-check.zsh"
"$repo/tests/erl-skills-check.zsh"
"$repo/tests/erl-skill-distribution-artifact-hygiene.zsh"
"$repo/tests/erl-repository-boundary.zsh"
"$repo/.scripts/erl/dev/erl-delta-test-naming-check.zsh"
"$repo/tests/erl-delta-primary-test-contract.zsh"
"$repo/tests/erl-delta-test-naming-gate.zsh"
"$repo/tests/erl-openspec-archive-contract.zsh"
"$repo/tests/erl-target-home-layout.zsh"
"$repo/tests/erl-human-readable-card-content.zsh"
"$repo/tests/erl-chapter-chain-handoff.zsh"
"$repo/tests/erl-chapter-vocabulary-quota-test-header.zsh"
"$repo/tests/erl-check.zsh"
"$repo/tests/erl-cli.zsh"
"$repo/tests/erl-agent-routing.zsh"

git -C "$repo" diff --check
print -r -- 'PASS: complete ERL test suite'
