#!/bin/zsh

#------------------------------------------------------------------------------
# erl-chapter-topic-binding.zsh
# Тип: ERL regression test
# Назначение: проверить initial binding, durable rebind, validation и migration
#------------------------------------------------------------------------------

emulate -L zsh
setopt errexit pipe_fail no_unset
repo="${0:A:h:h}"; erl="$repo/.scripts/erl"; export ERL_HOST_HOME="$repo/fixtures/host-contract"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/erl-chapter-topic-binding.XXXXXX")"
if [[ -z "${ERL_TEST_KEEP:-}" ]]; then trap 'rm -rf -- "$fixture"' EXIT HUP INT TERM; else print -ru2 -- "Fixture retained: $fixture"; fi
vault="$fixture/vault"; mkdir -p "$vault/notes"; print -r -- 'A chapter.' > "$fixture/book.txt"
policy_base='{"schema_version":1,"threshold":["C1"],"lexical_types":["word"]}'
policy_identity="$(print -r -- "$policy_base" | jq -cS . | shasum -a 256 | awk '{print "sha256:" $1}')"
print -r -- "$policy_base" | jq --arg identity "$policy_identity" '.+{identity:$identity}' > "$fixture/policy.json"

"$erl/erl-book-ingest.zsh" --vault "$vault" --source "$fixture/book.txt" --title 'Bound Book' --key-topic 'Reading One' --policy-file "$fixture/policy.json" --apply --json > "$fixture/first.json"
generation1="$(jq -r .data.generation_uuid "$fixture/first.json")"; work="$(jq -r .data.work_id "$fixture/first.json")"
source_file=("$vault/.state/erl/works"/*/sources/*.json); chapter="$(jq -r '.chapters[0].chapter_uuid' "$source_file[1]")"
chapter_file="$vault/notes/$chapter.adoc"; topic1="$vault/notes/$generation1.adoc"
[[ "$(awk '/^:key-topic:/{sub(/^:key-topic:[[:space:]]*/,"");print;exit}' "$chapter_file")" == 'Reading One' ]]
[[ "$(grep -cF "link:$generation1.adoc[Bound Book]" "$chapter_file")" == 1 ]]
[[ "$(grep -cF "link:$chapter.adoc[Chapter 1]" "$topic1")" == 1 ]]
"$erl/erl-check.zsh" --vault "$vault" --work "$work" --json | jq -e '.status=="ok"' >/dev/null

"$erl/erl-book-reduce.zsh" --vault "$vault" --generation "$generation1" --dry-run --json > "$fixture/reduce-plan.json"
fingerprint="$(jq -r .data.plan_fingerprint "$fixture/reduce-plan.json")"
"$erl/erl-book-reduce.zsh" --vault "$vault" --generation "$generation1" --plan-fingerprint "$fingerprint" --apply --json > "$fixture/reduce.json"
chapter_before="$(shasum -a 256 "$chapter_file")"
set +e
ERL_TEST_INTERRUPT_BOOK_BINDING_AFTER_DOCUMENTS=1 "$erl/erl-book-ingest.zsh" --vault "$vault" --source "$fixture/book.txt" --work-id "$work" --key-topic 'Reading Two' --policy-file "$fixture/policy.json" --apply --json > "$fixture/interrupted.json"
interrupt_rc=$?
set -e
[[ "$interrupt_rc" == 60 ]]
txid="$(for tx_file in "$vault"/.state/erl/transactions/*/transaction.json(N); do jq -r 'select(.operation=="erl-book-ingest" and .phase=="bindings_updated")|.txid' "$tx_file"; done | head -n1)"
"$erl/erl-transaction-recover.zsh" --vault "$vault" --txid "$txid" --apply --json | jq -e '.changed==true and .data.recovery_action=="rollback"' >/dev/null
[[ "$chapter_before" == "$(shasum -a 256 "$chapter_file")" ]]

"$erl/erl-book-ingest.zsh" --vault "$vault" --source "$fixture/book.txt" --work-id "$work" --key-topic 'Reading Two' --policy-file "$fixture/policy.json" --apply --json > "$fixture/second.json"
generation2="$(jq -r .data.generation_uuid "$fixture/second.json")"; topic2="$vault/notes/$generation2.adoc"
[[ "$(jq -r '.chapters[0].chapter_uuid' "$source_file[1]")" == "$chapter" ]]
[[ "$(awk '/^:key-topic:/{sub(/^:key-topic:[[:space:]]*/,"");print;exit}' "$chapter_file")" == 'Reading Two' ]]
[[ "$(grep -cF "link:$generation2.adoc[Bound Book]" "$chapter_file")" == 1 ]]
! grep -qF "link:$generation1.adoc[Bound Book]" "$chapter_file"
[[ "$(grep -cF "link:$chapter.adoc[Chapter 1]" "$topic2")" == 1 ]]
"$erl/erl-check.zsh" --vault "$vault" --work "$work" --json | jq -e '.status=="ok"' >/dev/null

