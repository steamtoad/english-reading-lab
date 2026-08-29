#!/bin/zsh

emulate -L zsh
setopt errexit pipe_fail no_unset

repo="${0:A:h:h}"
checker="$repo/.scripts/erl/erl-check.zsh"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/erl-check-test.XXXXXX")"
if [[ -z "${ERL_TEST_KEEP:-}" ]]; then
  trap 'rm -rf -- "$fixture"' EXIT HUP INT TERM
else
  print -ru2 -- "Fixture retained: $fixture"
fi

work_id="11111111-1111-4111-8111-111111111111"
source_id="22222222-2222-4222-8222-222222222222"
extraction_id="33333333-3333-4333-8333-333333333333"
generation="aaaaaaaa-aaaa-1aaa-8aaa-aaaaaaaaaaaa"
generation_two="eeeeeeee-eeee-1eee-8eee-eeeeeeeeeeee"
chapter="bbbbbbbb-bbbb-1bbb-8bbb-bbbbbbbbbbbb"
vocabulary="cccccccc-cccc-1ccc-8ccc-cccccccccccc"
occurrence="dddddddd-dddd-1ddd-8ddd-dddddddddddd"

mkdir -p "$fixture/notes" \
  "$fixture/.state/erl/works/example/sources" \
  "$fixture/.state/erl/works/example/generations" \
  "$fixture/.state/erl/transactions"

write_topic() {
  print -r -- "= English Reading - ключевая тема
:date: 2026-08-29
:keywords: topic
:type: topic
:author: test
:description: English Reading
:doclink: link:$generation.adoc[English Reading]
:docfilename: $generation.adoc
:key-topic: English Reading

" > "$fixture/notes/$generation.adoc"
}

write_note() {
  print -r -- "= Chapter 1
:date: 2026-08-29
:keywords: note
:type: note
:author: test
:description: Chapter 1
:doclink: link:$chapter.adoc[Chapter 1]
:docfilename: $chapter.adoc

Text.
" > "$fixture/notes/$chapter.adoc"
}

write_vocabulary() {
  local deprecated="${1:-}"
  print -r -- "= Forlorn
:date: 2026-08-29
:keywords: memo
:type: memo
:author: test
:description: forlorn
:doclink: link:$vocabulary.adoc[forlorn]
:docfilename: $vocabulary.adoc${deprecated}

== Lexical identity

Lemma:: forlorn
POS:: adjective
Lexical type:: word
" > "$fixture/notes/$vocabulary.adoc"
}

write_occurrence() {
  print -r -- "= Forlorn occurrence
:date: 2026-08-29
:keywords: memo
:type: memo
:author: test
:description: forlorn occurrence
:doclink: link:$occurrence.adoc[forlorn occurrence]
:docfilename: $occurrence.adoc

== Vocabulary

link:$vocabulary.adoc[Forlorn]

== Context

The context.
" > "$fixture/notes/$occurrence.adoc"
}

write_state() {
  print -r -- "{
  \"schema_version\": 1,
  \"work_id\": \"$work_id\",
  \"generation_uuids\": [\"$generation\"],
  \"active_generation_uuid\": \"$generation\"
}" > "$fixture/.state/erl/works/example/work.json"

  print -r -- "{
  \"schema_version\": 1,
  \"source_id\": \"$source_id\",
  \"work_id\": \"$work_id\",
  \"source_fingerprint\": \"sha256:$(printf 'a%.0s' {1..64})\",
  \"chapters\": [{
    \"chapter_uuid\": \"$chapter\",
    \"chapter_locator\": \"OEBPS/chapter-01.xhtml\",
    \"source_order\": 1
  }]
}" > "$fixture/.state/erl/works/example/sources/$source_id.json"

  print -r -- "{
  \"schema_version\": 1,
  \"generation_uuid\": \"$generation\",
  \"work_id\": \"$work_id\",
  \"policy_identity\": \"sha256:$(printf 'b%.0s' {1..64})\",
  \"sequence\": [
    {\"ordinal\":1,\"chapter_uuid\":\"$chapter\",\"role\":\"vocabulary\",\"document_uuid\":\"$vocabulary\"},
    {\"ordinal\":2,\"chapter_uuid\":\"$chapter\",\"role\":\"occurrence\",\"document_uuid\":\"$occurrence\"}
  ],
  \"ingestion_receipts\": [{\"extraction_id\":\"$extraction_id\",\"status\":\"completed\"}]
}" > "$fixture/.state/erl/works/example/generations/$generation.json"
}

assert_json() {
  local expected_rc="$1" jq_filter="$2"
  shift 2
  local output rc
  set +e
  output="$($checker --vault "$fixture" --json "$@")"
  rc=$?
  set -e
  [[ "$rc" == "$expected_rc" ]] || {
    print -ru2 -- "FAIL: expected exit $expected_rc, got $rc"
    print -ru2 -- "$output"
    return 1
  }
  jq -e "$jq_filter" <<< "$output" >/dev/null || {
    print -ru2 -- "FAIL: JSON assertion: $jq_filter"
    print -ru2 -- "$output"
    return 1
  }
}

