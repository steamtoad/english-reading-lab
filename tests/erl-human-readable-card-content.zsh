#!/bin/zsh

#------------------------------------------------------------------------------
# erl-human-readable-card-content.zsh
# Тип: ERL regression test
# Назначение: проверить создание, validation, audit и repair readable ERL cards
#------------------------------------------------------------------------------

emulate -L zsh
setopt errexit pipe_fail no_unset

repo="${0:A:h:h}"
source "$repo/.scripts/erl/lib/card-content.zsh"
checker="$repo/.scripts/erl/erl-check.zsh"
repair="$repo/.scripts/erl/erl-card-content-repair.zsh"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/erl-readable-cards.XXXXXX")"
trap 'rm -rf -- "$fixture"' EXIT HUP INT TERM
mkdir -p "$fixture/notes" "$fixture/.state/erl/works/book/sources" "$fixture/.state/erl/works/book/generations" "$fixture/.state/erl/transactions"

work="11111111-1111-4111-8111-111111111111"
source_id="22222222-2222-4222-8222-222222222222"
generation="aaaaaaaa-aaaa-1aaa-8aaa-aaaaaaaaaaaa"
chapter="bbbbbbbb-bbbb-1bbb-8bbb-bbbbbbbbbbbb"
vocabulary="cccccccc-cccc-1ccc-8ccc-cccccccccccc"
occurrence="dddddddd-dddd-1ddd-8ddd-dddddddddddd"

header() {
  local title="$1" type="$2" uuid="$3" extra="${4:-}"
  print -r -- "= $title
:date: 2026-09-01
:keywords: $type
:type: $type
:author: test
:description: $title
:doclink: link:$uuid.adoc[$title]
:docfilename: $uuid.adoc${extra}
"
}

header 'A Human Book' topic "$generation" $'\n:key-topic: Reading' > "$fixture/notes/$generation.adoc"
print -r -- "== Chapters

link:$chapter.adoc[Chapter 1]" >> "$fixture/notes/$generation.adoc"
header 'Chapter 1' note "$chapter" $'\n:key-topic: Reading' > "$fixture/notes/$chapter.adoc"
print -r -- '== Source

Book:: A Human Book
Chapter locator:: chapter-1.xhtml' >> "$fixture/notes/$chapter.adoc"
print -r -- "
== Book

link:$generation.adoc[A Human Book]" >> "$fixture/notes/$chapter.adoc"
print -r -- "
== Vocabulary

link:$vocabulary.adoc[forlorn]
link:$occurrence.adoc[forlorn occurrence]" >> "$fixture/notes/$chapter.adoc"
header 'forlorn' memo "$vocabulary" $'\n:key-topic: Reading' > "$fixture/notes/$vocabulary.adoc"
print -r -- '== Lexical identity

Lemma:: forlorn
POS:: adjective
Lexical type:: word

== Meaning

Definition:: sad and lonely
Translation:: покинутый

== Context

The forlorn traveller waited.' >> "$fixture/notes/$vocabulary.adoc"
print -r -- "
== Chapter

link:$chapter.adoc[Chapter 1]

== Memo Chain

link:$occurrence.adoc[Следующее memo]" >> "$fixture/notes/$vocabulary.adoc"
header 'forlorn occurrence' memo "$occurrence" $'\n:key-topic: Reading' > "$fixture/notes/$occurrence.adoc"
print -r -- "== Vocabulary

link:$vocabulary.adoc[forlorn]

== Context

The forlorn traveller waited.

== Chapter

link:$chapter.adoc[Chapter 1]

== Memo Chain

link:$vocabulary.adoc[Предыдущее memo]" >> "$fixture/notes/$occurrence.adoc"

print -r -- "{\"schema_version\":1,\"work_id\":\"$work\",\"title\":\"A Human Book\",\"generation_uuids\":[\"$generation\"],\"active_generation_uuid\":\"$generation\"}" > "$fixture/.state/erl/works/book/work.json"
print -r -- "{\"schema_version\":1,\"source_id\":\"$source_id\",\"work_id\":\"$work\",\"source_fingerprint\":\"sha256:$(printf 'a%.0s' {1..64})\",\"chapters\":[{\"chapter_uuid\":\"$chapter\",\"source_id\":\"$source_id\",\"chapter_locator\":\"chapter-1.xhtml\",\"source_order\":1}]}" > "$fixture/.state/erl/works/book/sources/$source_id.json"
print -r -- "{\"schema_version\":1,\"generation_uuid\":\"$generation\",\"work_id\":\"$work\",\"source_id\":\"$source_id\",\"policy_identity\":\"sha256:$(printf 'b%.0s' {1..64})\",\"sequence\":[{\"ordinal\":1,\"chapter_uuid\":\"$chapter\",\"role\":\"vocabulary\",\"document_uuid\":\"$vocabulary\"},{\"ordinal\":2,\"chapter_uuid\":\"$chapter\",\"role\":\"occurrence\",\"document_uuid\":\"$occurrence\"}],\"ingestion_receipts\":[]}" > "$fixture/.state/erl/works/book/generations/$generation.json"

# Positive role fixtures meet the deterministic structural floor.
for pair in "${chapter}:chapter" "${vocabulary}:vocabulary" "${occurrence}:occurrence"; do
  uuid="${pair%%:*}"; role="${pair#*:}"
  [[ -z "$(erl_card_content_findings "$fixture/notes/$uuid.adoc" "$role")" ]] || { print -ru2 -- "FAIL: valid $role card rejected"; exit 1; }
