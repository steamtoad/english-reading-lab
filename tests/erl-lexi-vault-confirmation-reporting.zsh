#!/bin/zsh

#------------------------------------------------------------------------------
# erl-lexi-vault-confirmation-reporting.zsh
# Тип: ERL Lexi confirmation/reporting regression test
# Назначение: проверить Vault-bound consent, revalidation, post-check и reporting
#------------------------------------------------------------------------------

emulate -L zsh
setopt errexit pipe_fail no_unset

repo="${0:A:h:h}"
checker="$repo/.scripts/erl/dev/erl-skills-check.zsh"
setup="$repo/.scripts/erl/dev/erl-openclaw-agent-setup.zsh"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/erl-lexi-vault-confirmation-test.XXXXXX")"
trap 'rm -rf -- "$fixture"' EXIT HUP INT TERM

typeset -a mutating_skills=(
  erl-book-ingest erl-chapter-vocabulary-extract erl-vocabulary-ingest
  erl-chapter-vocabulary-ingest erl-book-reduce erl-classic-reduce-reconcile
)
typeset -a confirmed_skills=(
  erl-book-ingest erl-chapter-vocabulary-ingest
  erl-book-reduce erl-classic-reduce-reconcile
)

for skill in "${confirmed_skills[@]}"; do
  skill_file="$repo/skills/$skill/SKILL.md"
  rg -qF 'Vault: <absolute-canonical-ERL_HOME>' "$skill_file" || {
    print -ru2 -- "FAIL: $skill omits Vault from the pending plan"
    exit 1
  }
  rg -q 'Immediately before apply.*canonicalize `ERL_HOME`' "$skill_file" || {
    print -ru2 -- "FAIL: $skill omits pre-apply Vault revalidation"
    exit 1
  }
done

for skill in "${mutating_skills[@]}"; do
  skill_file="$repo/skills/$skill/SKILL.md"
  rg -qF 'Vault: <absolute-canonical-path>' "$skill_file" || {
    print -ru2 -- "FAIL: $skill omits the actual Vault from its final report"
    exit 1
  }
  rg -q 'validation scope' "$skill_file" || {
    print -ru2 -- "FAIL: $skill omits validation scope from its final report"
    exit 1
  }
  rg -qF 'the `erl-check` result' "$skill_file" || {
    print -ru2 -- "FAIL: $skill omits the checker result from its final report"
    exit 1
  }
  rg -q 'Missing, failed, or cross-Vault validation is failure' "$skill_file" || {
    print -ru2 -- "FAIL: $skill can report success after invalid post-check"
    exit 1
  }
done

rg -qF 'Every L2/L3 pending plan includes a separate `Vault: <absolute-canonical-path>` field' \
  "$repo/.scripts/erl/docs/skill-contracts/erl-agent-contract-v1.md"
rg -qF 'The final mutation report includes `Vault: <absolute-canonical-path>`' \
  "$repo/.scripts/erl/docs/skill-contracts/erl-agent-contract-v1.md"
rg -qF 'The plan must' "$repo/.scripts/erl/docs/skill-contracts/skill-authorization-policy-v1.md"

reset_skills() {
  rm -rf -- "$fixture/skills"
  cp -R -- "$repo/skills" "$fixture/skills"
}

expect_skill_failure() {
  local skill="$1" expected="$2" output rc
  set +e
  output="$(ERL_SKILLS_DIR="$fixture/skills" "$checker" 2>&1)"
  rc=$?
  set -e
  [[ "$rc" == 10 && "$output" == *"$skill:"* && "$output" == *"$expected"* ]] || {
    print -ru2 -- "FAIL: missing deterministic $skill diagnostic: $expected"
    print -ru2 -- "$output"
    exit 1
  }
}

reset_skills
sed -i.bak '/Vault: <absolute-canonical-ERL_HOME>/d' "$fixture/skills/erl-book-ingest/SKILL.md"
rm -f -- "$fixture/skills/erl-book-ingest/SKILL.md.bak"
expect_skill_failure erl-book-ingest 'plan omits the canonical Vault field'

reset_skills
sed -i.bak '/Immediately before apply.*canonicalize `ERL_HOME`/d' "$fixture/skills/erl-chapter-vocabulary-ingest/SKILL.md"
rm -f -- "$fixture/skills/erl-chapter-vocabulary-ingest/SKILL.md.bak"
expect_skill_failure erl-chapter-vocabulary-ingest 'pre-apply Vault revalidation is missing'

reset_skills
sed -i.bak 's#--vault "${ERL_HOME}" --work "${WORK_ID}"#--vault "${ERL_HOST_HOME}" --work "${WORK_ID}"#' \
  "$fixture/skills/erl-classic-reduce-reconcile/SKILL.md"
rm -f -- "$fixture/skills/erl-classic-reduce-reconcile/SKILL.md.bak"
expect_skill_failure erl-classic-reduce-reconcile 'substitutes host, parent, or nested path'

reset_skills
sed -i.bak '/Vault: <absolute-canonical-path>/d' "$fixture/skills/erl-vocabulary-ingest/SKILL.md"
rm -f -- "$fixture/skills/erl-vocabulary-ingest/SKILL.md.bak"
expect_skill_failure erl-vocabulary-ingest 'final mutation report omits the actual Vault'

workspace="$fixture/workspace"
host="$fixture/host"
user_vault="$fixture/user-vault"
mkdir -p -- "$workspace" "$host" "$user_vault"
cp -- "$repo/.gitignore" "$workspace/.gitignore"
git -C "$workspace" init -q
cp -R -- "$repo/fixtures/host-contract/.scripts" "$host/.scripts"
"$setup" --workspace "$workspace" --host-home "$host" \
  --forbidden-user-home "$user_vault" --user-name Test --timezone UTC --apply >/dev/null
"$setup" --workspace "$workspace" --host-home "$host" \
  --forbidden-user-home "$user_vault" --user-name Test --timezone UTC --check >/dev/null

rg -qF "Vault: $workspace" "$workspace/TOOLS.md"
rg -qF 'separate explicit confirmation' "$workspace/TOOLS.md"
rg -qF 'resolve and canonicalize `ERL_HOME` again' "$workspace/TOOLS.md"
rg -qF -- "--vault $workspace" "$workspace/TOOLS.md"
rg -qF 'validation scope, and checker result' "$workspace/TOOLS.md"

"$setup" --check-reference-skills "$repo/skills" >/dev/null
print -r -- 'PASS: Lexi confirmation, revalidation, same-Vault check and reporting contract'