write_topic
write_note
write_vocabulary
write_occurrence
write_state

assert_json 0 '.status=="ok" and .code=="OK" and .changed==false and .data.counts.errors==0'
assert_json 0 '.status=="ok" and .data.scope.kind=="generation"' --generation "$generation"
assert_json 20 '.status=="error" and .code=="NOT_FOUND"' --work 99999999-9999-4999-8999-999999999999

before_hash="$(find "$fixture" -type f -print0 | sort -z | xargs -0 shasum -a 256 | shasum -a 256)"
$checker --vault "$fixture" --json >/dev/null
after_hash="$(find "$fixture" -type f -print0 | sort -z | xargs -0 shasum -a 256 | shasum -a 256)"
[[ "$before_hash" == "$after_hash" ]] || {
  print -ru2 -- "FAIL: erl-check changed fixture content"
  exit 1
}

mkdir -p "$fixture/.state/erl/transactions/44444444-4444-4444-8444-444444444444"
print -r -- '{"phase":"applying"}' > "$fixture/.state/erl/transactions/44444444-4444-4444-8444-444444444444/transaction.json"
assert_json 0 '.status=="warning" and .code=="PENDING_TRANSACTION" and any(.diagnostics[]; .code=="ERL-CHECK-018")'
rm -rf -- "$fixture/.state/erl/transactions/44444444-4444-4444-8444-444444444444"

print -r -- "= English Reading second generation - ключевая тема
:date: 2026-08-29
:keywords: topic
:type: topic
:author: test
:description: English Reading second generation
:doclink: link:$generation_two.adoc[English Reading second generation]
:docfilename: $generation_two.adoc
:key-topic: English Reading

" > "$fixture/notes/$generation_two.adoc"
print -r -- "{
  \"schema_version\": 1,
  \"generation_uuid\": \"$generation_two\",
  \"work_id\": \"$work_id\",
  \"policy_identity\": \"sha256:$(printf 'c%.0s' {1..64})\",
  \"sequence\": [],
  \"ingestion_receipts\": []
}" > "$fixture/.state/erl/works/example/generations/$generation_two.json"
jq --arg generation "$generation_two" '.generation_uuids += [$generation]' \
  "$fixture/.state/erl/works/example/work.json" > "$fixture/.state/erl/works/example/work.json.tmp"
mv -- "$fixture/.state/erl/works/example/work.json.tmp" "$fixture/.state/erl/works/example/work.json"
assert_json 10 '.status=="error" and .code=="VALIDATION_FAILED" and any(.diagnostics[]; .code=="ERL-CHECK-010")'
rm -f -- "$fixture/notes/$generation_two.adoc" "$fixture/.state/erl/works/example/generations/$generation_two.json"
jq --arg generation "$generation_two" '.generation_uuids |= map(select(. != $generation))' \
  "$fixture/.state/erl/works/example/work.json" > "$fixture/.state/erl/works/example/work.json.tmp"
mv -- "$fixture/.state/erl/works/example/work.json.tmp" "$fixture/.state/erl/works/example/work.json"

sed -i.bak '/:docfilename:/a\
:erl-kind: vocabulary' "$fixture/notes/$vocabulary.adoc"
rm -f -- "$fixture/notes/$vocabulary.adoc.bak"
assert_json 10 '.status=="error" and .code=="VALIDATION_FAILED" and any(.diagnostics[]; .code=="ERL-CHECK-020")'
sed -i.bak '/:erl-kind:/d' "$fixture/notes/$vocabulary.adoc"
rm -f -- "$fixture/notes/$vocabulary.adoc.bak"

write_vocabulary $'\n:deprecated:'
assert_json 0 '.status=="warning" and .code=="CLOSURE_REQUIRED" and any(.diagnostics[]; .code=="ERL-CHECK-006")'

empty_vault="$fixture/empty-vault"
transaction_vault="$fixture/transaction-vault"
mkdir -p "$empty_vault" "$transaction_vault/.state/erl/transactions/55555555-5555-4555-8555-555555555555"
set +e
empty_output="$($checker --vault "$empty_vault" --work 99999999-9999-4999-8999-999999999999 --json)"
empty_rc=$?
set -e
[[ "$empty_rc" == 20 ]] && jq -e '.status=="error" and .code=="NOT_FOUND"' <<< "$empty_output" >/dev/null || {
  print -ru2 -- "FAIL: absent works/ masked a missing scoped entity"
  exit 1
}
print -r -- '{"phase":"applying"}' > "$transaction_vault/.state/erl/transactions/55555555-5555-4555-8555-555555555555/transaction.json"
transaction_output="$($checker --vault "$transaction_vault" --json)"
jq -e '.status=="warning" and .code=="PENDING_TRANSACTION" and any(.diagnostics[]; .code=="ERL-CHECK-018")' \
  <<< "$transaction_output" >/dev/null || {
  print -ru2 -- "FAIL: absent works/ masked an unfinished transaction"
  exit 1
}

print -r -- "PASS: erl-check fixtures"
