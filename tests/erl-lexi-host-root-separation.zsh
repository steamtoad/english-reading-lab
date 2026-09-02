#!/bin/zsh

#------------------------------------------------------------------------------
# erl-lexi-host-root-separation.zsh
# Тип: ERL root-role regression test
# Назначение: проверить disjoint Lexi Vault, host implementation и forbidden user Vault
#------------------------------------------------------------------------------

emulate -L zsh
setopt errexit pipe_fail no_unset

repo="${0:A:h:h}"
erl="$repo/.scripts/erl"
setup="$erl/dev/erl-openclaw-agent-setup.zsh"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/erl-root-separation-test.XXXXXX")"
trap 'rm -rf -- "$fixture"' EXIT HUP INT TERM

host="$fixture/host"
host_two="$fixture/host-two"
user_vault="$fixture/user-vault"
vault="$fixture/target"
mkdir -p -- "$host" "$host_two" "$user_vault/notes" "$vault/notes"
cp -R -- "$repo/fixtures/host-contract/.scripts" "$host/.scripts"
cp -R -- "$repo/fixtures/host-contract/.scripts" "$host_two/.scripts"

print -r -- 'A short chapter.' > "$fixture/book.txt"
policy_base='{"schema_version":1,"threshold":["B2","C1","C2"],"lexical_types":["word"]}'
policy_identity="$(print -r -- "$policy_base" | jq -cS . | shasum -a 256 | awk '{print "sha256:" $1}')"
print -r -- "$policy_base" | jq --arg identity "$policy_identity" '.+{identity:$identity}' > "$fixture/policy.json"

book_command=("$erl/erl-book-ingest.zsh" --vault "$vault" --source "$fixture/book.txt" --title Example --key-topic Reading --policy-file "$fixture/policy.json" --dry-run --json)

# Positive role resolution uses the target only for documents/state and the
# separate host only for canonical constructors.
jq -n --arg host "$host" --arg forbidden "$user_vault" \
  '{version:1,host_root:$host,forbidden_roots:[$forbidden]}' > "$vault/.state-host.json"
mkdir -p -- "$vault/.state/erl"
mv -- "$vault/.state-host.json" "$vault/.state/erl/host-contract.json"
ERL_HOST_HOME="$host" "${book_command[@]}" > "$fixture/positive.json"
jq -e --arg prefix "$vault/.state/erl/works/" \
  '.status=="ok" and .changed==false and (.data.work_state_path | startswith($prefix))' \
  "$fixture/positive.json" >/dev/null
[[ "$(find "$vault" -type f ! -path '*/host-contract.json' | wc -l | tr -d ' ')" == 0 ]] || {
  print -ru2 -- 'FAIL: positive dry-run mutated target Vault'
  exit 1
}

expect_error() {
  local expected_rc="$1" expected_code="$2" output="$3"
  shift 3
  set +e
  "$@" > "$output"
  local rc=$?
  set -e
  [[ "$rc" == "$expected_rc" ]] || { print -ru2 -- "FAIL: expected rc $expected_rc, got $rc"; exit 1; }
  jq -e --arg code "$expected_code" '.changed==false and .code==$code' "$output" >/dev/null || {
    print -ru2 -- "FAIL: expected diagnostic $expected_code"
    cat "$output" >&2
    exit 1
  }
}

before="$(find "$vault" -type f -exec shasum -a 256 {} + | sort)"
expect_error 30 FORBIDDEN_ROOT "$fixture/forbidden-target.json" \
  env ERL_FORBIDDEN_HOME="$vault" ERL_HOST_HOME="$host" "${book_command[@]}"
after="$(find "$vault" -type f -exec shasum -a 256 {} + | sort)"
[[ "$before" == "$after" ]] || { print -ru2 -- 'FAIL: forbidden target failure mutated Vault'; exit 1; }

user_command=("$erl/erl-book-ingest.zsh" --vault /Users/steamtoad/zettelkasten --source "$fixture/book.txt" --title Forbidden --key-topic Reading --policy-file "$fixture/policy.json" --dry-run --json)
expect_error 30 FORBIDDEN_ROOT "$fixture/current-user-vault.json" env ERL_HOST_HOME="$host" "${user_command[@]}"

jq -n --arg host "$host" '{version:1,host_root:$host,forbidden_roots:[$host]}' > "$vault/.state/erl/host-contract.json"
expect_error 30 FORBIDDEN_ROOT "$fixture/forbidden-host.json" env -u ERL_HOST_HOME "${book_command[@]}"

jq -n --arg host "$host" --arg forbidden "$user_vault" \
  '{version:1,host_root:$host,forbidden_roots:[$forbidden]}' > "$vault/.state/erl/host-contract.json"
expect_error 30 HOST_ROOT_CONFIG_DRIFT "$fixture/drift.json" env ERL_HOST_HOME="$host_two" "${book_command[@]}"
expect_error 10 INVALID_INPUT "$fixture/relative.json" env ERL_HOST_HOME=relative-host "${book_command[@]}"

equal_vault="$fixture/equal"
mkdir -p -- "$equal_vault/notes"
cp -R -- "$repo/fixtures/host-contract/.scripts" "$equal_vault/.scripts"
equal_command=("$erl/erl-book-ingest.zsh" --vault "$equal_vault" --source "$fixture/book.txt" --title Equal --key-topic Reading --policy-file "$fixture/policy.json" --dry-run --json)
expect_error 30 ROOT_ROLE_CONFLICT "$fixture/equal.json" env ERL_HOST_HOME="$equal_vault" "${equal_command[@]}"

