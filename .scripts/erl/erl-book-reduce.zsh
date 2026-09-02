#!/bin/zsh

#------------------------------------------------------------------------------
# erl-book-reduce.zsh
# Тип: ERL CLI
# Назначение: транзакционно закрыть Book generations с полным dependency closure и rollback
#------------------------------------------------------------------------------

emulate -L zsh
setopt pipe_fail no_unset
script_dir="${0:A:h}"
source "$script_dir/lib/common.zsh"
ERL_COMMAND="erl-book-reduce"; ERL_JSON_MODE=0
vault_arg="" mode="" include_dependencies=0 plan_fingerprint="" lock=""
typeset -a seed_generations
seed_generations=()
cleanup_reduce() { erl_lock_release "$lock"; }
trap cleanup_reduce EXIT HUP INT TERM
while (( $# )); do
  case "$1" in
    --vault) (( $#>=2 )) || erl_usage_error "--vault requires DIR"; vault_arg="$2"; shift 2 ;;
    --generation) (( $#>=2 )) || erl_usage_error "--generation requires UUID"; seed_generations+=("$2"); shift 2 ;;
    --include-dependencies) include_dependencies=1; shift ;;
    --plan-fingerprint) (( $#>=2 )) || erl_usage_error "--plan-fingerprint requires HASH"; plan_fingerprint="$2"; shift 2 ;;
    --dry-run|--apply) [[ -z "$mode" ]] || erl_usage_error "Select exactly one mode"; mode="${1#--}"; shift ;;
    --json) ERL_JSON_MODE=1; shift ;;
    --help) print -- "Usage: $ERL_COMMAND --vault DIR --generation UUID [--generation UUID ...] [--include-dependencies] [--plan-fingerprint HASH] (--dry-run|--apply) [--json]"; exit 0 ;;
    *) erl_usage_error "Unknown argument: $1" ;;
  esac
