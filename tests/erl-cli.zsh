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

"$erl/erl-book-reduce.zsh" --vault "$vault" --generation "$generation" --dry-run --json > "$fixture/reduce-dry.json"
fingerprint="$(jq -r .data.plan_fingerprint "$fixture/reduce-dry.json")"
"$erl/erl-book-reduce.zsh" --vault "$vault" --generation "$generation" --plan-fingerprint "$fingerprint" --apply --json > "$fixture/reduce.json"
jq -e '.changed==true and .data.receipt_status=="committed"' "$fixture/reduce.json" >/dev/null
[[ ! -f "$vault/.state/erl/works/example-book/generations/$generation.json" ]] || { print -ru2 -- 'FAIL: Reduce retained generation state'; exit 1; }
grep -q '^:deprecated:$' "$vault/notes/$generation.adoc" || { print -ru2 -- 'FAIL: Reduce did not deprecate Book Topic'; exit 1; }
grep -q '^:deprecated:$' "$vault/notes/$chapter.adoc" && { print -ru2 -- 'FAIL: Reduce deprecated Chapter Note'; exit 1; }
"$erl/erl-check.zsh" --vault "$vault" --json | jq -e '.status=="ok" and .data.counts.errors==0' >/dev/null

print -r -- 'PASS: ERL public CLI workflow'