missing_host="$fixture/missing-host"
mkdir -p -- "$missing_host"
jq -n --arg host "$missing_host" --arg forbidden "$user_vault" \
  '{version:1,host_root:$host,forbidden_roots:[$forbidden]}' > "$vault/.state/erl/host-contract.json"
expect_error 50 HOST_CONTRACT_UNAVAILABLE "$fixture/missing-marker.json" env ERL_HOST_HOME="$missing_host" "${book_command[@]}"

# Setup renders the same roles, manages the descriptor transactionally, and is
# portable when explicit fixture paths are supplied.
new_workspace() {
  local root="$1"
  mkdir -p -- "$root"
  cp -- "$repo/.gitignore" "$root/.gitignore"
  git -C "$root" init -q
}
setup_args=(--host-home "$host" --forbidden-user-home "$user_vault" --user-name Test --timezone UTC)
workspace="$fixture/workspace"
new_workspace "$workspace"
dry="$($setup --workspace "$workspace" "${setup_args[@]}")"
[[ "$dry" == *"erl_home=$workspace"* && "$dry" == *"erl_host_home=$host"* && "$dry" == *"forbidden_user_home=$user_vault"* ]] || {
  print -ru2 -- 'FAIL: setup dry-run omitted effective root roles'
  exit 1
}
[[ "$dry" == *$'create\t.state/erl/host-contract.json'* ]] || { print -ru2 -- 'FAIL: setup did not plan host contract'; exit 1; }
$setup --workspace "$workspace" "${setup_args[@]}" --apply >/dev/null
$setup --workspace "$workspace" "${setup_args[@]}" --check >/dev/null
jq -e --arg host "$host" --arg forbidden "$user_vault" \
  '.host_root==$host and .forbidden_roots==[$forbidden]' "$workspace/.state/erl/host-contract.json" >/dev/null

stale="$fixture/stale"
new_workspace "$stale"
mkdir -p -- "$stale/.state/erl"
print -r -- '{"version":1,"host_root":"/Users/steamtoad/zettelkasten"}' > "$stale/.state/erl/host-contract.json"
stale_hash="$(shasum -a 256 "$stale/.state/erl/host-contract.json")"
stale_dry="$($setup --workspace "$stale" "${setup_args[@]}")"
[[ "$stale_dry" == *$'conflict\t.state/erl/host-contract.json'* ]] || { print -ru2 -- 'FAIL: stale descriptor was not a conflict'; exit 1; }
set +e
stale_apply="$($setup --workspace "$stale" "${setup_args[@]}" --apply 2>&1)"
stale_rc=$?
set -e
[[ "$stale_rc" == 10 && "$stale_apply" == *'managed conflicts detected'* ]] || { print -ru2 -- 'FAIL: stale descriptor did not require replacement consent'; exit 1; }
[[ "$(shasum -a 256 "$stale/.state/erl/host-contract.json")" == "$stale_hash" ]] || { print -ru2 -- 'FAIL: default apply changed stale descriptor'; exit 1; }
replace="$($setup --workspace "$stale" "${setup_args[@]}" --replace-managed --apply)"
journal="${replace##*journal=}"
rg -qF '/Users/steamtoad/zettelkasten' "$journal/backups/.state/erl/host-contract.json"
jq -e --arg host "$host" '.host_root==$host' "$stale/.state/erl/host-contract.json" >/dev/null

rollback="$fixture/rollback"
new_workspace "$rollback"
mkdir -p -- "$rollback/.state/erl"
print -r -- '{"version":1,"host_root":"/Users/steamtoad/zettelkasten"}' > "$rollback/.state/erl/host-contract.json"
rollback_hash="$(shasum -a 256 "$rollback/.state/erl/host-contract.json")"
set +e
rollback_output="$(ERL_AGENT_SETUP_FAIL_AFTER=2 $setup --workspace "$rollback" "${setup_args[@]}" --replace-managed --apply 2>&1)"
rollback_rc=$?
set -e
[[ "$rollback_rc" == 20 && "$rollback_output" == *'rollback completed'* ]] || { print -ru2 -- 'FAIL: injected setup failure did not roll back'; exit 1; }
[[ "$(shasum -a 256 "$rollback/.state/erl/host-contract.json")" == "$rollback_hash" ]] || { print -ru2 -- 'FAIL: rollback did not restore stale descriptor bytes'; exit 1; }
rg -q 'status=recovery-required' "$rollback/.state/erl/agent-setup-transactions"/*/status

rg -qF 'ERL_HOME=/Users/steamtoad/pub/english-reading-lab' "$repo/.scripts/erl/docs/skill-contracts/erl-agent-contract-v1.md"
rg -qF 'ERL_HOST_HOME=/Users/steamtoad/dev/zettelkasten-cli' "$repo/.scripts/erl/docs/skill-contracts/erl-agent-contract-v1.md"
$setup --check-reference-skills "$repo/skills" >/dev/null

for command in \
  erl-book-ingest erl-book-reduce erl-card-content-repair erl-chapter-chain-handoff \
  erl-chapter-memo-chain-migrate erl-chapter-topic-binding-migrate \
  erl-chapter-vocabulary-ingest erl-classic-reduce-reconcile erl-extraction-stage \
  erl-home-layout-migrate erl-state-migrate erl-transaction-recover \
  erl-vocabulary-ingest erl-work-rename; do
  rg -q 'erl_validate_target_root_role' "$erl/$command.zsh" || {
    print -ru2 -- "FAIL: $command lacks target root-role preflight"
    exit 1
  }
done

print -r -- 'PASS: Lexi Vault and host implementation roots are separated'
