#!/bin/zsh

#------------------------------------------------------------------------------
# erl-book-title-key-topic.zsh
# Тип: ERL primary regression test
# Назначение: проверить exact Book-title key и explicit migration
#------------------------------------------------------------------------------

emulate -L zsh
setopt errexit pipe_fail no_unset
repo="${0:A:h:h}"; erl="$repo/.scripts/erl"; export ERL_HOST_HOME="$repo/fixtures/host-contract"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/erl-book-title-key-topic.XXXXXX")"; trap 'rm -rf -- "$fixture"' EXIT HUP INT TERM
vault="$fixture/vault"; mkdir -p "$vault/notes"; print -r -- 'Friday arrived quietly.' > "$fixture/friday.txt"
policy_base='{"schema_version":1,"threshold":["C1"],"lexical_types":["word"]}'
policy_identity="$(print -r -- "$policy_base" | jq -cS . | shasum -a 256 | awk '{print "sha256:" $1}')"
print -r -- "$policy_base" | jq --arg identity "$policy_identity" '.+{identity:$identity}' > "$fixture/policy.json"
key_of() { awk '/^:key-topic:/{sub(/^:key-topic:[[:space:]]*/,"");print;exit}' "$1"; }

set +e
"$erl/erl-book-ingest.zsh" --vault "$vault" --source "$fixture/friday.txt" --title Friday --key-topic 'English Reading' --policy-file "$fixture/policy.json" --apply --json > "$fixture/conflict.json"
rc=$?
set -e
[[ "$rc" == 10 ]]
jq -e '.code=="INVALID_INPUT" and .data.expected_key_topic=="Friday" and .data.actual_key_topic=="English Reading"' "$fixture/conflict.json" >/dev/null
[[ "$(find "$vault/notes" -type f | wc -l | tr -d ' ')" == 0 ]]
[[ "$(find "$vault/.state/erl/works" -type f 2>/dev/null | wc -l | tr -d ' ')" == 0 ]]

"$erl/erl-book-ingest.zsh" --vault "$vault" --source "$fixture/friday.txt" --title Friday --policy-file "$fixture/policy.json" --apply --json > "$fixture/ingest.json"
work="$(jq -r .data.work_id "$fixture/ingest.json")"; generation="$(jq -r .data.generation_uuid "$fixture/ingest.json")"
source_file=("$vault/.state/erl/works"/*/sources/*.json); chapter="$(jq -r '.chapters[0].chapter_uuid' "$source_file[1]")"
topic="$vault/notes/$generation.adoc"; chapter_file="$vault/notes/$chapter.adoc"
[[ "$(key_of "$topic")" == Friday && "$(key_of "$chapter_file")" == Friday ]]
! rg -q '^:key-topic: English Reading$' "$topic" "$chapter_file"

sed -i.bak 's/^:key-topic: Friday$/:key-topic: English Reading/' "$topic"; rm -f "$topic.bak"
before="$(shasum -a 256 "$topic")"
set +e; "$erl/erl-check.zsh" --vault "$vault" --work "$work" --json > "$fixture/stale.json"; rc=$?; set -e
[[ "$rc" == 10 ]]
jq -e --arg uuid "$generation" 'any(.diagnostics[]; .code=="ERL-CHECK-021" and .document_uuid==$uuid and .expected_key_topic=="Friday" and .actual_key_topic=="English Reading")' "$fixture/stale.json" >/dev/null
[[ "$before" == "$(shasum -a 256 "$topic")" ]]

sed -i.bak 's/^:key-topic: Friday$/:key-topic: English Reading/' "$chapter_file"; rm -f "$chapter_file.bak"
stale_hash="$(shasum -a 256 "$topic" "$chapter_file")"
"$erl/erl-book-title-key-topic-migrate.zsh" --vault "$vault" --work "$work" --dry-run --json > "$fixture/plan.json"
jq -e '.changed==false and .data.update_count==2 and .data.title=="Friday"' "$fixture/plan.json" >/dev/null
[[ "$stale_hash" == "$(shasum -a 256 "$topic" "$chapter_file")" ]]
set +e
ERL_TEST_INTERRUPT_BOOK_TITLE_KEY_TOPIC_AFTER_MUTATION=1 "$erl/erl-book-title-key-topic-migrate.zsh" --vault "$vault" --work "$work" --apply --json > "$fixture/interrupted.json"
rc=$?
set -e
[[ "$rc" == 60 ]]
txid="$(for f in "$vault"/.state/erl/transactions/*/transaction.json(N); do jq -r 'select(.operation=="erl-book-title-key-topic-migrate" and .phase=="applied")|.txid' "$f"; done | head -n1)"
"$erl/erl-transaction-recover.zsh" --vault "$vault" --txid "$txid" --apply --json | jq -e '.changed==true and .data.recovery_action=="rollback"' >/dev/null
[[ "$stale_hash" == "$(shasum -a 256 "$topic" "$chapter_file")" ]]
"$erl/erl-book-title-key-topic-migrate.zsh" --vault "$vault" --work "$work" --apply --json > "$fixture/migrated.json"
jq -e '.changed==true and .data.update_count==2' "$fixture/migrated.json" >/dev/null
[[ "$(key_of "$topic")" == Friday && "$(key_of "$chapter_file")" == Friday ]]
"$erl/erl-book-title-key-topic-migrate.zsh" --vault "$vault" --work "$work" --apply --json | jq -e '.code=="ALREADY_CURRENT" and .changed==false' >/dev/null
print -r -- 'PASS: Book title key-topic'
