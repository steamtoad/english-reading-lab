#!/bin/zsh

#------------------------------------------------------------------------------
# erl-vocabulary-ingest.zsh
# Тип: ERL CLI
# Назначение: ingestировать один Candidate как Vocabulary или Occurrence с обновлением sequence и receipts
#------------------------------------------------------------------------------

emulate -L zsh
setopt pipe_fail no_unset
script_dir="${0:A:h}"
source "$script_dir/lib/common.zsh"
ERL_COMMAND="erl-vocabulary-ingest"; ERL_JSON_MODE=0
vault_arg="" extraction_id="" candidate_ordinal="" mode="" lock=""
cleanup_vocabulary() { erl_lock_release "$lock"; }
trap cleanup_vocabulary EXIT HUP INT TERM
while (( $# )); do
  case "$1" in
    --vault) (( $#>=2 )) || erl_usage_error "--vault requires DIR"; vault_arg="$2"; shift 2 ;;
    --extraction-id) (( $#>=2 )) || erl_usage_error "--extraction-id requires UUID"; extraction_id="$2"; shift 2 ;;
    --candidate) (( $#>=2 )) || erl_usage_error "--candidate requires INTEGER"; candidate_ordinal="$2"; shift 2 ;;
    --dry-run|--apply) [[ -z "$mode" ]] || erl_usage_error "Select exactly one mode"; mode="${1#--}"; shift ;;
    --json) ERL_JSON_MODE=1; shift ;;
    --help) print -- "Usage: $ERL_COMMAND --vault DIR --extraction-id UUID --candidate INTEGER (--dry-run|--apply) [--json]"; exit 0 ;;
    *) erl_usage_error "Unknown argument: $1" ;;
  esac
done
erl_require_command jq
[[ -n "$mode" ]] || erl_usage_error "Select exactly one of --dry-run or --apply"
[[ "$extraction_id" =~ '^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' ]] || erl_fail 10 error INVALID_INPUT "EXTRACTION_ID must be lowercase UUID v4"
[[ "$candidate_ordinal" == <-> && "$candidate_ordinal" -ge 1 ]] || erl_fail 10 error INVALID_INPUT "Candidate ordinal must be a positive integer"
vault="$(erl_resolve_vault "$vault_arg")"
staging_file="$(erl_extraction_file "$vault" "$extraction_id" 2>/dev/null)" || erl_fail 20 error NOT_FOUND "Staged extraction not found: $extraction_id"
candidate="$(jq -c --argjson ordinal "$candidate_ordinal" '.candidates[]? | select(.ordinal==$ordinal)' "$staging_file")"
[[ -n "$candidate" ]] || erl_fail 20 error NOT_FOUND "Candidate ordinal not found: $candidate_ordinal"
generation="$(jq -r .generation_uuid "$staging_file")"; chapter="$(jq -r .chapter_uuid "$staging_file")"
generation_file="$(erl_find_generation_file "$vault" "$generation" 2>/dev/null)" || erl_fail 20 error NOT_FOUND "Generation not found: $generation"
[[ "$(jq -r '.status // "active"' "$generation_file")" == active ]] || erl_fail 40 blocked GENERATION_CLOSED_EXTERNALLY "Generation is not active"
current_source_order="$(erl_chapter_source_order "$vault" "$generation_file" "$chapter" 2>/dev/null)" || erl_fail 30 error STATE_CONFLICT "Chapter is not registered in generation source"
max_source_order=0
for prior_chapter in "${(@f)$(jq -r '.sequence[]?.chapter_uuid // empty' "$generation_file" | sort -u)}"; do
  [[ -n "$prior_chapter" ]] || continue
  prior_source_order="$(erl_chapter_source_order "$vault" "$generation_file" "$prior_chapter" 2>/dev/null)" || erl_fail 30 error STATE_CONFLICT "Sequence Chapter is absent from generation source: $prior_chapter"
  (( prior_source_order > max_source_order )) && max_source_order="$prior_source_order"
done
(( current_source_order >= max_source_order )) || erl_fail 30 error STATE_CONFLICT "Chapter ingestion would violate source-order sequence"
completed="$(jq -c --arg extraction "$extraction_id" --argjson ordinal "$candidate_ordinal" '[.ingestion_receipts[]? | select(.extraction_id==$extraction) | .candidates[]? | select(.ordinal==$ordinal and .status=="completed")][0] // empty' "$generation_file")"
if [[ -n "$completed" ]]; then
  data="$(jq -cn --arg extraction_id "$extraction_id" --argjson ordinal "$candidate_ordinal" --argjson completed "$completed" '{extraction_id:$extraction_id,candidate_ordinal:$ordinal,role:$completed.role,document_uuid:$completed.document_uuid,vocabulary_uuid:($completed.vocabulary_uuid//null),sequence_ordinal:$completed.sequence_ordinal}')"
  erl_emit ok ALREADY_INGESTED false "$data" '[]' 0
fi
lemma="$(jq -r .lemma <<< "$candidate")"; pos="$(jq -r .pos <<< "$candidate")"; lexical_type="$(jq -r .lexical_type <<< "$candidate")"
identity="$(erl_normalize_identity "$lemma" "$pos" "$lexical_type")"; identity_key="$(erl_identity_key "$identity")"
existing_vocabulary=""
for candidate_generation in "$vault/.state/erl/works"/*/generations/*.json(N); do
  while IFS= read -r vocabulary_uuid; do
    [[ -n "$vocabulary_uuid" ]] || continue
    vocabulary_file="$(erl_doc_path "$vault" "$vocabulary_uuid" 2>/dev/null)" || continue
    erl_doc_deprecated "$vocabulary_file" || { existing_vocabulary="$vocabulary_uuid"; break 2; }
  done < <(jq -r --arg key "$identity_key" '.sequence[]? | select(.role=="vocabulary" and .lexical_identity_key==$key) | .document_uuid' "$candidate_generation" 2>/dev/null)
done
if [[ -n "$existing_vocabulary" ]]; then role=occurrence; else role=vocabulary; fi
last_ordinal="$(jq '[.sequence[]?.ordinal] | max // 0' "$generation_file")"; sequence_ordinal=$((last_ordinal + 1))
plan="$(jq -cn --arg extraction_id "$extraction_id" --argjson candidate "$candidate_ordinal" --arg role "$role" --argjson identity "$identity" --arg existing "$existing_vocabulary" --argjson sequence_ordinal "$sequence_ordinal" '{extraction_id:$extraction_id,candidate_ordinal:$candidate,role:$role,lexical_identity:$identity,existing_vocabulary_uuid:(if $existing=="" then null else $existing end),prospective_sequence_ordinal:$sequence_ordinal}')"
[[ "$mode" == apply ]] || erl_emit ok OK false "$plan" '[]' 0

lock="$vault/.state/erl/locks/ingest-${generation}-${extraction_id}.lock"; erl_lock_acquire "$lock"
# Recheck idempotency after obtaining the lock.
generation_file="$(erl_find_generation_file "$vault" "$generation")"
if jq -e --arg extraction "$extraction_id" --argjson ordinal "$candidate_ordinal" 'any(.ingestion_receipts[]?; .extraction_id==$extraction and any(.candidates[]?; .ordinal==$ordinal and .status=="completed"))' "$generation_file" >/dev/null; then
  erl_emit ok ALREADY_INGESTED false "$plan" '[]' 0
fi
txid="$(erl_uuid_v4)" || erl_fail 50 error IO_ERROR "Cannot generate TXID"
tx_dir="$vault/.state/erl/transactions/$txid"; mkdir -p -- "$tx_dir/backups" || erl_fail 50 error IO_ERROR "Cannot create transaction journal"
cp -- "$generation_file" "$tx_dir/backups/generation.json"
jq -cn --arg txid "$txid" --arg generation "$generation" --arg extraction "$extraction_id" --argjson candidate "$candidate_ordinal" --arg generation_path "$generation_file" --arg generation_pre_hash "$(erl_sha256_file "$generation_file")" '{schema_version:1,txid:$txid,operation:"erl-vocabulary-ingest",phase:"applying",generation_uuid:$generation,generation_path:$generation_path,generation_pre_hash:$generation_pre_hash,extraction_id:$extraction,candidate_ordinal:$candidate}' | erl_atomic_write "$tx_dir/transaction.json" || erl_fail 50 error IO_ERROR "Cannot write transaction journal"

surface="$(jq -r .surface_form <<< "$candidate")"; context="$(erl_json_escape_asciidoc "$(jq -r .context <<< "$candidate")")"
memo_fname="$(ZK_HOME="$vault" "$script_dir/../objects/memo-create.zsh" "$surface" memo "$surface")" || erl_fail 50 error IO_ERROR "Canonical Memo constructor failed"
document_uuid="${memo_fname%.adoc}"; document_file="$vault/notes/$memo_fname"
if [[ "$role" == vocabulary ]]; then
  translations="$(jq -r '.enrichment.translation_ru|join(", ")' <<< "$candidate")"
  definition="$(erl_json_escape_asciidoc "$(jq -r .enrichment.definition_en <<< "$candidate")")"
  ipa="$(erl_json_escape_asciidoc "$(jq -r .enrichment.ipa <<< "$candidate")")"
  cefr="$(jq -r .enrichment.cefr.value <<< "$candidate")"
  {
    print -r -- "== Lexical identity"; print -r -- ""; print -r -- "Lemma:: $lemma"; print -r -- "POS:: $pos"; print -r -- "Lexical type:: $lexical_type"
    print -r -- ""; print -r -- "== Meaning"; print -r -- ""; print -r -- "Definition:: $definition"; print -r -- "Translation:: $translations"; print -r -- "IPA:: $ipa"; print -r -- "CEFR:: $cefr"
    print -r -- ""; print -r -- "== Context"; print -r -- ""; print -r -- "$context"
  } >> "$document_file"
  vocabulary_uuid=""
else
  vocabulary_uuid="$existing_vocabulary"
  vocabulary_file="$(erl_doc_path "$vault" "$vocabulary_uuid")"
  vocabulary_description="$(erl_doc_attr "$vocabulary_file" description)"; [[ -n "$vocabulary_description" ]] || vocabulary_description="$lemma"
  {
    print -r -- "== Vocabulary"; print -r -- ""; print -r -- "link:$vocabulary_uuid.adoc[$vocabulary_description]"
    print -r -- ""; print -r -- "== Context"; print -r -- ""; print -r -- "$context"
  } >> "$document_file"
fi

jq --arg document_uuid "$document_uuid" --arg document_path "$document_file" --arg document_hash "$(erl_sha256_file "$document_file")" '.phase="document_created"|.document_uuid=$document_uuid|.document_path=$document_path|.document_hash=$document_hash' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json" || {
  rm -f -- "$document_file"
  jq '.phase="rolled_back"' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json" || true
  erl_fail 60 error TRANSACTION_FAILED "Cannot record created document recovery metadata"
}

total_candidates="$(jq '.candidates|length' "$staging_file")"
receipt_candidate="$(jq -cn --argjson ordinal "$candidate_ordinal" --arg role "$role" --arg document_uuid "$document_uuid" --arg vocabulary_uuid "$vocabulary_uuid" --argjson sequence_ordinal "$sequence_ordinal" '{ordinal:$ordinal,status:"completed",role:$role,document_uuid:$document_uuid,sequence_ordinal:$sequence_ordinal} + if $vocabulary_uuid=="" then {} else {vocabulary_uuid:$vocabulary_uuid} end')"
entry="$(jq -cn --argjson ordinal "$sequence_ordinal" --arg chapter_uuid "$chapter" --arg role "$role" --arg document_uuid "$document_uuid" --arg extraction_id "$extraction_id" --argjson candidate_ordinal "$candidate_ordinal" --arg identity_key "$identity_key" --arg vocabulary_uuid "$vocabulary_uuid" '{ordinal:$ordinal,chapter_uuid:$chapter_uuid,role:$role,document_uuid:$document_uuid,extraction_id:$extraction_id,candidate_ordinal:$candidate_ordinal,lexical_identity_key:$identity_key} + if $vocabulary_uuid=="" then {} else {vocabulary_uuid:$vocabulary_uuid} end')"
jq --argjson entry "$entry" --arg document_uuid "$document_uuid" --arg role "$role" --arg extraction "$extraction_id" --argjson receipt_candidate "$receipt_candidate" --argjson total "$total_candidates" '
  .sequence=((.sequence//[])+[$entry]) |
  .members=((.members//[])+[{document_uuid:$document_uuid,role:$role,reducible:true}]|unique_by(.document_uuid)) |
  (.ingestion_receipts//[]) as $all |
  ($all|map(select(.extraction_id==$extraction))[0] // {extraction_id:$extraction,status:"applying",candidates:[]}) as $old |
  ($old | .candidates=((.candidates//[])+[$receipt_candidate]|unique_by(.ordinal)) |
    .status=(if ([.candidates[]|select(.status=="completed")]|length)>=$total then "completed" else "applying" end)) as $new |
  .ingestion_receipts=(($all|map(select(.extraction_id!=$extraction)))+[$new])
' "$generation_file" | erl_atomic_write "$generation_file" || {
  rm -f -- "$document_file"
  cp "$tx_dir/backups/generation.json" "$generation_file"
  jq '.phase="rolled_back"' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json" || true
  erl_fail 60 error TRANSACTION_FAILED "Cannot update generation state"
}
jq --arg hash "$(erl_sha256_file "$generation_file")" '.phase="state_updated"|.generation_post_hash=$hash' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json" || {
  rm -f -- "$document_file"
  cp "$tx_dir/backups/generation.json" "$generation_file"
  jq '.phase="rolled_back"' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json" || true
  erl_fail 60 error TRANSACTION_FAILED "Cannot record updated state recovery metadata"
}

set +e; check_output="$(erl_run_check "$vault" generation "$generation")"; check_rc=$?; set -e
if (( check_rc != 0 )); then
  rm -f -- "$document_file"; cp "$tx_dir/backups/generation.json" "$generation_file"
  jq '.phase="rolled_back"' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json" || true
  erl_fail 60 error TRANSACTION_FAILED "Post-ingest validation failed and changes were rolled back" "$(jq -cn --argjson check "$check_output" '{check:$check}')"
fi
jq --arg document_uuid "$document_uuid" '.phase="committed"|.document_uuid=$document_uuid' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json"; rm -rf -- "$tx_dir/backups"
data="$(jq -cn --arg role "$role" --arg document_uuid "$document_uuid" --arg vocabulary_uuid "$vocabulary_uuid" --argjson identity "$identity" --argjson sequence_ordinal "$sequence_ordinal" --arg generation_uuid "$generation" '{role:$role,document_uuid:$document_uuid,lexical_identity:$identity,sequence_ordinal:$sequence_ordinal,generation_uuid:$generation_uuid} + if $vocabulary_uuid=="" then {} else {vocabulary_uuid:$vocabulary_uuid} end')"
erl_emit ok OK true "$data" '[]' 0