done
erl_require_command jq
(( ${#seed_generations} > 0 )) || erl_usage_error "At least one --generation is required"
[[ -n "$mode" ]] || erl_usage_error "Select exactly one of --dry-run or --apply"
[[ "$mode" == dry-run && -z "$plan_fingerprint" || "$mode" == apply && "$plan_fingerprint" =~ '^sha256:[0-9a-f]{64}$' ]] || erl_usage_error "--plan-fingerprint is required only with --apply"
vault="$(erl_resolve_vault "$vault_arg")"
erl_validate_target_root_role "$vault"

# Block on unfinished journals and invalid pre-existing state.
set +e; precheck="$(erl_run_check "$vault")"; precheck_rc=$?; set -e
(( precheck_rc == 0 )) || erl_fail 40 blocked VALIDATION_FAILED "ERL preflight validation failed" "$(jq -cn --argjson check "$precheck" '{check:$check}')"
[[ "$(jq -r .code <<< "$precheck")" != PENDING_TRANSACTION ]] || erl_fail 60 blocked PENDING_TRANSACTION "An unfinished transaction requires recovery"

typeset -A closure seed_set target_role target_reason target_generation target_type work_set
for generation in "${seed_generations[@]}"; do
  [[ "$generation" =~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' ]] || erl_fail 10 error INVALID_INPUT "Invalid generation UUID: $generation"
  generation_file="$(erl_find_generation_file "$vault" "$generation" 2>/dev/null)" || erl_fail 20 error NOT_FOUND "Generation not found: $generation"
  [[ "$(jq -r '.status // "active"' "$generation_file")" == active ]] || erl_fail 40 blocked GENERATION_CLOSED_EXTERNALLY "Generation is not active: $generation"
  closure[$generation]=1; seed_set[$generation]=1
done

add_generation_targets() {
  local generation="$1" generation_file work_id uuid role
  generation_file="$(erl_find_generation_file "$vault" "$generation")" || return 1
  work_id="$(jq -r .work_id "$generation_file")"; work_set[$work_id]=1
  target_role[$generation]=book; target_type[$generation]=topic; target_reason[$generation]="book_generation_seed_or_closure"; target_generation[$generation]="$generation"
  while IFS=$'\t' read -r uuid role; do
    [[ -n "$uuid" ]] || continue
    [[ "$role" == vocabulary || "$role" == occurrence ]] || continue
    target_role[$uuid]="$role"; target_type[$uuid]=memo; target_reason[$uuid]="reducible_generation_member"; target_generation[$uuid]="$generation"
  done < <(jq -r '((.members//[]) + [(.sequence//[])[] | {document_uuid,role,reducible:true}]) | unique_by(.document_uuid)[] | select((.reducible//true)==true) | [.document_uuid,.role]|@tsv' "$generation_file")
}

changed=1
while (( changed )); do
  changed=0
  for generation in "${(@k)closure}"; do add_generation_targets "$generation" || erl_fail 30 error STATE_CONFLICT "Generation disappeared during preflight: $generation"; done
  for target_uuid in "${(@k)target_role}"; do
    [[ "${target_role[$target_uuid]}" == vocabulary ]] || continue
    for candidate_generation_file in "$vault/.state/erl/works"/*/generations/*.json(N); do
      owner_generation="$(jq -r '.generation_uuid // .book_topic_uuid' "$candidate_generation_file")"
      [[ -n "${closure[$owner_generation]-}" ]] && continue
      [[ "$(jq -r '.status // "active"' "$candidate_generation_file")" == active ]] || continue
      depends=0
      if jq -e --arg target "$target_uuid" 'any(.sequence[]?; .role=="occurrence" and .vocabulary_uuid==$target)' "$candidate_generation_file" >/dev/null; then
        depends=1
      else
        while IFS= read -r occurrence_uuid; do
          occurrence_file="$(erl_doc_path "$vault" "$occurrence_uuid" 2>/dev/null)" || continue
          grep -qF -- "link:$target_uuid.adoc[" "$occurrence_file" && { depends=1; break; }
        done < <(jq -r '.sequence[]? | select(.role=="occurrence") | .document_uuid' "$candidate_generation_file")
      fi
      if (( depends )); then closure[$owner_generation]=1; changed=1; fi
    done
  done
done
for generation in "${(@k)closure}"; do add_generation_targets "$generation"; done

closure_json="$(printf '%s\n' "${(@k)closure}" | sort | jq -Rsc 'split("\n")|map(select(length>0))')"
seed_json="$(printf '%s\n' "${seed_generations[@]}" | sort -u | jq -Rsc 'split("\n")|map(select(length>0))')"
additional_json="$(jq -cn --argjson closure "$closure_json" --argjson seeds "$seed_json" '$closure-$seeds')"
targets_rows=()
hash_rows=()
for uuid in "${(@k)target_role}"; do
  file="$(erl_doc_path "$vault" "$uuid" 2>/dev/null)" || erl_fail 30 error STATE_CONFLICT "Mutation target document is missing: $uuid"
  [[ "$(erl_doc_attr "$file" type)" != note ]] || erl_fail 40 blocked VALIDATION_FAILED "Chapter Note entered Reduce mutation set: $uuid"
  targets_rows+=("$(jq -cn --arg uuid "$uuid" --arg type "${target_type[$uuid]}" --arg role "${target_role[$uuid]}" --arg reason "${target_reason[$uuid]}" --arg generation_uuid "${target_generation[$uuid]}" '{uuid:$uuid,type:$type,role:$role,reason:$reason,generation_uuid:$generation_uuid}')")
  hash_rows+=("$(jq -cn --arg path "$file" --arg hash "$(erl_sha256_file "$file")" '{path:$path,hash:$hash}')")
done
for generation in "${(@k)closure}"; do
  generation_file="$(erl_find_generation_file "$vault" "$generation")"
  hash_rows+=("$(jq -cn --arg path "$generation_file" --arg hash "$(erl_sha256_file "$generation_file")" '{path:$path,hash:$hash}')")
  work_file="$(erl_find_work_file "$vault" "$(jq -r .work_id "$generation_file")")"
  hash_rows+=("$(jq -cn --arg path "$work_file" --arg hash "$(erl_sha256_file "$work_file")" '{path:$path,hash:$hash}')")
done
targets_json="$(printf '%s\n' "${targets_rows[@]}" | jq -s 'unique_by(.uuid)|sort_by(.uuid)')"
hashes_json="$(printf '%s\n' "${hash_rows[@]}" | jq -s 'unique_by(.path)|sort_by(.path)')"

# Scan every active Vault document for inbound links to mutation targets. Known
# Occurrence -> Vocabulary relations are hard dependencies handled by closure;
# all other inbound links are explicitly reported as soft references.
soft_rows=()
for source_doc in "$vault/notes"/*.adoc(N); do
  erl_doc_deprecated "$source_doc" && continue
  source_uuid="${source_doc:t:r}"
  for target_uuid in "${(@k)target_role}"; do
    grep -qF -- "link:$target_uuid.adoc[" "$source_doc" || continue
    known_hard=0
    if [[ "${target_role[$target_uuid]}" == vocabulary ]]; then
      for candidate_generation_file in "$vault/.state/erl/works"/*/generations/*.json(N); do
        if jq -e --arg source "$source_uuid" --arg target "$target_uuid" 'any(.sequence[]?; .document_uuid==$source and .role=="occurrence" and .vocabulary_uuid==$target)' "$candidate_generation_file" >/dev/null; then
          known_hard=1; break
        fi
      done
    fi
    (( known_hard )) || soft_rows+=("$(jq -cn --arg source_uuid "$source_uuid" --arg target_uuid "$target_uuid" '{source_uuid:$source_uuid,target_uuid:$target_uuid,classification:"soft"}')")
  done
done
if (( ${#soft_rows} )); then
  soft_references_json="$(printf '%s\n' "${soft_rows[@]}" | jq -s 'unique_by(.source_uuid+"|"+.target_uuid)|sort_by(.source_uuid,.target_uuid)')"
else
  soft_references_json='[]'
fi

mutation_paths=("${(@f)$(jq -r '.[].path' <<< "$hashes_json")}")
git_preflight="$(erl_git_preflight "$vault" "${mutation_paths[@]}")" || erl_fail 50 error IO_ERROR "Cannot evaluate Git/worktree policy"
semantic_plan="$(jq -cn --argjson seeds "$seed_json" --argjson closure "$closure_json" --argjson additional "$additional_json" --argjson targets "$targets_json" --argjson hashes "$hashes_json" --argjson soft "$soft_references_json" --argjson git "$git_preflight" --argjson include "$include_dependencies" '{seed_generations:$seeds,closure_generations:$closure,additional_generations:$additional,targets:$targets,soft_references:$soft,git_preflight:$git,preflight_hashes:$hashes,include_dependencies:$include}')"
calculated_fingerprint="$(print -rn -- "$semantic_plan" | jq -cS . | erl_sha256_stdin)"
data="$(jq -cn --argjson plan "$semantic_plan" --arg fingerprint "$calculated_fingerprint" '$plan + {plan_fingerprint:$fingerprint}')"
additional_count="$(jq length <<< "$additional_json")"
if [[ "$mode" == dry-run ]]; then
  if [[ "$(jq -r .clean <<< "$git_preflight")" != true ]]; then erl_emit warning WORKTREE_DIRTY false "$data" '[]' 0
  elif (( additional_count > 0 && ! include_dependencies )); then erl_emit warning DEPENDENCIES_REQUIRED false "$data" '[]' 0
  else erl_emit ok OK false "$data" '[]' 0; fi
fi
[[ "$plan_fingerprint" == "$calculated_fingerprint" ]] || erl_fail 30 error STATE_CONFLICT "Plan fingerprint is stale or does not match the exact semantic plan" "$data"
[[ "$(jq -r .clean <<< "$git_preflight")" == true ]] || erl_fail 40 blocked WORKTREE_DIRTY "Git/worktree policy rejects dirty mutation targets" "$data"
(( additional_count == 0 || include_dependencies )) || erl_fail 40 blocked DEPENDENCIES_REQUIRED "Dependency closure exceeds seed generations; rerun with --include-dependencies" "$data"

lock="$vault/.state/erl/locks/book-reduce.lock"; erl_lock_acquire "$lock"
txid="$(erl_uuid_v4)" || erl_fail 50 error IO_ERROR "Cannot generate TXID"; tx_dir="$vault/.state/erl/transactions/$txid"; mkdir -p "$tx_dir/backups/documents" "$tx_dir/backups/generations" "$tx_dir/backups/works"
print -r -- "$semantic_plan" > "$tx_dir/plan.json"
jq -cn --arg txid "$txid" --arg fingerprint "$calculated_fingerprint" --argjson closed "$closure_json" --argjson targets "$targets_json" '{schema_version:1,txid:$txid,operation:"erl-book-reduce",phase:"applying",plan_fingerprint:$fingerprint,closed_generations:$closed,targets:$targets}' | erl_atomic_write "$tx_dir/transaction.json"
print -r -- '[]' > "$tx_dir/applied-hashes.json"
for uuid in "${(@k)target_role}"; do file="$(erl_doc_path "$vault" "$uuid")"; cp "$file" "$tx_dir/backups/documents/$uuid.adoc"; done
for generation in "${(@k)closure}"; do
  generation_file="$(erl_find_generation_file "$vault" "$generation")"; cp "$generation_file" "$tx_dir/backups/generations/$generation.json"
  work_id="$(jq -r .work_id "$generation_file")"; work_file="$(erl_find_work_file "$vault" "$work_id")"; [[ -f "$tx_dir/backups/works/$work_id.json" ]] || cp "$work_file" "$tx_dir/backups/works/$work_id.json"
done
rollback_reduce() {
  local file uuid generation work_id backup blocked=0
  restore_if_ours() {
    local backup="$1" file="$2" original expected current
    original="$(erl_sha256_file "$backup")"
    expected="$(jq -r --arg path "$file" '[.[]|select(.path==$path)][-1].hash // empty' "$tx_dir/applied-hashes.json")"
    if [[ -f "$file" ]]; then current="$(erl_sha256_file "$file")"; else current=missing; fi
    [[ "$current" == "$original" ]] && return 0
    if [[ -n "$expected" && "$current" == "$expected" ]]; then
      mkdir -p -- "${file:h}"; cp -- "$backup" "$file"; return $?
    fi
    blocked=1
    return 1
  }
  for backup in "$tx_dir/backups/documents"/*.adoc(N); do uuid="${backup:t:r}"; file="$(erl_doc_path "$vault" "$uuid" 2>/dev/null || print "$vault/notes/$uuid.adoc")"; restore_if_ours "$backup" "$file" || true; done
  for backup in "$tx_dir/backups/generations"/*.json(N); do generation="${backup:t:r}"; work_id="$(jq -r .work_id "$backup")"; work_file="$(erl_find_work_file "$vault" "$work_id" 2>/dev/null || true)"; generation_file="${work_file:h}/generations/$generation.json"; restore_if_ours "$backup" "$generation_file" || true; done
  for backup in "$tx_dir/backups/works"/*.json(N); do work_id="${backup:t:r}"; work_file="$(erl_find_work_file "$vault" "$work_id" 2>/dev/null || true)"; [[ -n "$work_file" ]] && restore_if_ours "$backup" "$work_file" || true; done
  if (( blocked )); then
    jq '.phase="rollback_blocked"' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json" || true
    return 1
  fi
  jq '.phase="rolled_back"' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json" || true
}
rollback_or_block() {
  rollback_reduce || erl_fail 60 blocked RECOVERY_CONFLICT "Rollback refused to overwrite files changed unexpectedly after transaction start"
}
record_applied_hash() {
  local target_path="$1" hash
  if [[ -f "$target_path" ]]; then hash="$(erl_sha256_file "$target_path")"; else hash=missing; fi
  jq --arg path "$target_path" --arg hash "$hash" '. + [{path:$path,hash:$hash}]' "$tx_dir/applied-hashes.json" | erl_atomic_write "$tx_dir/applied-hashes.json"
}
for uuid in "${(@k)target_role}"; do
  file="$(erl_doc_path "$vault" "$uuid")"
  erl_deprecate_document "$file" || { rollback_or_block; erl_fail 60 error TRANSACTION_FAILED "Cannot deprecate target: $uuid"; }
  record_applied_hash "$file" || { rollback_or_block; erl_fail 60 error TRANSACTION_FAILED "Cannot record applied document hash: $uuid"; }
done
for generation in "${(@k)closure}"; do
  generation_file="$(erl_find_generation_file "$vault" "$generation")"; work_id="$(jq -r .work_id "$generation_file")"; work_file="$(erl_find_work_file "$vault" "$work_id")"
  jq --arg generation "$generation" '.generation_uuids=((.generation_uuids//[])|map(select(.!=$generation))) | if (.active_generation_uuid//"")==$generation then .active_generation_uuid=null else . end' "$work_file" | erl_atomic_write "$work_file" || { rollback_or_block; erl_fail 60 error TRANSACTION_FAILED "Cannot update work manifest"; }
  record_applied_hash "$work_file" || { rollback_or_block; erl_fail 60 error TRANSACTION_FAILED "Cannot record applied work hash"; }
  rm -f -- "$generation_file"
  record_applied_hash "$generation_file" || { rollback_or_block; erl_fail 60 error TRANSACTION_FAILED "Cannot record removed generation"; }
done
set +e; postcheck="$(erl_run_check "$vault")"; postcheck_rc=$?; set -e
if (( postcheck_rc != 0 )); then rollback_or_block; erl_fail 60 error TRANSACTION_FAILED "Reduce post-validation failed and transaction was rolled back" "$(jq -cn --argjson check "$postcheck" '{check:$check}')"; fi
jq '.phase="committed"' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json"; cp "$tx_dir/transaction.json" "$tx_dir/result.json"; rm -rf "$tx_dir/backups"; rm -f -- "$tx_dir/applied-hashes.json"
data="$(jq -cn --arg txid "$txid" --arg fingerprint "$calculated_fingerprint" --argjson closed "$closure_json" --argjson targets "$targets_json" '{txid:$txid,plan_fingerprint:$fingerprint,closed_generations:$closed,targets:$targets,receipt_status:"committed"}')"
erl_emit ok OK true "$data" '[]' 0