# Negative checker diagnostics distinguish key, attachment count and reciprocity/order.
cp "$chapter_file" "$fixture/chapter.saved"; sed -i.bak 's/:key-topic: Reading Two/:key-topic: Wrong/' "$chapter_file"; rm -f "$chapter_file.bak"
set +e; check="$($erl/erl-check.zsh --vault "$vault" --work "$work" --json)"; rc=$?; set -e
[[ "$rc" == 10 ]] && jq -e 'any(.diagnostics[];.code=="ERL-CHECK-027" and .reason=="mismatched_key")' <<< "$check" >/dev/null
cp "$fixture/chapter.saved" "$chapter_file"; sed -i.bak "/link:$generation2.adoc\[Bound Book\]/a\\
link:$generation1.adoc[Bound Book]" "$chapter_file"; rm -f "$chapter_file.bak"
set +e; check="$($erl/erl-check.zsh --vault "$vault" --work "$work" --json)"; rc=$?; set -e
[[ "$rc" == 10 ]] && jq -e 'any(.diagnostics[];.code=="ERL-CHECK-027" and .reason=="chapter_topic_count")' <<< "$check" >/dev/null
mv "$fixture/chapter.saved" "$chapter_file"
cp "$topic2" "$fixture/topic.saved"; sed -i.bak "/link:$chapter.adoc\[Chapter 1\]/d" "$topic2"; rm -f "$topic2.bak"
set +e; check="$($erl/erl-check.zsh --vault "$vault" --work "$work" --json)"; rc=$?; set -e
[[ "$rc" == 10 ]] && jq -e 'any(.diagnostics[];.code=="ERL-CHECK-027" and (.reason=="topic_chapter_order" or .reason=="topic_chapter_link"))' <<< "$check" >/dev/null
cp "$fixture/topic.saved" "$topic2"; sed -i.bak "/link:$chapter.adoc\[Chapter 1\]/a\\
link:$chapter.adoc[Chapter 1]" "$topic2"; rm -f "$topic2.bak"
set +e; check="$($erl/erl-check.zsh --vault "$vault" --work "$work" --json)"; rc=$?; set -e
[[ "$rc" == 10 ]] && jq -e 'any(.diagnostics[];.code=="ERL-CHECK-027" and .reason=="topic_chapter_order")' <<< "$check" >/dev/null
mv "$fixture/topic.saved" "$topic2"

chapter2="77777777-7777-4777-8777-777777777777"; chapter2_file="$vault/notes/$chapter2.adoc"
print -r -- "= Chapter 2
:type: note
:description: Chapter 2
:doclink: link:$chapter2.adoc[Chapter 2]
:docfilename: $chapter2.adoc
:key-topic: Reading Two

== Book

link:$generation2.adoc[Bound Book]

== Source

Book:: Bound Book
Chapter locator:: chapter-2.txt" > "$chapter2_file"
cp "$source_file[1]" "$fixture/source.saved"; cp "$topic2" "$fixture/topic.saved"
jq --arg chapter "$chapter2" --arg source "$(jq -r .source_id "$source_file[1]")" '.chapters += [{chapter_uuid:$chapter,source_id:$source,chapter_locator:"chapter-2.txt",source_order:2}]' "$source_file[1]" > "$source_file[1].tmp"; mv "$source_file[1].tmp" "$source_file[1]"
sed -i.bak "/link:$chapter.adoc\[Chapter 1\]/i\\
link:$chapter2.adoc[Chapter 2]" "$topic2"; rm -f "$topic2.bak"
set +e; check="$($erl/erl-check.zsh --vault "$vault" --work "$work" --json)"; rc=$?; set -e
[[ "$rc" == 10 ]] && jq -e 'any(.diagnostics[];.code=="ERL-CHECK-027" and .reason=="topic_chapter_order")' <<< "$check" >/dev/null
mv "$fixture/source.saved" "$source_file[1]"; mv "$fixture/topic.saved" "$topic2"; rm -f "$chapter2_file"

# Legacy gaps are repaired only by explicit, mutation-free/idempotent migration.
awk '!/^:key-topic:/{if($0=="== Book"){skip=1;next} if(skip&&/^== /){skip=0} if(!skip)print}' "$chapter_file" > "$chapter_file.tmp"; mv "$chapter_file.tmp" "$chapter_file"
awk '{if($0=="== Chapters"){skip=1;next} if(skip&&/^== /){skip=0} if(!skip)print}' "$topic2" > "$topic2.tmp"; mv "$topic2.tmp" "$topic2"
legacy_hash="$(shasum -a 256 "$chapter_file" "$topic2")"
"$erl/erl-chapter-topic-binding-migrate.zsh" --vault "$vault" --generation "$generation2" --dry-run --json | jq -e '.changed==false and .data.document_count==2' >/dev/null
[[ "$legacy_hash" == "$(shasum -a 256 "$chapter_file" "$topic2")" ]]
set +e
ERL_TEST_INTERRUPT_CHAPTER_TOPIC_MIGRATION=1 "$erl/erl-chapter-topic-binding-migrate.zsh" --vault "$vault" --generation "$generation2" --apply --json > "$fixture/migration-interrupted.json"
migration_rc=$?
set -e
[[ "$migration_rc" == 60 ]]
migration_txid="$(for tx_file in "$vault"/.state/erl/transactions/*/transaction.json(N); do jq -r 'select(.operation=="erl-chapter-topic-binding-migrate" and .phase=="applied")|.txid' "$tx_file"; done | head -n1)"
"$erl/erl-transaction-recover.zsh" --vault "$vault" --txid "$migration_txid" --apply --json | jq -e '.changed==true' >/dev/null
[[ "$legacy_hash" == "$(shasum -a 256 "$chapter_file" "$topic2")" ]]
"$erl/erl-chapter-topic-binding-migrate.zsh" --vault "$vault" --generation "$generation2" --apply --json | jq -e '.changed==true' >/dev/null
"$erl/erl-chapter-topic-binding-migrate.zsh" --vault "$vault" --generation "$generation2" --apply --json | jq -e '.code=="ALREADY_CURRENT" and .changed==false' >/dev/null
"$erl/erl-check.zsh" --vault "$vault" --work "$work" --json | jq -e '.status=="ok"' >/dev/null
print -r -- 'PASS: Chapter Topic binding'
