#!/bin/zsh

#------------------------------------------------------------------------------
# erl-chapter-memo-chain.zsh
# Тип: ERL regression test
# Назначение: проверить Chapter attachment, Memo Chain, rollback и migration
#------------------------------------------------------------------------------

emulate -L zsh
setopt errexit pipe_fail no_unset
repo="${0:A:h:h}"; erl="$repo/.scripts/erl"
export ERL_HOST_HOME="$repo/fixtures/host-contract"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/erl-chapter-memo-chain.XXXXXX")"
if [[ -z "${ERL_TEST_KEEP:-}" ]]; then trap 'rm -rf -- "$fixture"' EXIT HUP INT TERM; else print -ru2 -- "Fixture retained: $fixture"; fi
mkdir -p "$fixture/notes" "$fixture/.state/erl/works/book/sources" "$fixture/.state/erl/works/book/generations" "$fixture/.state/erl/staging" "$fixture/.state/erl/transactions"
work="11111111-1111-4111-8111-111111111111"; source_id="22222222-2222-4222-8222-222222222222"
generation="33333333-3333-4333-8333-333333333333"; chapter="44444444-4444-4444-8444-444444444444"
extraction="55555555-5555-4555-8555-555555555555"; policy="sha256:$(printf 'a%.0s' {1..64})"
print -r -- "= Chain Book
:type: topic
:description: Chain Book
:doclink: link:$generation.adoc[Chain Book]
:docfilename: $generation.adoc
:key-topic: Reading

== Book

Title:: Chain Book
Reading topic:: Reading

== Chapters

link:$chapter.adoc[Chapter 1]
" > "$fixture/notes/$generation.adoc"
print -r -- "= Chapter 1
:type: note
:description: Chapter 1
:doclink: link:$chapter.adoc[Chapter 1]
:docfilename: $chapter.adoc
:key-topic: Reading

== Book

link:$generation.adoc[Chain Book]
" > "$fixture/notes/$chapter.adoc"
print -r -- "{\"schema_version\":1,\"work_id\":\"$work\",\"title\":\"Chain Book\",\"generation_uuids\":[\"$generation\"],\"active_generation_uuid\":\"$generation\"}" > "$fixture/.state/erl/works/book/work.json"
print -r -- "{\"schema_version\":1,\"source_id\":\"$source_id\",\"work_id\":\"$work\",\"source_fingerprint\":\"sha256:$(printf 'b%.0s' {1..64})\",\"chapters\":[{\"chapter_uuid\":\"$chapter\",\"source_id\":\"$source_id\",\"chapter_locator\":\"chapter.txt\",\"source_order\":1}]}" > "$fixture/.state/erl/works/book/sources/$source_id.json"
print -r -- "{\"schema_version\":1,\"generation_uuid\":\"$generation\",\"work_id\":\"$work\",\"source_id\":\"$source_id\",\"status\":\"active\",\"policy_identity\":\"$policy\",\"sequence\":[],\"members\":[],\"ingestion_receipts\":[]}" > "$fixture/.state/erl/works/book/generations/$generation.json"
jq -n --arg extraction "$extraction" --arg generation "$generation" --arg chapter "$chapter" --arg policy "$policy" '{schema_version:1,extraction_id:$extraction,generation_uuid:$generation,chapter_uuid:$chapter,policy_identity:$policy,candidates:[
  {ordinal:1,surface_form:"forlorn",lemma:"forlorn",pos:"adjective",lexical_type:"word",context:"A forlorn figure.",enrichment:{translation_ru:["покинутый"],definition_en:"sad and abandoned",ipa:"/fəˈlɔːn/",cefr:{value:"C1"}}},
  {ordinal:2,surface_form:"forlorn",lemma:"forlorn",pos:"adjective",lexical_type:"word",context:"Still forlorn.",enrichment:{translation_ru:["покинутый"],definition_en:"sad and abandoned",ipa:"/fəˈlɔːn/",cefr:{value:"C1"}}}
]}' > "$fixture/.state/erl/staging/$extraction.json"

"$erl/erl-chapter-vocabulary-ingest.zsh" --vault "$fixture" --extraction-id "$extraction" --apply --json > "$fixture/result.json" || { print -ru2 -- "$(<"$fixture/result.json")"; exit 1; }
jq -e '.status=="ok" and .data.created_vocabulary==1 and .data.created_occurrences==1' "$fixture/result.json" >/dev/null
generation_file="$fixture/.state/erl/works/book/generations/$generation.json"
first="$(jq -r '.sequence[0].document_uuid' "$generation_file")"; second="$(jq -r '.sequence[1].document_uuid' "$generation_file")"
[[ "$(awk '/^:key-topic:/{sub(/^:key-topic:[[:space:]]*/,"");print;exit}' "$fixture/notes/$first.adoc")" == Reading ]]
[[ "$(awk '/^:key-topic:/{sub(/^:key-topic:[[:space:]]*/,"");print;exit}' "$fixture/notes/$second.adoc")" == Reading ]]
[[ "$(grep -cF "link:$chapter.adoc[Chapter 1]" "$fixture/notes/$first.adoc")" == 1 ]]
[[ "$(grep -cF "link:$chapter.adoc[Chapter 1]" "$fixture/notes/$second.adoc")" == 1 ]]
[[ "$(grep -cF "link:$first.adoc[forlorn]" "$fixture/notes/$chapter.adoc")" == 1 ]]
[[ "$(grep -cF "link:$second.adoc[forlorn]" "$fixture/notes/$chapter.adoc")" == 1 ]]
! grep -qF '[Предыдущее memo]' "$fixture/notes/$first.adoc"
grep -qF "link:$second.adoc[Следующее memo]" "$fixture/notes/$first.adoc"
grep -qF "link:$first.adoc[Предыдущее memo]" "$fixture/notes/$second.adoc"
! grep -qF '[Следующее memo]' "$fixture/notes/$second.adoc"
"$erl/erl-chapter-vocabulary-ingest.zsh" --vault "$fixture" --extraction-id "$extraction" --apply --json | jq -e '.code=="ALREADY_INGESTED"' >/dev/null
[[ "$(grep -cF "link:$first.adoc[forlorn]" "$fixture/notes/$chapter.adoc")" == 1 ]]
"$erl/erl-check.zsh" --vault "$fixture" --generation "$generation" --json | jq -e '.status=="ok" and .data.counts.errors==0' >/dev/null