done

# Every forbidden condition has a focused negative fixture.
negative="$fixture/negative.adoc"
assert_finding() { [[ "$(erl_card_content_findings "$negative" vocabulary)" == *"$1"* ]] || { print -ru2 -- "FAIL: missing finding: $1"; exit 1; }; }
print -r -- '= Broken' > "$negative"; assert_finding 'empty document body'
print -r -- $'= Broken\n\n==Bad' > "$negative"; assert_finding 'malformed AsciiDoc heading'
print -r -- $'= Broken\n\n{{VALUE}}' > "$negative"; assert_finding 'unresolved template placeholder'
print -r -- $'= Broken\n\n{"state":true}' > "$negative"; assert_finding 'raw JSON serialization'
print -r -- $'= Broken\n\n---\nstate: true' > "$negative"; assert_finding 'raw YAML serialization'
print -r -- $'= Broken\n\n<html>raw</html>' > "$negative"; assert_finding 'raw HTML/XML markup'
print -r -- $'= Broken\n\nText.\001' > "$negative"; assert_finding 'control character'
print -r -- "= Broken

link:$vocabulary.adoc[Description]" > "$negative"; assert_finding 'unreadable label'
printf '= Broken\n\n\377\n' > "$negative"; assert_finding 'invalid UTF-8'

# Audit is byte-stable, apply is journaled, and an injected failure restores exact bytes.
before="$(shasum -a 256 "$fixture/notes/$generation.adoc" "$fixture/.state/erl/works/book/work.json")"
"$repair" --vault "$fixture" --document "$generation" --dry-run --json > "$fixture/audit.json"
jq -e '.code=="AUDIT_COMPLETE" and .changed==false and .data.repairable==1 and .data.blocked==0' "$fixture/audit.json" >/dev/null
[[ "$before" == "$(shasum -a 256 "$fixture/notes/$generation.adoc" "$fixture/.state/erl/works/book/work.json")" ]] || { print -ru2 -- 'FAIL: audit mutated files'; exit 1; }

set +e
ERL_TEST_INTERRUPT_CARD_REPAIR_AFTER_MUTATION=1 "$repair" --vault "$fixture" --document "$generation" --apply --json > "$fixture/interrupted.json"
interrupted_rc=$?
set -e
[[ "$interrupted_rc" == 60 ]] || { print -ru2 -- 'FAIL: repair interruption fixture'; exit 1; }
interrupted_tx="$(for tx_file in "$fixture"/.state/erl/transactions/*/transaction.json(N); do jq -r 'select(.operation=="erl-card-content-repair" and .phase=="applied") | .txid' "$tx_file"; done | head -n 1)"
[[ -n "$interrupted_tx" ]] || { print -ru2 -- 'FAIL: interrupted repair journal missing'; exit 1; }
"$repo/.scripts/erl/erl-transaction-recover.zsh" --vault "$fixture" --txid "$interrupted_tx" --dry-run --json | jq -e '.changed==false and .data.recovery_action=="rollback"' >/dev/null
"$repo/.scripts/erl/erl-transaction-recover.zsh" --vault "$fixture" --txid "$interrupted_tx" --apply --json | jq -e '.changed==true and .data.recovery_action=="rollback"' >/dev/null
[[ "$before" == "$(shasum -a 256 "$fixture/notes/$generation.adoc" "$fixture/.state/erl/works/book/work.json")" ]] || { print -ru2 -- 'FAIL: recovery did not restore exact bytes'; exit 1; }

set +e
ERL_TEST_FAIL_CARD_REPAIR_AFTER_MUTATION=1 "$repair" --vault "$fixture" --document "$generation" --apply --json > "$fixture/fault.json"
fault_rc=$?
set -e
[[ "$fault_rc" == 60 ]] && jq -e '.code=="TRANSACTION_FAILED" and .changed==false' "$fixture/fault.json" >/dev/null || { print -ru2 -- 'FAIL: injected repair failure contract'; exit 1; }
[[ "$before" == "$(shasum -a 256 "$fixture/notes/$generation.adoc" "$fixture/.state/erl/works/book/work.json")" ]] || { print -ru2 -- 'FAIL: rollback did not restore exact bytes'; exit 1; }

"$repair" --vault "$fixture" --document "$generation" --apply --json > "$fixture/apply.json"
jq -e '.code=="OK" and .changed==true and .data.txid' "$fixture/apply.json" >/dev/null
"$checker" --vault "$fixture" --json | jq -e '.status=="ok" and .data.counts.errors==0' >/dev/null
rg -q '^== Book$|^Title:: A Human Book$|^Reading topic:: Reading$' "$fixture/notes/$generation.adoc"
! rg -q '^:erl-' "$fixture/notes"/*.adoc

# Missing lexical meaning is intentionally ambiguous and blocks apply.
cp "$fixture/notes/$vocabulary.adoc" "$fixture/vocabulary.saved"
awk '/^== Meaning$/{exit} {print}' "$fixture/vocabulary.saved" > "$fixture/notes/$vocabulary.adoc"
set +e
"$repair" --vault "$fixture" --document "$vocabulary" --apply --json > "$fixture/conflict.json"
conflict_rc=$?
set -e
[[ "$conflict_rc" == 30 ]] && jq -e '.code=="REPAIR_CONFLICT" and .changed==false and .data.blocked==1' "$fixture/conflict.json" >/dev/null || { print -ru2 -- 'FAIL: ambiguous repair was not blocked'; exit 1; }

print -r -- 'PASS: human-readable ERL card content'
