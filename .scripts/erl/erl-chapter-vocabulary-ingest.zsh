#!/bin/zsh

#------------------------------------------------------------------------------
# erl-chapter-vocabulary-ingest.zsh
# Тип: ERL CLI
# Назначение: пакетно ingestировать staged Candidates главы в reading sequence без дубликатов
#------------------------------------------------------------------------------

emulate -L zsh
setopt pipe_fail no_unset
script_dir="${0:A:h}"
source "$script_dir/lib/common.zsh"
ERL_COMMAND="erl-chapter-vocabulary-ingest"; ERL_JSON_MODE=0
vault_arg="" extraction_id="" mode=""
while (( $# )); do
  case "$1" in
    --vault) (( $#>=2 )) || erl_usage_error "--vault requires DIR"; vault_arg="$2"; shift 2 ;;
    --extraction-id) (( $#>=2 )) || erl_usage_error "--extraction-id requires UUID"; extraction_id="$2"; shift 2 ;;
    --dry-run|--apply) [[ -z "$mode" ]] || erl_usage_error "Select exactly one mode"; mode="${1#--}"; shift ;;
    --json) ERL_JSON_MODE=1; shift ;;
    --help) print -- "Usage: $ERL_COMMAND --vault DIR --extraction-id UUID (--dry-run|--apply) [--json]"; exit 0 ;;
    *) erl_usage_error "Unknown argument: $1" ;;
  esac
done
erl_require_command jq
[[ -n "$mode" ]] || erl_usage_error "Select exactly one of --dry-run or --apply"
vault="$(erl_resolve_vault "$vault_arg")"
erl_validate_target_root_role "$vault"
staging_file="$(erl_extraction_file "$vault" "$extraction_id" 2>/dev/null)" || erl_fail 20 error NOT_FOUND "Staged extraction not found: $extraction_id"
generation="$(jq -r .generation_uuid "$staging_file")"; chapter="$(jq -r .chapter_uuid "$staging_file")"
generation_file="$(erl_find_generation_file "$vault" "$generation" 2>/dev/null)" || erl_fail 20 error NOT_FOUND "Generation not found: $generation"
if jq -e --arg extraction "$extraction_id" 'any(.ingestion_receipts[]?; .extraction_id==$extraction and .status=="completed")' "$generation_file" >/dev/null; then
  handoff="$($script_dir/erl-chapter-chain-handoff.zsh --vault "$vault" --generation "$generation" --chapter "$chapter" --"$mode" --json)" || {
    rc=$?; erl_fail "$rc" blocked "$(jq -r '.code // "RECOVERY_REQUIRED"' <<< "$handoff")" "Completed batch handoff requires recovery" "$(jq -cn --argjson handoff "$handoff" '{handoff:$handoff}')"
  }
  data="$(jq -cn --arg extraction_id "$extraction_id" --arg chapter_uuid "$chapter" --arg generation_uuid "$generation" --argjson handoff "$(jq '.data' <<< "$handoff")" '{extraction_id:$extraction_id,chapter_uuid:$chapter_uuid,generation_uuid:$generation_uuid,receipt_status:"completed",handoff:$handoff}')"
  erl_emit ok ALREADY_INGESTED "$(jq -r '.changed' <<< "$handoff")" "$data" '[]' 0
fi
plans=()
next_sequence_ordinal=$(( $(jq '[.sequence[]?.ordinal] | max // 0' "$generation_file") + 1 ))
while IFS= read -r ordinal; do
  if result="$("$script_dir/erl-vocabulary-ingest.zsh" --vault "$vault" --extraction-id "$extraction_id" --candidate "$ordinal" --dry-run --json)"; then rc=0; else rc=$?; fi
  (( rc == 0 )) || erl_fail "$rc" error "$(jq -r '.code // "INTERNAL_ERROR"' <<< "$result")" "Candidate $ordinal dry-run failed" "$(jq -cn --argjson result "$result" '{result:$result}')"
  plans+=("$(jq -c --argjson sequence_ordinal "$next_sequence_ordinal" '.data | .prospective_sequence_ordinal=$sequence_ordinal' <<< "$result")")
  next_sequence_ordinal=$((next_sequence_ordinal + 1))
