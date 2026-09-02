#!/bin/zsh

#------------------------------------------------------------------------------
# erl-chapter-chain-handoff.zsh
# Тип: ERL regression test
# Назначение: проверить Chapter tail handoff, validation, retry и recovery
#------------------------------------------------------------------------------

emulate -L zsh
setopt errexit pipe_fail no_unset

repo="${0:A:h:h}"; command="$repo/.scripts/erl/erl-chapter-chain-handoff.zsh"; checker="$repo/.scripts/erl/erl-check.zsh"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/erl-chapter-handoff.XXXXXX")"
if [[ -z "${ERL_TEST_KEEP:-}" ]]; then trap 'rm -rf -- "$fixture"' EXIT HUP INT TERM; else print -ru2 -- "Fixture retained: $fixture"; fi
mkdir -p "$fixture/notes" "$fixture/.state/erl/works/book/sources" "$fixture/.state/erl/works/book/generations" "$fixture/.state/erl/transactions"

work="11111111-1111-4111-8111-111111111111"; source_id="22222222-2222-4222-8222-222222222222"
generation="aaaaaaaa-aaaa-1aaa-8aaa-aaaaaaaaaaaa"
chapter1="bbbbbbbb-bbbb-1bbb-8bbb-bbbbbbbbbbb1"; chapter2="bbbbbbbb-bbbb-1bbb-8bbb-bbbbbbbbbbb2"; chapter3="bbbbbbbb-bbbb-1bbb-8bbb-bbbbbbbbbbb3"
memo1="cccccccc-cccc-1ccc-8ccc-ccccccccccc1"; memo2="cccccccc-cccc-1ccc-8ccc-ccccccccccc2"; memo3="cccccccc-cccc-1ccc-8ccc-ccccccccccc3"

write_doc() {
  local uuid="$1" title="$2" type="$3" body="$4" extra="${5:-}"
  print -r -- "= $title
:date: 2026-09-01
:keywords: $type
:type: $type
:author: test
:description: $title
:doclink: link:$uuid.adoc[$title]
:docfilename: $uuid.adoc${extra}

$body" > "$fixture/notes/$uuid.adoc"
}
write_doc "$generation" 'Handoff Book' topic $'== Book\n\nTitle:: Handoff Book\nReading topic:: Reading' $'\n:key-topic: Reading'
print -r -- "
== Chapters

link:$chapter1.adoc[Chapter 1]
link:$chapter2.adoc[Chapter 2]
link:$chapter3.adoc[Chapter 3]" >> "$fixture/notes/$generation.adoc"
for item in "${chapter1}:Chapter 1" "${chapter2}:Chapter 2" "${chapter3}:Chapter 3"; do
  uuid="${item%%:*}"; title="${item#*:}"; write_doc "$uuid" "$title" note $'== Source\n\nBook:: Handoff Book\nChapter locator:: source.xhtml' $'\n:key-topic: Reading'
done
for item in "${chapter1}:Chapter 1" "${chapter2}:Chapter 2" "${chapter3}:Chapter 3"; do
  uuid="${item%%:*}"
  print -r -- "
== Book

link:$generation.adoc[Handoff Book]" >> "$fixture/notes/$uuid.adoc"
done
for item in "${memo1}:one" "${memo2}:two" "${memo3}:three"; do
  uuid="${item%%:*}"; lemma="${item#*:}"
  write_doc "$uuid" "$lemma" memo "== Lexical identity

Lemma:: $lemma
POS:: noun
Lexical type:: word

== Meaning

Definition:: readable $lemma" $'\n:key-topic: Reading'
done
print -r -- "
== Chapter

link:$chapter1.adoc[Chapter 1]

== Memo Chain

link:$memo2.adoc[Следующее memo]" >> "$fixture/notes/$memo1.adoc"
print -r -- "
== Chapter

link:$chapter1.adoc[Chapter 1]

== Memo Chain

link:$memo1.adoc[Предыдущее memo]" >> "$fixture/notes/$memo2.adoc"
print -r -- "
== Chapter

link:$chapter2.adoc[Chapter 2]" >> "$fixture/notes/$memo3.adoc"
print -r -- "
== Vocabulary

link:$memo1.adoc[one]
link:$memo2.adoc[two]" >> "$fixture/notes/$chapter1.adoc"
print -r -- "
== Vocabulary

link:$memo3.adoc[three]" >> "$fixture/notes/$chapter2.adoc"