# Per-Candidate failure and interruption restore Chapter, predecessor and state bytes.
fault_extraction="66666666-6666-4666-8666-666666666666"
jq --arg extraction "$fault_extraction" '.extraction_id=$extraction | .candidates=[(.candidates[0] | .surface_form="bleak" | .lemma="bleak" | .context="A bleak place.")]' "$fixture/.state/erl/staging/$extraction.json" > "$fixture/.state/erl/staging/$fault_extraction.json"
before_candidate="$(shasum -a 256 "$fixture/notes/$chapter.adoc" "$fixture/notes/$second.adoc" "$generation_file")"
set +e
ERL_TEST_FAIL_VOCABULARY_AFTER_DOCUMENTS=1 "$erl/erl-vocabulary-ingest.zsh" --vault "$fixture" --extraction-id "$fault_extraction" --candidate 1 --apply --json > "$fixture/fault.json"
fault_rc=$?
set -e
[[ "$fault_rc" == 60 && "$before_candidate" == "$(shasum -a 256 "$fixture/notes/$chapter.adoc" "$fixture/notes/$second.adoc" "$generation_file")" ]]
set +e
ERL_TEST_INTERRUPT_VOCABULARY_AFTER_DOCUMENTS=1 "$erl/erl-vocabulary-ingest.zsh" --vault "$fixture" --extraction-id "$fault_extraction" --candidate 1 --apply --json > "$fixture/interrupted.json"
interrupt_rc=$?
set -e
[[ "$interrupt_rc" == 60 ]]
txid="$(for tx_file in "$fixture"/.state/erl/transactions/*/transaction.json(N); do jq -r --arg extraction "$fault_extraction" 'select(.operation=="erl-vocabulary-ingest" and .phase=="documents_updated" and .extraction_id==$extraction)|.txid' "$tx_file"; done | head -n1)"
"$erl/erl-transaction-recover.zsh" --vault "$fixture" --txid "$txid" --apply --json | jq -e '.changed==true and .data.recovery_action=="rollback"' >/dev/null
[[ "$before_candidate" == "$(shasum -a 256 "$fixture/notes/$chapter.adoc" "$fixture/notes/$second.adoc" "$generation_file")" ]]

# Explicit legacy migration is mutation-free in dry-run and idempotent on apply.
for memo in "$first" "$second"; do
  awk '!/^:key-topic:/{if(/^== (Chapter|Memo Chain)$/){skip=1;next} if(skip&&/^== /){skip=0} if(!skip)print}' "$fixture/notes/$memo.adoc" > "$fixture/notes/$memo.adoc.tmp"
  mv -- "$fixture/notes/$memo.adoc.tmp" "$fixture/notes/$memo.adoc"
done
awk '{if(/^== Vocabulary$/){skip=1;next} if(skip&&/^== /){skip=0} if(!skip)print}' "$fixture/notes/$chapter.adoc" > "$fixture/notes/$chapter.adoc.tmp"
mv -- "$fixture/notes/$chapter.adoc.tmp" "$fixture/notes/$chapter.adoc"
before="$(shasum -a 256 "$fixture/notes/$chapter.adoc" "$fixture/notes/$first.adoc" "$fixture/notes/$second.adoc")"
"$erl/erl-chapter-memo-chain-migrate.zsh" --vault "$fixture" --generation "$generation" --dry-run --json | jq -e '.changed==false and .data.document_count==2' >/dev/null
[[ "$before" == "$(shasum -a 256 "$fixture/notes/$chapter.adoc" "$fixture/notes/$first.adoc" "$fixture/notes/$second.adoc")" ]]
"$erl/erl-chapter-memo-chain-migrate.zsh" --vault "$fixture" --generation "$generation" --apply --json | jq -e '.changed==true and .data.document_count==2' >/dev/null
"$erl/erl-chapter-memo-chain-migrate.zsh" --vault "$fixture" --generation "$generation" --apply --json | jq -e '.code=="ALREADY_CURRENT" and .changed==false' >/dev/null
"$erl/erl-check.zsh" --vault "$fixture" --generation "$generation" --json | jq -e '.status=="ok"' >/dev/null
print -r -- 'PASS: Chapter Memo Chain'