done < <(jq -r '.candidates[].ordinal' "$staging_file")
plan_array="$(printf '%s\n' "${plans[@]}" | jq -s 'sort_by(.candidate_ordinal)')"
if [[ "$mode" == dry-run ]]; then
  data="$(jq -cn --arg extraction_id "$extraction_id" --arg chapter_uuid "$chapter" --arg generation_uuid "$generation" --argjson plan "$plan_array" '{extraction_id:$extraction_id,chapter_uuid:$chapter_uuid,generation_uuid:$generation_uuid,plan:$plan,candidate_count:($plan|length),created_vocabulary:([$plan[]|select(.role=="vocabulary")]|length),created_occurrences:([$plan[]|select(.role=="occurrence")]|length),sequence_from:($plan|map(.prospective_sequence_ordinal)|min),sequence_to:($plan|map(.prospective_sequence_ordinal)|max),handoff:{phase:"after-candidate-commit",resolution:"source-order"}}')"
  erl_emit ok OK false "$data" '[]' 0
fi

created_vocabulary=0; created_occurrences=0; sequence_from=""; sequence_to=""
while IFS= read -r ordinal; do
  if result="$("$script_dir/erl-vocabulary-ingest.zsh" --vault "$vault" --extraction-id "$extraction_id" --candidate "$ordinal" --apply --json)"; then rc=0; else rc=$?; fi
  if (( rc != 0 )); then
    code="$(jq -r '.code // "RECOVERY_REQUIRED"' <<< "$result" 2>/dev/null)"
    erl_fail "$rc" blocked "$code" "Batch ingestion stopped at Candidate $ordinal; completed per-Candidate receipts are retained for safe resume" "$(jq -cn --argjson result "$result" '{result:$result}')"
  fi
  role="$(jq -r '.data.role // empty' <<< "$result")"; sequence="$(jq -r '.data.sequence_ordinal // empty' <<< "$result")"
  [[ "$role" == vocabulary ]] && created_vocabulary=$((created_vocabulary + 1))
  [[ "$role" == occurrence ]] && created_occurrences=$((created_occurrences + 1))
  [[ -n "$sequence_from" ]] || sequence_from="$sequence"; sequence_to="$sequence"
done < <(jq -r '.candidates[].ordinal' "$staging_file")

generation_file="$(erl_find_generation_file "$vault" "$generation")"
receipt_status="$(jq -r --arg extraction "$extraction_id" '.ingestion_receipts[]? | select(.extraction_id==$extraction) | .status' "$generation_file")"
[[ "$receipt_status" == completed ]] || erl_fail 60 blocked RECOVERY_REQUIRED "Batch ended without a completed ingestion receipt"
if handoff="$($script_dir/erl-chapter-chain-handoff.zsh --vault "$vault" --generation "$generation" --chapter "$chapter" --apply --json)"; then rc=0; else rc=$?; fi
(( rc == 0 )) || erl_fail "$rc" blocked "$(jq -r '.code // "RECOVERY_REQUIRED"' <<< "$handoff")" "Candidate receipts completed but Chapter handoff requires recovery" "$(jq -cn --argjson handoff "$handoff" '{handoff:$handoff}')"
data="$(jq -cn --arg extraction_id "$extraction_id" --arg chapter_uuid "$chapter" --arg generation_uuid "$generation" --argjson created_vocabulary "$created_vocabulary" --argjson created_occurrences "$created_occurrences" --argjson sequence_from "${sequence_from:-null}" --argjson sequence_to "${sequence_to:-null}" --argjson handoff "$(jq '.data' <<< "$handoff")" '{extraction_id:$extraction_id,chapter_uuid:$chapter_uuid,generation_uuid:$generation_uuid,created_vocabulary:$created_vocabulary,created_occurrences:$created_occurrences,sequence_from:$sequence_from,sequence_to:$sequence_to,receipt_status:"completed",handoff:$handoff}')"
erl_emit ok OK true "$data" '[]' 0