print -r -- "{\"schema_version\":1,\"work_id\":\"$work\",\"title\":\"Handoff Book\",\"generation_uuids\":[\"$generation\"],\"active_generation_uuid\":\"$generation\"}" > "$fixture/.state/erl/works/book/work.json"
print -r -- "{\"schema_version\":1,\"source_id\":\"$source_id\",\"work_id\":\"$work\",\"source_fingerprint\":\"sha256:$(printf 'a%.0s' {1..64})\",\"chapters\":[{\"chapter_uuid\":\"$chapter1\",\"source_id\":\"$source_id\",\"chapter_locator\":\"one.xhtml\",\"source_order\":1},{\"chapter_uuid\":\"$chapter2\",\"source_id\":\"$source_id\",\"chapter_locator\":\"two.xhtml\",\"source_order\":2},{\"chapter_uuid\":\"$chapter3\",\"source_id\":\"$source_id\",\"chapter_locator\":\"three.xhtml\",\"source_order\":3}]}" > "$fixture/.state/erl/works/book/sources/$source_id.json"
print -r -- "{\"schema_version\":1,\"generation_uuid\":\"$generation\",\"work_id\":\"$work\",\"source_id\":\"$source_id\",\"policy_identity\":\"sha256:$(printf 'b%.0s' {1..64})\",\"sequence\":[{\"ordinal\":1,\"chapter_uuid\":\"$chapter1\",\"role\":\"vocabulary\",\"document_uuid\":\"$memo1\"},{\"ordinal\":2,\"chapter_uuid\":\"$chapter1\",\"role\":\"vocabulary\",\"document_uuid\":\"$memo2\"},{\"ordinal\":3,\"chapter_uuid\":\"$chapter2\",\"role\":\"vocabulary\",\"document_uuid\":\"$memo3\"}],\"ingestion_receipts\":[]}" > "$fixture/.state/erl/works/book/generations/$generation.json"

before="$(shasum -a 256 "$fixture/notes"/*.adoc "$fixture/.state/erl/works/book/generations/$generation.json")"
"$command" --vault "$fixture" --generation "$generation" --dry-run --json > "$fixture/plan.json"
jq -e '.changed==false and .data.pair_count==2 and .data.conflict_count==0' "$fixture/plan.json" >/dev/null
[[ "$before" == "$(shasum -a 256 "$fixture/notes"/*.adoc "$fixture/.state/erl/works/book/generations/$generation.json")" ]] || { print -ru2 -- 'FAIL: dry-run mutated Vault/state'; exit 1; }

set +e
ERL_TEST_FAIL_HANDOFF_AFTER_TAIL=1 "$command" --vault "$fixture" --generation "$generation" --chapter "$chapter1" --apply --json > "$fixture/fault.json"
fault_rc=$?
set -e
[[ "$fault_rc" == 60 ]] && [[ "$before" == "$(shasum -a 256 "$fixture/notes"/*.adoc "$fixture/.state/erl/works/book/generations/$generation.json")" ]] || { print -ru2 -- 'FAIL: handoff rollback did not restore bytes'; exit 1; }

set +e
ERL_TEST_INTERRUPT_HANDOFF=1 "$command" --vault "$fixture" --generation "$generation" --chapter "$chapter1" --apply --json > "$fixture/interrupted.json"
interrupt_rc=$?
set -e
[[ "$interrupt_rc" == 60 ]] || { print -ru2 -- 'FAIL: interruption did not require recovery'; exit 1; }
txid="$(for file in "$fixture"/.state/erl/transactions/*/transaction.json(N); do jq -r 'select(.operation=="erl-chapter-chain-handoff" and .phase=="applied")|.txid' "$file"; done | head -n1)"
"$repo/.scripts/erl/erl-transaction-recover.zsh" --vault "$fixture" --txid "$txid" --apply --json | jq -e '.changed==true and .data.recovery_action=="rollback"' >/dev/null
[[ "$before" == "$(shasum -a 256 "$fixture/notes"/*.adoc "$fixture/.state/erl/works/book/generations/$generation.json")" ]] || { print -ru2 -- 'FAIL: recovery did not restore bytes'; exit 1; }

"$command" --vault "$fixture" --generation "$generation" --apply --json > "$fixture/apply.json"
jq -e '.changed==true and .data.pair_count==2 and .data.txid' "$fixture/apply.json" >/dev/null
rg -q "^link:$chapter2.adoc\[Следующая глава\]$" "$fixture/notes/$memo2.adoc"
rg -q "^link:$memo2.adoc\[Последнее memo предыдущей главы\]$" "$fixture/notes/$chapter2.adoc"
rg -q "^link:$chapter3.adoc\[Следующая глава\]$" "$fixture/notes/$memo3.adoc"
rg -q "^link:$memo3.adoc\[Последнее memo предыдущей главы\]$" "$fixture/notes/$chapter3.adoc"
! rg -q 'Предыдущее memo' "$fixture/notes/$memo3.adoc"
! rg -q 'Следующая глава' "$fixture/notes/$memo1.adoc"

after_apply="$(shasum -a 256 "$fixture/notes"/*.adoc)"
"$command" --vault "$fixture" --generation "$generation" --apply --json > "$fixture/retry.json"
[[ "$after_apply" == "$(shasum -a 256 "$fixture/notes"/*.adoc)" ]] || { print -ru2 -- 'FAIL: retry changed committed handoff bytes'; exit 1; }
"$checker" --vault "$fixture" --json | jq -e '.status=="ok" and .data.counts.errors==0' >/dev/null

