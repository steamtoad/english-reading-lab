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
export ERL_HOST_HOME="$repo/fixtures/host-contract"
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

# Production runtime must fail explicitly when the target host contract is
# unavailable; repository-local test doubles are never an implicit fallback.
missing_host_vault="$fixture/missing-host-vault"
mkdir -p "$missing_host_vault/notes"
set +e
env -u ERL_HOST_HOME "$erl/erl-book-ingest.zsh" --vault "$missing_host_vault" --source "$fixture/book.txt" --title 'Missing Host' --key-topic 'Missing Host' --policy-file "$fixture/policy.json" --dry-run --json > "$fixture/missing-host.json"
missing_host_rc=$?
set -e
if [[ "$missing_host_rc" != 50 ]] || ! jq -e '.status=="error" and .code=="HOST_CONTRACT_UNAVAILABLE" and .changed==false' "$fixture/missing-host.json" >/dev/null; then
  print -ru2 -- 'FAIL: ERL silently accepted a missing host contract'
  exit 1
fi

before="$(find "$vault" -type f | wc -l | tr -d ' ')"
"$erl/erl-book-ingest.zsh" --vault "$vault" --source "$fixture/book.txt" --title 'Example Book' --policy-file "$fixture/policy.json" --dry-run --json > "$fixture/book-dry.json"
after="$(find "$vault" -type f | wc -l | tr -d ' ')"
[[ "$before" == "$after" ]] || { print -ru2 -- 'FAIL: book dry-run mutated Vault'; exit 1; }
assert_envelope "$fixture/book-dry.json"

