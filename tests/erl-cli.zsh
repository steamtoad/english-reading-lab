#!/bin/zsh

#------------------------------------------------------------------------------
# erl-cli.zsh
# Тип: ERL integration test
# Назначение: проверить сквозной public CLI workflow, идемпотентность, validation и transactional Reduce
#------------------------------------------------------------------------------

emulate -L zsh
setopt errexit pipe_fail no_unset

repo="${0:A:h:h}"
erl="$repo/.scripts/erl"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/erl-cli-test.XXXXXX")"
trap 'rm -rf -- "$fixture"' EXIT HUP INT TERM
vault="$fixture/vault"
mkdir -p "$vault/notes"
print -r -- 'The forlorn sentinel stood watch.' > "$fixture/book.txt"

while IFS= read -r shell_file; do
  [[ "$shell_file" == *.zsh ]] || {
    print -ru2 -- "FAIL: ERL shell file has no .zsh extension: $shell_file"
    exit 1
  }
done < <(find "$repo/.scripts/erl" "$repo/tests" -type f -exec awk 'FNR==1 && $0 ~ /^#!(\/bin\/zsh|\/usr\/bin\/env zsh)$/{print FILENAME}' {} +)

policy_base='{"schema_version":1,"threshold":["B2","C1","C2"],"lexical_types":["word"]}'
policy_identity="$(print -r -- "$policy_base" | jq -cS . | shasum -a 256 | awk '{print "sha256:" $1}')"
print -r -- "$policy_base" | jq --arg identity "$policy_identity" '.+{identity:$identity}' > "$fixture/policy.json"

assert_envelope() {
  jq -e '.schema_version==1 and (.command|type=="string") and (.status|IN("ok","warning","blocked","error")) and (.code|type=="string") and (.changed|type=="boolean") and (.data|type=="object") and (.diagnostics|type=="array")' "$1" >/dev/null
}

before="$(find "$vault" -type f | wc -l | tr -d ' ')"
"$erl/erl-book-ingest.zsh" --vault "$vault" --source "$fixture/book.txt" --title 'Example Book' --key-topic 'English Reading' --policy-file "$fixture/policy.json" --dry-run --json > "$fixture/book-dry.json"
after="$(find "$vault" -type f | wc -l | tr -d ' ')"
[[ "$before" == "$after" ]] || { print -ru2 -- 'FAIL: book dry-run mutated Vault'; exit 1; }
assert_envelope "$fixture/book-dry.json"