# Missing reciprocal, duplicate, stale owner, wrong adjacency, and terminal links.
cp "$fixture/notes/$chapter2.adoc" "$fixture/chapter2.saved"
awk '$0 !~ /Последнее memo предыдущей главы/' "$fixture/chapter2.saved" > "$fixture/notes/$chapter2.adoc"
set +e; check="$($checker --vault "$fixture" --json)"; rc=$?; set -e
[[ "$rc" == 10 ]] && jq -e 'any(.diagnostics[]; .code=="ERL-CHECK-029" and (.message|contains("reciprocal")))' <<< "$check" >/dev/null
mv "$fixture/chapter2.saved" "$fixture/notes/$chapter2.adoc"

print -r -- "link:$chapter2.adoc[Следующая глава]" >> "$fixture/notes/$memo2.adoc"
set +e; check="$($checker --vault "$fixture" --json)"; rc=$?; set -e
[[ "$rc" == 10 ]] && jq -e 'any(.diagnostics[]; .code=="ERL-CHECK-029" and (.message|contains("exactly one")))' <<< "$check" >/dev/null
sed -i.bak '$d' "$fixture/notes/$memo2.adoc"; rm -f "$fixture/notes/$memo2.adoc.bak"

cp "$fixture/notes/$memo2.adoc" "$fixture/memo2.saved"
sed "s/link:$chapter2.adoc\[Следующая глава\]/link:$chapter3.adoc[Следующая глава]/" "$fixture/memo2.saved" > "$fixture/notes/$memo2.adoc"
set +e; check="$($checker --vault "$fixture" --json)"; rc=$?; set -e
[[ "$rc" == 10 ]] && jq -e 'any(.diagnostics[]; .code=="ERL-CHECK-029" and (.message|contains("adjacent")))' <<< "$check" >/dev/null
mv "$fixture/memo2.saved" "$fixture/notes/$memo2.adoc"

cp "$fixture/notes/$memo1.adoc" "$fixture/memo1.saved"; cp "$fixture/notes/$memo2.adoc" "$fixture/memo2.saved"
awk '$0=="== Reading handoff"{exit}{print}' "$fixture/memo2.saved" > "$fixture/notes/$memo2.adoc"
print -r -- "
== Reading handoff

link:$chapter2.adoc[Следующая глава]" >> "$fixture/notes/$memo1.adoc"
set +e; check="$($checker --vault "$fixture" --json)"; rc=$?; set -e
[[ "$rc" == 10 ]] && jq -e 'any(.diagnostics[]; .code=="ERL-CHECK-029" and (.message|contains("stale non-tail")))' <<< "$check" >/dev/null
mv "$fixture/memo1.saved" "$fixture/notes/$memo1.adoc"; mv "$fixture/memo2.saved" "$fixture/notes/$memo2.adoc"

cp "$fixture/.state/erl/works/book/sources/$source_id.json" "$fixture/source.saved"
jq --arg chapter "$chapter3" '.chapters |= map(select(.chapter_uuid!=$chapter))' "$fixture/source.saved" > "$fixture/.state/erl/works/book/sources/$source_id.json"
set +e; check="$($checker --vault "$fixture" --json)"; rc=$?; set -e
[[ "$rc" == 10 ]] && jq -e 'any(.diagnostics[]; .code=="ERL-CHECK-029" and (.message|contains("Terminal")))' <<< "$check" >/dev/null
mv "$fixture/source.saved" "$fixture/.state/erl/works/book/sources/$source_id.json"

cp "$fixture/.state/erl/works/book/sources/$source_id.json" "$fixture/source.saved"
jq --arg chapter "$chapter2" '.chapters |= map(if .chapter_uuid==$chapter then .source_id="33333333-3333-4333-8333-333333333333" else . end)' "$fixture/source.saved" > "$fixture/.state/erl/works/book/sources/$source_id.json"
set +e; check="$($checker --vault "$fixture" --json)"; rc=$?; set -e
[[ "$rc" == 10 ]] && jq -e 'any(.diagnostics[]; .code=="ERL-CHECK-029" and (.message|contains("SOURCE_ID")))' <<< "$check" >/dev/null
mv "$fixture/source.saved" "$fixture/.state/erl/works/book/sources/$source_id.json"

# User-owned conflicting section is reported and never overwritten by rebuild.
cp "$fixture/notes/$memo1.adoc" "$fixture/memo1.saved"
print -r -- $'\n== Reading handoff\n\nUser prose must stay.' >> "$fixture/notes/$memo1.adoc"
conflict_hash="$(shasum -a 256 "$fixture/notes/$memo1.adoc")"
set +e; "$command" --vault "$fixture" --generation "$generation" --apply --json > "$fixture/conflict.json"; conflict_rc=$?; set -e
[[ "$conflict_rc" == 30 ]] && jq -e '.code=="STATE_CONFLICT" and .changed==false' "$fixture/conflict.json" >/dev/null
[[ "$conflict_hash" == "$(shasum -a 256 "$fixture/notes/$memo1.adoc")" ]] || { print -ru2 -- 'FAIL: rebuild overwrote conflicting user content'; exit 1; }
mv "$fixture/memo1.saved" "$fixture/notes/$memo1.adoc"

print -r -- 'PASS: Chapter chain handoff'
