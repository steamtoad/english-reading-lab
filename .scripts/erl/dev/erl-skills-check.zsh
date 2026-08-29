#!/usr/bin/env zsh

#------------------------------------------------------------------------------
# erl-skills-check.zsh
# Тип: ERL development check
# Назначение: проверить packaging, contracts, requirement IDs и executable references skills Lexi
#------------------------------------------------------------------------------

set -eu
setopt pipe_fail

script_dir="${0:A:h}"
erl_dir="${script_dir:h}"
repo_root="${erl_dir:h:h}"
skills_dir="${repo_root}/skills"
requirements_file="${erl_dir}/docs/requirements.md"
source_contract="${erl_dir}/docs/skill-contracts/erl-agent-contract-v1.md"
source_authorization="${erl_dir}/docs/skill-contracts/skill-authorization-policy-v1.md"
source_reduce_contract="${erl_dir}/docs/skill-contracts/erl-book-reduce-contract-v1.md"

typeset -a skill_names=(
  erl-book-ingest
  erl-chapter-vocabulary-extract
  erl-vocabulary-ingest
  erl-chapter-vocabulary-ingest
  erl-book-reduce
  erl-classic-reduce-reconcile
  erl-check
)

typeset failures=0

fail() {
  print -u2 -- "ERROR: $*"
  failures=$((failures + 1))
}

while IFS= read -r shell_file; do
  [[ "$shell_file" == *.zsh ]] || fail "ERL shell file lacks mandatory .zsh extension: $shell_file"
  header_name="$(sed -n '4p' "$shell_file")"
  [[ "$(sed -n '3p' "$shell_file")" == '#------------------------------------------------------------------------------' ]] || fail "$shell_file: missing opening header separator"
  [[ "$header_name" == "# ${shell_file:t}" ]] || fail "$shell_file: header does not contain the full filename"
  [[ "$(sed -n '5p' "$shell_file")" == '# Тип: '* ]] || fail "$shell_file: missing header type"
  [[ "$(sed -n '6p' "$shell_file")" == '# Назначение: '* ]] || fail "$shell_file: missing header purpose"
  [[ "$(sed -n '7p' "$shell_file")" == '#------------------------------------------------------------------------------' ]] || fail "$shell_file: missing closing header separator"
done < <(find "$erl_dir" "$repo_root/tests" -type f -exec awk 'FNR==1 && $0 ~ /^#!(\/bin\/zsh|\/usr\/bin\/env zsh)$/{print FILENAME}' {} +)

for command_name in \
  erl-book-ingest erl-chapter-export erl-extraction-stage erl-vocabulary-ingest \
  erl-chapter-vocabulary-ingest erl-book-reduce erl-classic-reduce-reconcile erl-check; do
  [[ -x "${erl_dir}/${command_name}.zsh" ]] || fail "canonical executable is missing: ${erl_dir}/${command_name}.zsh"
  [[ ! -e "${erl_dir}/${command_name}" ]] || fail "extensionless executable is forbidden: ${erl_dir}/${command_name}"
done

[[ -f "$requirements_file" ]] || fail "requirements not found: $requirements_file"
[[ -f "$source_contract" ]] || fail "source contract not found: $source_contract"
[[ -f "$source_authorization" ]] || fail "authorization policy not found: $source_authorization"
[[ -f "$source_reduce_contract" ]] || fail "Reduce contract not found: $source_reduce_contract"
[[ -x "${erl_dir}/erl-check.zsh" ]] || fail "canonical checker is not executable: ${erl_dir}/erl-check.zsh"
[[ ! -e "${erl_dir}/erl-check" ]] || fail "legacy extensionless checker must not exist: ${erl_dir}/erl-check"

for skill_name in "${skill_names[@]}"; do
  skill_file="${skills_dir}/${skill_name}/SKILL.md"
  reference_file="${skills_dir}/${skill_name}/references/erl-agent-contract-v1.md"
  authorization_file="${skills_dir}/${skill_name}/references/skill-authorization-policy-v1.md"

  [[ -f "$skill_file" ]] || { fail "skill not found: $skill_file"; continue; }
  [[ -f "$reference_file" ]] || { fail "reference not found: $reference_file"; continue; }
  [[ -f "$authorization_file" ]] || { fail "authorization policy not found: $authorization_file"; continue; }

  frontmatter_name="$(awk -F': ' '/^name:/{gsub(/"/, "", $2); print $2; exit}' "$skill_file")"
  description="$(awk -F': ' '/^description:/{sub(/^description: /, ""); gsub(/^"|"$/, ""); print; exit}' "$skill_file")"
  [[ "$frontmatter_name" == "$skill_name" ]] || fail "$skill_name: invalid frontmatter name"
  [[ -n "$description" ]] || fail "$skill_name: missing description"
  (( ${#description} <= 160 )) || fail "$skill_name: description exceeds 160 characters"
  [[ "$description" != *"canonical ERL checker"* ]] || fail "$skill_name: description is implementation-oriented"

  cmp -s "$source_contract" "$reference_file" || fail "$skill_name: common contract hash drift"
  cmp -s "$source_authorization" "$authorization_file" || fail "$skill_name: authorization policy hash drift"
  if [[ "$skill_name" == erl-book-reduce ]]; then
    cmp -s "$source_reduce_contract" "${skills_dir}/${skill_name}/references/erl-book-reduce-contract-v1.md" || \
      fail "$skill_name: Reduce contract hash drift"
  fi

  if rg -n 'Resolve (executable )?`erl-|Invoke `erl-|Call `erl-' "$skill_file" >/dev/null; then
    fail "$skill_name: noncanonical executable reference"
  fi

  while IFS= read -r requirement_id; do
    rg -q "^${requirement_id}$" "$requirements_file" || fail "$skill_name: unknown requirement ID $requirement_id"
  done < <(rg -o 'ERL-[A-Z]+-[0-9]{3}' "$skill_file" | sort -u)

  while IFS= read -r requirement_range; do
    [[ -n "$requirement_range" ]] || continue
    range_prefix="${requirement_range%%-[0-9][0-9][0-9]..*}"
    range_start="${requirement_range#${range_prefix}-}"
    range_start="${range_start%%..*}"
    range_end="${requirement_range##*..}"
    for (( requirement_number = 10#$range_start; requirement_number <= 10#$range_end; requirement_number++ )); do
      requirement_id="${range_prefix}-$(printf '%03d' "$requirement_number")"
      rg -q "^${requirement_id}$" "$requirements_file" || fail "$skill_name: unknown requirement ID $requirement_id"
    done
  done < <(rg -o 'ERL-[A-Z]+-[0-9]{3}\.\.[0-9]{3}' "$skill_file" | sort -u)
done

while IFS= read -r artifact; do
  [[ -z "$artifact" ]] || fail "distribution artifact is not allowed: $artifact"
done < <(find "$skills_dir" -type f \( -name '.DS_Store' -o -path '*/.openclaw/source-origin.json' \) -print)

[[ ! -d "${skills_dir}/.openclaw-install-backups" ]] || \
  fail "distribution artifact is not allowed: ${skills_dir}/.openclaw-install-backups"

(( failures == 0 )) || exit 10
print -- "PASS: ERL skill contracts"
