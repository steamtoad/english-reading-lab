#!/bin/zsh

#------------------------------------------------------------------------------
# erl-target-home-layout.zsh
# Тип: ERL architecture/migration regression test
# Назначение: проверить canonical target home и safe legacy layout migration
#------------------------------------------------------------------------------

emulate -L zsh
setopt errexit pipe_fail no_unset
repo="${0:A:h:h}"; erl="$repo/.scripts/erl"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/erl-home-layout.XXXXXX")"
trap 'rm -rf -- "$fixture"' EXIT HUP INT TERM

home="$fixture/home"
mkdir -p "$home/vault/notes" "$home/vault/.state/erl/works/example" \
  "$home/vault/.state/erl/cache" "$home/vault/.state/erl/staging" \
  "$home/vault/.state/erl/transactions/legacy"
print -r -- '= Legacy note' > "$home/vault/notes/aaaaaaaa-aaaa-1aaa-8aaa-aaaaaaaaaaaa.adoc"
print -r -- '{"schema_version":1}' > "$home/vault/.state/erl/works/example/work.json"
print -r -- 'cache' > "$home/vault/.state/erl/cache/index"
print -r -- '{"status":"staged"}' > "$home/vault/.state/erl/staging/batch.json"
print -r -- '{"phase":"committed"}' > "$home/vault/.state/erl/transactions/legacy/transaction.json"

set +e
"$erl/erl-check.zsh" --vault "$home" --json > "$fixture/legacy-check.json"
check_rc=$?
set -e
[[ "$check_rc" == 10 ]] || { print -ru2 -- "FAIL: legacy checker exit was $check_rc"; exit 1; }
jq -e 'any(.diagnostics[]; .code=="HOME_LAYOUT_MIGRATION_REQUIRED")' "$fixture/legacy-check.json" >/dev/null

before="$(find "$home" -type f | sort | xargs shasum -a 256)"
"$erl/erl-home-layout-migrate.zsh" --home "$home" --dry-run --json > "$fixture/dry.json"
jq -e '.changed==false and .data.files==5 and .data.collisions==0' "$fixture/dry.json" >/dev/null
after="$(find "$home" -type f | sort | xargs shasum -a 256)"
[[ "$before" == "$after" ]] || { print -ru2 -- 'FAIL: migration dry-run changed files'; exit 1; }

"$erl/erl-home-layout-migrate.zsh" --home "$home" --apply --json > "$fixture/apply.json"
jq -e '.changed==true and .data.files==5 and .data.layout=="canonical"' "$fixture/apply.json" >/dev/null
[[ -f "$home/notes/aaaaaaaa-aaaa-1aaa-8aaa-aaaaaaaaaaaa.adoc" ]] || { print -ru2 -- 'FAIL: note was not migrated'; exit 1; }
[[ -f "$home/.state/erl/works/example/work.json" && -f "$home/.state/erl/cache/index" ]] || { print -ru2 -- 'FAIL: state classes were not migrated'; exit 1; }
[[ -f "$home/.state/erl/staging/batch.json" && -f "$home/.state/erl/transactions/legacy/transaction.json" ]] || { print -ru2 -- 'FAIL: staging/transaction state was not migrated'; exit 1; }
[[ ! -d "$home/vault" ]] || { print -ru2 -- 'FAIL: empty legacy vault directory remains'; exit 1; }
txid="$(jq -r .data.txid "$fixture/apply.json")"
jq -e '.phase=="committed" and .operation=="erl-home-layout-migrate"' "$home/.state/erl/transactions/$txid/transaction.json" >/dev/null
set +e
"$erl/erl-check.zsh" --vault "$home" --json > "$fixture/canonical-check.json"
set -e
jq -e 'all(.diagnostics[]; .code!="HOME_LAYOUT_MIGRATION_REQUIRED")' "$fixture/canonical-check.json" >/dev/null

# Existing canonical targets block migration before mutation.
collision="$fixture/collision"
mkdir -p "$collision/vault/notes" "$collision/notes"
print -r -- legacy > "$collision/vault/notes/same.adoc"
print -r -- canonical > "$collision/notes/same.adoc"
set +e
"$erl/erl-home-layout-migrate.zsh" --home "$collision" --apply --json > "$fixture/collision.json"
collision_rc=$?
set -e
[[ "$collision_rc" == 30 ]] || { print -ru2 -- "FAIL: collision exit was $collision_rc"; exit 1; }
jq -e '.code=="MIGRATION_COLLISION" and .changed==false' "$fixture/collision.json" >/dev/null
[[ "$(<"$collision/notes/same.adoc")" == canonical && "$(<"$collision/vault/notes/same.adoc")" == legacy ]] || { print -ru2 -- 'FAIL: collision path was mutated'; exit 1; }