"$erl/erl-book-ingest.zsh" --vault "$vault" --source "$fixture/book.txt" --title 'Example Book' --policy-file "$fixture/policy.json" --apply --json > "$fixture/book.json"
assert_envelope "$fixture/book.json"
generation="$(jq -r .data.generation_uuid "$fixture/book.json")"
work_id="$(jq -r .data.work_id "$fixture/book.json")"
source_state=("$vault/.state/erl/works"/*/sources/*.json)
chapter="$(jq -r '.chapters[0].chapter_uuid' "$source_state[1]")"
source_id="$(jq -r .source_id "$source_state[1]")"
source_fingerprint="$(jq -r .source_fingerprint "$source_state[1]")"

# Legacy Chapter records are migrated through an explicit atomic operation.
cp "$source_state[1]" "$fixture/source-current.json"
jq 'del(.chapters[].source_id)' "$fixture/source-current.json" > "$source_state[1]"
"$erl/erl-state-migrate.zsh" --vault "$vault" --work-id "$work_id" --dry-run --json > "$fixture/migrate-dry.json"
jq -e '.changed==false and .data.migration=="chapter-source-id-v1" and .data.chapter_records==1' "$fixture/migrate-dry.json" >/dev/null
"$erl/erl-state-migrate.zsh" --vault "$vault" --work-id "$work_id" --apply --json > "$fixture/migrate.json"
jq -e '.changed==true and .data.chapter_records==1' "$fixture/migrate.json" >/dev/null
jq -e --arg source "$source_id" 'all(.chapters[]; .source_id==$source)' "$source_state[1]" >/dev/null

"$erl/erl-chapter-export.zsh" --vault "$vault" --generation "$generation" --chapter "$chapter" --json > "$fixture/export.json"
jq -e --arg chapter "$chapter" '.changed==false and .data.chapter_uuid==$chapter and (.data.content|contains("forlorn"))' "$fixture/export.json" >/dev/null

jq -n --arg generation "$generation" --arg chapter "$chapter" --arg policy "$policy_identity" --arg source_id "$source_id" --arg source_fingerprint "$source_fingerprint" '{
  schema_version:1,generation_uuid:$generation,chapter_uuid:$chapter,policy_identity:$policy,
  source_identity:{source_id:$source_id,source_fingerprint:$source_fingerprint},
  candidates:[{ordinal:1,surface_form:"forlorn",lemma:"forlorn",pos:"adjective",lexical_type:"word",candidate_confidence:0.95,
    first_relevant_occurrence:{text:"forlorn sentinel"},context:"The forlorn sentinel stood watch.",
    enrichment:{ipa:"/fəˈlɔːn/",translation_ru:["покинутый"],definition_en:"pitifully sad and abandoned",sense_gloss:"sad and abandoned",
      cefr:{value:"C1",confidence:0.8,provenance:"model-estimate"},register:[],rarity:"uncommon",labels:["literary"],semantic_relations:[],collocations:[]}}]
}' > "$fixture/extraction.json"

jq 'del(.source_identity)' "$fixture/extraction.json" > "$fixture/extraction-missing-source.json"
set +e
"$erl/erl-extraction-stage.zsh" --vault "$vault" --input "$fixture/extraction-missing-source.json" --dry-run --json > "$fixture/stage-missing-source.json"
missing_source_rc=$?
set -e
if [[ "$missing_source_rc" != 10 ]] || ! jq -e '.status=="error" and .code=="VALIDATION_FAILED" and .changed==false' "$fixture/stage-missing-source.json" >/dev/null; then
  print -ru2 -- 'FAIL: extraction accepted missing source identity'
  exit 1
fi

jq '.source_identity.source_fingerprint="sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"' "$fixture/extraction.json" > "$fixture/extraction-wrong-source.json"
set +e
"$erl/erl-extraction-stage.zsh" --vault "$vault" --input "$fixture/extraction-wrong-source.json" --dry-run --json > "$fixture/stage-wrong-source.json"
wrong_source_rc=$?
set -e
if [[ "$wrong_source_rc" != 30 ]] || ! jq -e '.status=="error" and .code=="STATE_CONFLICT" and .changed==false' "$fixture/stage-wrong-source.json" >/dev/null; then
  print -ru2 -- 'FAIL: extraction accepted mismatched source identity'
  exit 1
fi

"$erl/erl-extraction-stage.zsh" --vault "$vault" --input "$fixture/extraction.json" --dry-run --json > "$fixture/stage-dry.json"
[[ "$(find "$vault/.state/erl/staging" -type f 2>/dev/null | wc -l | tr -d ' ')" == 0 ]] || { print -ru2 -- 'FAIL: extraction dry-run wrote staging'; exit 1; }
jq '.candidates[0].enrichment.ipa="" | .candidates[0].lexical_type="idiom"' "$fixture/extraction.json" > "$fixture/extraction-empty-ipa.json"
"$erl/erl-extraction-stage.zsh" --vault "$vault" --input "$fixture/extraction-empty-ipa.json" --dry-run --json > "$fixture/stage-empty-ipa.json"
jq -e '.status=="ok" and .code=="OK" and .changed==false' "$fixture/stage-empty-ipa.json" >/dev/null || {
  print -ru2 -- 'FAIL: extraction rejected schema-valid empty IPA'
  exit 1
}
jq '.candidates[0].enrichment.rarity=[]' "$fixture/extraction.json" > "$fixture/extraction-invalid-rarity.json"
set +e
"$erl/erl-extraction-stage.zsh" --vault "$vault" --input "$fixture/extraction-invalid-rarity.json" --dry-run --json > "$fixture/stage-invalid-rarity.json"
invalid_rarity_rc=$?
set -e
if [[ "$invalid_rarity_rc" != 10 ]] || ! jq -e '.status=="error" and .code=="VALIDATION_FAILED" and .changed==false' "$fixture/stage-invalid-rarity.json" >/dev/null; then
  print -ru2 -- 'FAIL: extraction accepted array-valued Candidate rarity'
  exit 1
fi
"$erl/erl-extraction-stage.zsh" --vault "$vault" --input "$fixture/extraction.json" --apply --json > "$fixture/stage.json"
extraction="$(jq -r .data.extraction_id "$fixture/stage.json")"
jq -e --arg source_id "$source_id" --arg source_fingerprint "$source_fingerprint" \
  '.source_identity.source_id==$source_id and .source_identity.source_fingerprint==$source_fingerprint' \
  "$vault/.state/erl/staging/$extraction.json" >/dev/null || {
  print -ru2 -- 'FAIL: staged extraction did not retain source identity'
  exit 1
}
"$erl/erl-extraction-stage.zsh" --vault "$vault" --input "$fixture/extraction.json" --apply --json > "$fixture/stage-repeat.json"
jq -e --arg extraction "$extraction" '.code=="ALREADY_STAGED" and .changed==false and .data.extraction_id==$extraction' "$fixture/stage-repeat.json" >/dev/null

"$erl/erl-chapter-vocabulary-ingest.zsh" --vault "$vault" --extraction-id "$extraction" --dry-run --json > "$fixture/batch-dry.json"
jq -e '.changed==false and .data.sequence_from==1 and .data.sequence_to==1' "$fixture/batch-dry.json" >/dev/null
"$erl/erl-chapter-vocabulary-ingest.zsh" --vault "$vault" --extraction-id "$extraction" --apply --json > "$fixture/batch.json"
"$erl/erl-chapter-vocabulary-ingest.zsh" --vault "$vault" --extraction-id "$extraction" --apply --json > "$fixture/batch-repeat.json"
jq -e '.code=="ALREADY_INGESTED" and .changed==false' "$fixture/batch-repeat.json" >/dev/null

# Interrupted ingestion with a created-but-unrecorded document can be
# deterministically rolled back without touching changed state.
recovery_txid="$(uuidgen | tr '[:upper:]' '[:lower:]')"
recovery_dir="$vault/.state/erl/transactions/$recovery_txid"
recovery_doc="$(uuidgen | tr '[:upper:]' '[:lower:]')"
mkdir -p "$recovery_dir/backups"
cp "$vault/.state/erl/works/example-book/generations/$generation.json" "$recovery_dir/backups/generation.json"
print -r -- '= interrupted memo' > "$vault/notes/$recovery_doc.adoc"
recovery_generation_hash="$(shasum -a 256 "$vault/.state/erl/works/example-book/generations/$generation.json" | awk '{print "sha256:" $1}')"
recovery_document_hash="$(shasum -a 256 "$vault/notes/$recovery_doc.adoc" | awk '{print "sha256:" $1}')"
jq -n --arg txid "$recovery_txid" --arg generation "$generation" --arg generation_path "$vault/.state/erl/works/example-book/generations/$generation.json" --arg generation_hash "$recovery_generation_hash" --arg extraction "$(uuidgen | tr '[:upper:]' '[:lower:]')" --arg document_uuid "$recovery_doc" --arg document_path "$vault/notes/$recovery_doc.adoc" --arg document_hash "$recovery_document_hash" '{schema_version:1,txid:$txid,operation:"erl-vocabulary-ingest",phase:"document_created",generation_uuid:$generation,generation_path:$generation_path,generation_pre_hash:$generation_hash,extraction_id:$extraction,candidate_ordinal:1,document_uuid:$document_uuid,document_path:$document_path,document_hash:$document_hash}' > "$recovery_dir/transaction.json"
"$erl/erl-transaction-recover.zsh" --vault "$vault" --txid "$recovery_txid" --dry-run --json | jq -e '.changed==false and .data.recovery_action=="rollback"' >/dev/null
"$erl/erl-transaction-recover.zsh" --vault "$vault" --txid "$recovery_txid" --apply --json | jq -e '.changed==true and .data.recovery_action=="rollback"' >/dev/null
[[ ! -e "$vault/notes/$recovery_doc.adoc" ]] || { print -ru2 -- 'FAIL: transaction recovery retained orphan document'; exit 1; }
jq -e '.phase=="rolled_back"' "$recovery_dir/transaction.json" >/dev/null

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
"$erl/erl-book-ingest.zsh" --vault "$vault" --source "$fixture/book-two.txt" --title 'Second Book' --policy-file "$fixture/policy.json" --apply --json > "$fixture/book-two.json"
generation_two="$(jq -r .data.generation_uuid "$fixture/book-two.json")"
source_two=("$vault/.state/erl/works/second-book/sources"/*.json)
chapter_two="$(jq -r '.chapters[0].chapter_uuid' "$source_two[1]")"
source_id_two="$(jq -r .source_id "$source_two[1]")"
source_fingerprint_two="$(jq -r .source_fingerprint "$source_two[1]")"
jq --arg generation "$generation_two" --arg chapter "$chapter_two" --arg source_id "$source_id_two" --arg source_fingerprint "$source_fingerprint_two" \
  '.generation_uuid=$generation | .chapter_uuid=$chapter | .source_identity={source_id:$source_id,source_fingerprint:$source_fingerprint} | .candidates[0].context="The forlorn ranger returned." | .candidates[0].first_relevant_occurrence.text="forlorn ranger"' \
  "$fixture/extraction.json" > "$fixture/extraction-two.json"
"$erl/erl-extraction-stage.zsh" --vault "$vault" --input "$fixture/extraction-two.json" --apply --json > "$fixture/stage-two.json"
extraction_two="$(jq -r .data.extraction_id "$fixture/stage-two.json")"
"$erl/erl-chapter-vocabulary-ingest.zsh" --vault "$vault" --extraction-id "$extraction_two" --apply --json > "$fixture/batch-two.json"
jq -e '.data.created_occurrences==1 and .data.created_vocabulary==0' "$fixture/batch-two.json" >/dev/null

# Generic active inbound links are classified as soft, and dirty mutation
# targets are rejected by the applicable Git worktree policy.
soft_source="$(uuidgen | tr '[:upper:]' '[:lower:]')"
print -r -- "= Reader note
:date: 2026-08-30
:keywords: memo
:type: memo
:author: test
:description: Reader note
:doclink: link:$soft_source.adoc[Reader note]
:docfilename: $soft_source.adoc

link:$generation.adoc[Book]
" > "$vault/notes/$soft_source.adoc"
git -C "$vault" init -q
git -C "$vault" config user.name 'ERL Test'
git -C "$vault" config user.email 'erl-test@example.invalid'
git -C "$vault" add .
git -C "$vault" commit -qm 'fixture baseline'
cp "$vault/notes/$generation.adoc" "$fixture/generation-before-dirty.adoc"
print -r -- '\nlocal edit' >> "$vault/notes/$generation.adoc"
"$erl/erl-book-reduce.zsh" --vault "$vault" --generation "$generation" --dry-run --json > "$fixture/reduce-dirty.json"
jq -e '.status=="warning" and .code=="WORKTREE_DIRTY" and .data.git_preflight.clean==false' "$fixture/reduce-dirty.json" >/dev/null
cp "$fixture/generation-before-dirty.adoc" "$vault/notes/$generation.adoc"

"$erl/erl-book-reduce.zsh" --vault "$vault" --generation "$generation" --dry-run --json > "$fixture/reduce-closure.json"
jq -e --arg additional "$generation_two" --arg source "$soft_source" --arg target "$generation" '.status=="warning" and .code=="DEPENDENCIES_REQUIRED" and (.data.additional_generations|index($additional))!=null and any(.data.soft_references[]; .source_uuid==$source and .target_uuid==$target and .classification=="soft")' "$fixture/reduce-closure.json" >/dev/null
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

# A closed work may create a new semantic generation for the same source while
# reusing SOURCE_ID and durable Chapter UUIDs.
chapter_before="$(jq -r '.chapters[0].chapter_uuid' "$source_state[1]")"
"$erl/erl-book-ingest.zsh" --vault "$vault" --source "$fixture/book.txt" --work-id "$work_id" --policy-file "$fixture/policy.json" --dry-run --json > "$fixture/book-regeneration-dry.json"
jq -e --arg source_id "$source_id" '.changed==false and .data.reuses_source==true and .data.source_id==$source_id and .data.will_generate_source_id==false' "$fixture/book-regeneration-dry.json" >/dev/null
"$erl/erl-book-ingest.zsh" --vault "$vault" --source "$fixture/book.txt" --work-id "$work_id" --policy-file "$fixture/policy.json" --apply --json > "$fixture/book-regeneration.json"
generation_regenerated="$(jq -r .data.generation_uuid "$fixture/book-regeneration.json")"
jq -e --arg source_id "$source_id" '.changed==true and .data.reused_source==true and .data.source_id==$source_id and .data.created.notes==0' "$fixture/book-regeneration.json" >/dev/null
[[ "$(jq -r '.chapters[0].chapter_uuid' "$source_state[1]")" == "$chapter_before" ]] || { print -ru2 -- 'FAIL: same-source generation changed durable Chapter UUID'; exit 1; }
[[ "$generation_regenerated" != "$generation" ]] || { print -ru2 -- 'FAIL: semantic regeneration reused Book Topic UUID'; exit 1; }
"$erl/erl-check.zsh" --vault "$vault" --work "$work_id" --json | jq -e '.status=="ok" and .data.counts.errors==0' >/dev/null

# Work slug migration changes only the path locator, under an explicit lock.
"$erl/erl-work-rename.zsh" --vault "$vault" --work-id "$work_id" --new-slug 'example-book-renamed' --dry-run --json > "$fixture/rename-dry.json"
jq -e '.changed==false and .data.old_slug=="example-book" and .data.new_slug=="example-book-renamed"' "$fixture/rename-dry.json" >/dev/null
"$erl/erl-work-rename.zsh" --vault "$vault" --work-id "$work_id" --new-slug 'example-book-renamed' --apply --json > "$fixture/rename.json"
jq -e '.changed==true and .data.work_id!=""' "$fixture/rename.json" >/dev/null
[[ ! -e "$vault/.state/erl/works/example-book" && -f "$vault/.state/erl/works/example-book-renamed/work.json" ]] || { print -ru2 -- 'FAIL: work slug directory migration is incomplete'; exit 1; }
jq -e --arg work_id "$work_id" '.work_id==$work_id and .work_slug=="example-book-renamed"' "$vault/.state/erl/works/example-book-renamed/work.json" >/dev/null
"$erl/erl-check.zsh" --vault "$vault" --work "$work_id" --json | jq -e '.status=="ok" and .data.counts.errors==0' >/dev/null

# Classic reconciliation is tested separately from ERL Book Reduce, including
# the rule that successor adoption is never implicit.
print -r -- 'A quiet chapter.' > "$fixture/book-three.txt"
"$erl/erl-book-ingest.zsh" --vault "$vault" --source "$fixture/book-three.txt" --title 'Classic Book' --policy-file "$fixture/policy.json" --apply --json > "$fixture/book-three.json"
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