"$erl/erl-book-ingest.zsh" --vault "$vault" --source "$fixture/book.txt" --title 'Example Book' --key-topic 'English Reading' --policy-file "$fixture/policy.json" --apply --json > "$fixture/book.json"
assert_envelope "$fixture/book.json"
generation="$(jq -r .data.generation_uuid "$fixture/book.json")"
work_id="$(jq -r .data.work_id "$fixture/book.json")"
source_state=("$vault/.state/erl/works"/*/sources/*.json)
chapter="$(jq -r '.chapters[0].chapter_uuid' "$source_state[1]")"

"$erl/erl-chapter-export.zsh" --vault "$vault" --generation "$generation" --chapter "$chapter" --json > "$fixture/export.json"
jq -e --arg chapter "$chapter" '.changed==false and .data.chapter_uuid==$chapter and (.data.content|contains("forlorn"))' "$fixture/export.json" >/dev/null

jq -n --arg generation "$generation" --arg chapter "$chapter" --arg policy "$policy_identity" '{
  schema_version:1,generation_uuid:$generation,chapter_uuid:$chapter,policy_identity:$policy,
  candidates:[{ordinal:1,surface_form:"forlorn",lemma:"forlorn",pos:"adjective",lexical_type:"word",candidate_confidence:0.95,
    first_relevant_occurrence:{text:"forlorn sentinel"},context:"The forlorn sentinel stood watch.",
    enrichment:{ipa:"/fəˈlɔːn/",translation_ru:["покинутый"],definition_en:"pitifully sad and abandoned",sense_gloss:"sad and abandoned",
      cefr:{value:"C1",confidence:0.8,provenance:"model-estimate"},register:[],rarity:[],labels:["literary"],semantic_relations:[],collocations:[]}}]
}' > "$fixture/extraction.json"

"$erl/erl-extraction-stage.zsh" --vault "$vault" --input "$fixture/extraction.json" --dry-run --json > "$fixture/stage-dry.json"
[[ "$(find "$vault/.state/erl/staging" -type f 2>/dev/null | wc -l | tr -d ' ')" == 0 ]] || { print -ru2 -- 'FAIL: extraction dry-run wrote staging'; exit 1; }
"$erl/erl-extraction-stage.zsh" --vault "$vault" --input "$fixture/extraction.json" --apply --json > "$fixture/stage.json"
extraction="$(jq -r .data.extraction_id "$fixture/stage.json")"
"$erl/erl-extraction-stage.zsh" --vault "$vault" --input "$fixture/extraction.json" --apply --json > "$fixture/stage-repeat.json"
jq -e --arg extraction "$extraction" '.code=="ALREADY_STAGED" and .changed==false and .data.extraction_id==$extraction' "$fixture/stage-repeat.json" >/dev/null

"$erl/erl-chapter-vocabulary-ingest.zsh" --vault "$vault" --extraction-id "$extraction" --dry-run --json > "$fixture/batch-dry.json"
jq -e '.changed==false and .data.sequence_from==1 and .data.sequence_to==1' "$fixture/batch-dry.json" >/dev/null
"$erl/erl-chapter-vocabulary-ingest.zsh" --vault "$vault" --extraction-id "$extraction" --apply --json > "$fixture/batch.json"
"$erl/erl-chapter-vocabulary-ingest.zsh" --vault "$vault" --extraction-id "$extraction" --apply --json > "$fixture/batch-repeat.json"
jq -e '.code=="ALREADY_INGESTED" and .changed==false' "$fixture/batch-repeat.json" >/dev/null

"$erl/erl-check.zsh" --vault "$vault" --work "$work_id" --json > "$fixture/check.json"
jq -e '.status=="ok" and .data.counts.errors==0' "$fixture/check.json" >/dev/null

# Single-Candidate ingestion is a separate public workflow from Chapter batch ingestion.
jq '.candidates[0] |= (
  .surface_form="bleak" |
  .lemma="bleak" |
  .first_relevant_occurrence.text="bleak sentinel" |
  .context="The bleak sentinel stood watch." |
  .enrichment.translation_ru=["мрачный"] |
  .enrichment.definition_en="cold and miserable" |
  .enrichment.sense_gloss="cold and miserable"
)' "$fixture/extraction.json" > "$fixture/single-extraction.json"
"$erl/erl-extraction-stage.zsh" --vault "$vault" --input "$fixture/single-extraction.json" --apply --json > "$fixture/single-stage.json"
single_extraction="$(jq -r .data.extraction_id "$fixture/single-stage.json")"
"$erl/erl-vocabulary-ingest.zsh" --vault "$vault" --extraction-id "$single_extraction" --candidate 1 --dry-run --json > "$fixture/single-dry.json"
jq -e '.changed==false and .data.role=="vocabulary" and .data.prospective_sequence_ordinal==2' "$fixture/single-dry.json" >/dev/null
"$erl/erl-vocabulary-ingest.zsh" --vault "$vault" --extraction-id "$single_extraction" --candidate 1 --apply --json > "$fixture/single.json"
jq -e '.changed==true and .data.role=="vocabulary" and .data.sequence_ordinal==2' "$fixture/single.json" >/dev/null
"$erl/erl-vocabulary-ingest.zsh" --vault "$vault" --extraction-id "$single_extraction" --candidate 1 --apply --json > "$fixture/single-repeat.json"
jq -e '.code=="ALREADY_INGESTED" and .changed==false and .data.sequence_ordinal==2' "$fixture/single-repeat.json" >/dev/null

# A second Book acquiring the same lexical identity creates an Occurrence and
# forces a cross-work fixed-point closure when the owning generation is reduced.
print -r -- 'The forlorn ranger returned.' > "$fixture/book-two.txt"
"$erl/erl-book-ingest.zsh" --vault "$vault" --source "$fixture/book-two.txt" --title 'Second Book' --key-topic 'Second Reading' --policy-file "$fixture/policy.json" --apply --json > "$fixture/book-two.json"
generation_two="$(jq -r .data.generation_uuid "$fixture/book-two.json")"
source_two=("$vault/.state/erl/works/second-book/sources"/*.json)
chapter_two="$(jq -r '.chapters[0].chapter_uuid' "$source_two[1]")"
jq --arg generation "$generation_two" --arg chapter "$chapter_two" \
  '.generation_uuid=$generation | .chapter_uuid=$chapter | .candidates[0].context="The forlorn ranger returned." | .candidates[0].first_relevant_occurrence.text="forlorn ranger"' \
  "$fixture/extraction.json" > "$fixture/extraction-two.json"
"$erl/erl-extraction-stage.zsh" --vault "$vault" --input "$fixture/extraction-two.json" --apply --json > "$fixture/stage-two.json"
extraction_two="$(jq -r .data.extraction_id "$fixture/stage-two.json")"
"$erl/erl-chapter-vocabulary-ingest.zsh" --vault "$vault" --extraction-id "$extraction_two" --apply --json > "$fixture/batch-two.json"
jq -e '.data.created_occurrences==1 and .data.created_vocabulary==0' "$fixture/batch-two.json" >/dev/null

"$erl/erl-book-reduce.zsh" --vault "$vault" --generation "$generation" --dry-run --json > "$fixture/reduce-closure.json"
jq -e --arg additional "$generation_two" '.status=="warning" and .code=="DEPENDENCIES_REQUIRED" and (.data.additional_generations|index($additional))!=null' "$fixture/reduce-closure.json" >/dev/null
closure_fingerprint="$(jq -r .data.plan_fingerprint "$fixture/reduce-closure.json")"
set +e
"$erl/erl-book-reduce.zsh" --vault "$vault" --generation "$generation" --plan-fingerprint "$closure_fingerprint" --apply --json > "$fixture/reduce-blocked.json"
blocked_rc=$?
set -e
if [[ "$blocked_rc" != 40 ]] || ! jq -e '.status=="blocked" and .code=="DEPENDENCIES_REQUIRED" and .changed==false' "$fixture/reduce-blocked.json" >/dev/null; then
  print -ru2 -- 'FAIL: Reduce accepted an unconfirmed cross-book closure'
  exit 1
fi
"$erl/erl-book-reduce.zsh" --vault "$vault" --generation "$generation" --include-dependencies --dry-run --json > "$fixture/reduce-dry.json"
fingerprint="$(jq -r .data.plan_fingerprint "$fixture/reduce-dry.json")"
[[ "$fingerprint" != "$closure_fingerprint" ]] || { print -ru2 -- 'FAIL: dependency consent did not change exact-plan fingerprint'; exit 1; }
set +e
"$erl/erl-book-reduce.zsh" --vault "$vault" --generation "$generation" --include-dependencies --plan-fingerprint "$closure_fingerprint" --apply --json > "$fixture/reduce-stale.json"
stale_rc=$?
set -e
if [[ "$stale_rc" != 30 ]] || ! jq -e '.status=="error" and .code=="STATE_CONFLICT" and .changed==false' "$fixture/reduce-stale.json" >/dev/null; then
  print -ru2 -- 'FAIL: Reduce accepted a stale plan fingerprint'
  exit 1
fi
"$erl/erl-book-reduce.zsh" --vault "$vault" --generation "$generation" --include-dependencies --plan-fingerprint "$fingerprint" --apply --json > "$fixture/reduce.json"
jq -e '.changed==true and .data.receipt_status=="committed"' "$fixture/reduce.json" >/dev/null
[[ ! -f "$vault/.state/erl/works/example-book/generations/$generation.json" ]] || { print -ru2 -- 'FAIL: Reduce retained generation state'; exit 1; }
[[ ! -f "$vault/.state/erl/works/second-book/generations/$generation_two.json" ]] || { print -ru2 -- 'FAIL: Reduce retained dependency generation state'; exit 1; }
grep -q '^:deprecated:$' "$vault/notes/$generation.adoc" || { print -ru2 -- 'FAIL: Reduce did not deprecate Book Topic'; exit 1; }
grep -q '^:deprecated:$' "$vault/notes/$chapter.adoc" && { print -ru2 -- 'FAIL: Reduce deprecated Chapter Note'; exit 1; }
grep -q '^:deprecated:$' "$vault/notes/$chapter_two.adoc" && { print -ru2 -- 'FAIL: Reduce deprecated dependency Chapter Note'; exit 1; }
"$erl/erl-check.zsh" --vault "$vault" --json | jq -e '.status=="ok" and .data.counts.errors==0' >/dev/null

# Classic reconciliation is tested separately from ERL Book Reduce, including
# the rule that successor adoption is never implicit.
print -r -- 'A quiet chapter.' > "$fixture/book-three.txt"
"$erl/erl-book-ingest.zsh" --vault "$vault" --source "$fixture/book-three.txt" --title 'Classic Book' --key-topic 'Classic Reading' --policy-file "$fixture/policy.json" --apply --json > "$fixture/book-three.json"
generation_three="$(jq -r .data.generation_uuid "$fixture/book-three.json")"
work_three="$(jq -r .data.work_id "$fixture/book-three.json")"
successor="$(uuidgen | tr '[:upper:]' '[:lower:]')"
cp "$vault/notes/$generation_three.adoc" "$vault/notes/$successor.adoc"
sed -i.bak "s/$generation_three/$successor/g" "$vault/notes/$successor.adoc"
rm -f -- "$vault/notes/$successor.adoc.bak"
print -r -- "\nlink:$generation_three.adoc[Previous Classic Topic]" >> "$vault/notes/$successor.adoc"
sed -i.bak '/^:docfilename:/a\
:deprecated:' "$vault/notes/$generation_three.adoc"
rm -f -- "$vault/notes/$generation_three.adoc.bak"
"$erl/erl-classic-reduce-reconcile.zsh" --vault "$vault" --generation "$generation_three" --dry-run --json > "$fixture/reconcile-close.json"
jq -e --arg successor "$successor" '.changed==false and .data.adopt_successor==null and (.data.detected_successors|index($successor))!=null' "$fixture/reconcile-close.json" >/dev/null
"$erl/erl-classic-reduce-reconcile.zsh" --vault "$vault" --generation "$generation_three" --adopt-successor "$successor" --dry-run --json > "$fixture/reconcile-adopt-dry.json"
jq -e --arg successor "$successor" '.changed==false and .data.adopt_successor==$successor' "$fixture/reconcile-adopt-dry.json" >/dev/null
"$erl/erl-classic-reduce-reconcile.zsh" --vault "$vault" --generation "$generation_three" --adopt-successor "$successor" --apply --json > "$fixture/reconcile.json"
jq -e --arg successor "$successor" '.changed==true and .data.status=="GENERATION_CLOSED_EXTERNALLY" and .data.adopted_successor==$successor' "$fixture/reconcile.json" >/dev/null
work_three_file="$vault/.state/erl/works/classic-book/work.json"
jq -e --arg successor "$successor" '.active_generation_uuid==$successor and (.generation_uuids|index($successor))!=null' "$work_three_file" >/dev/null
"$erl/erl-check.zsh" --vault "$vault" --work "$work_three" --json | jq -e '.status=="ok" and .data.counts.errors==0' >/dev/null

print -r -- 'PASS: ERL public CLI workflow'