# A crash after copy/source removal is recoverable without overwriting changes.
recovery="$fixture/recovery"; recovery_txid="11111111-1111-4111-8111-111111111111"
source_path="$recovery/vault/notes/recover.adoc"; target_path="$recovery/notes/recover.adoc"
mkdir -p "${target_path:h}" "$recovery/.state/erl/transactions/$recovery_txid"
print -r -- recovered > "$target_path"
hash="$(shasum -a 256 "$target_path" | awk '{print "sha256:" $1}')"
jq -n --arg txid "$recovery_txid" --arg source "$source_path" --arg target "$target_path" --arg hash "$hash" \
  '{schema_version:1,txid:$txid,operation:"erl-home-layout-migrate",phase:"removing_sources",items:[{source:$source,target:$target,hash:$hash,copied:true,source_removed:true}]}' \
  > "$recovery/.state/erl/transactions/$recovery_txid/transaction.json"
"$erl/erl-transaction-recover.zsh" --vault "$recovery" --txid "$recovery_txid" --dry-run --json | jq -e '.data.recovery_action=="rollback" and .changed==false' >/dev/null
"$erl/erl-transaction-recover.zsh" --vault "$recovery" --txid "$recovery_txid" --apply --json | jq -e '.data.recovery_action=="rollback" and .changed==true' >/dev/null
[[ -f "$source_path" && ! -e "$target_path" ]] || { print -ru2 -- 'FAIL: migration recovery did not restore legacy source'; exit 1; }
jq -e '.phase=="rolled_back"' "$recovery/.state/erl/transactions/$recovery_txid/transaction.json" >/dev/null

# Recovery refuses to overwrite or delete an unexpectedly edited target.
conflict_txid="22222222-2222-4222-8222-222222222222"
conflict_source="$recovery/vault/notes/conflict.adoc"; conflict_target="$recovery/notes/conflict.adoc"
mkdir -p "${conflict_target:h}" "$recovery/.state/erl/transactions/$conflict_txid"
print -r -- original > "$conflict_target"
original_hash="$(shasum -a 256 "$conflict_target" | awk '{print "sha256:" $1}')"
jq -n --arg txid "$conflict_txid" --arg source "$conflict_source" --arg target "$conflict_target" --arg hash "$original_hash" \
  '{schema_version:1,txid:$txid,operation:"erl-home-layout-migrate",phase:"removing_sources",items:[{source:$source,target:$target,hash:$hash,copied:true,source_removed:true}]}' \
  > "$recovery/.state/erl/transactions/$conflict_txid/transaction.json"
print -r -- 'user edit' > "$conflict_target"
set +e
"$erl/erl-transaction-recover.zsh" --vault "$recovery" --txid "$conflict_txid" --apply --json > "$fixture/recovery-conflict.json"
conflict_recovery_rc=$?
set -e
[[ "$conflict_recovery_rc" == 40 ]] || { print -ru2 -- "FAIL: recovery conflict exit was $conflict_recovery_rc"; exit 1; }
jq -e '.code=="RECOVERY_CONFLICT" and .changed==false' "$fixture/recovery-conflict.json" >/dev/null
[[ "$(<"$conflict_target")" == 'user edit' && ! -e "$conflict_source" ]] || { print -ru2 -- 'FAIL: recovery conflict overwrote user data'; exit 1; }

rg -qF 'Compatibility spelling для target Zettelkasten home' "$repo/.scripts/erl/docs/cli-contract-v1.md" || {
  print -ru2 -- 'FAIL: CLI contract does not define --vault as target home'
  exit 1
}

# Naming validation detects a missing derived primary test and accepts it once present.
naming_fixture="$fixture/naming-repo"
mkdir -p "$naming_fixture/openspec/changes/fix-missing-test" "$naming_fixture/tests"
print -r -- '## 1. Fixture

- [x] 1.1 Complete implementation' > "$naming_fixture/openspec/changes/fix-missing-test/tasks.md"
set +e
naming_output="$("$repo/.scripts/erl/dev/erl-delta-test-naming-check.zsh" "$naming_fixture" 2>&1)"
naming_rc=$?
set -e
[[ "$naming_rc" == 10 && "$naming_output" == *'erl-missing-test.zsh'* ]] || {
  print -ru2 -- 'FAIL: delta-test naming checker missed absent primary regression test'
  exit 1
}
print -r -- '#!/bin/zsh' > "$naming_fixture/tests/erl-missing-test.zsh"
"$repo/.scripts/erl/dev/erl-delta-test-naming-check.zsh" "$naming_fixture" >/dev/null

print -r -- 'PASS: ERL target-home layout and migration'
