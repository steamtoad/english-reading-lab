#!/bin/zsh

#------------------------------------------------------------------------------
# erl-transaction-recover.zsh
# Тип: ERL CLI
# Назначение: детерминированно восстановить прерванную ERL transaction
#------------------------------------------------------------------------------

emulate -L zsh
setopt pipe_fail no_unset
script_dir="${0:A:h}"
source "$script_dir/lib/common.zsh"
ERL_COMMAND="erl-transaction-recover"; ERL_JSON_MODE=0
vault_arg=""; txid=""; mode=""; lock=""
trap 'erl_lock_release "$lock"' EXIT HUP INT TERM
while (( $# )); do
  case "$1" in
    --vault) (( $#>=2 )) || erl_usage_error "--vault requires DIR"; vault_arg="$2"; shift 2 ;;
    --txid) (( $#>=2 )) || erl_usage_error "--txid requires UUID"; txid="$2"; shift 2 ;;
    --dry-run|--apply) [[ -z "$mode" ]] || erl_usage_error "Select exactly one mode"; mode="${1#--}"; shift ;;
    --json) ERL_JSON_MODE=1; shift ;;
    --help) print -- "Usage: $ERL_COMMAND --vault DIR --txid UUID (--dry-run|--apply) [--json]"; exit 0 ;;
    *) erl_usage_error "Unknown argument: $1" ;;
  esac
done
erl_require_command jq
[[ -n "$mode" ]] || erl_usage_error "Select exactly one of --dry-run or --apply"
[[ "$txid" =~ '^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' ]] || erl_usage_error "--txid must be lowercase UUID v4"
vault="$(erl_resolve_target_home "$vault_arg" allow-legacy)"; erl_validate_target_root_role "$vault"; tx_dir="$vault/.state/erl/transactions/$txid"; tx_file="$tx_dir/transaction.json"
[[ -f "$tx_file" ]] || erl_fail 20 error NOT_FOUND "Transaction not found: $txid"
operation="$(jq -r '.operation // empty' "$tx_file")"; phase="$(jq -r '.phase // empty' "$tx_file")"
[[ "$phase" != committed && "$phase" != rolled_back ]] || erl_emit ok ALREADY_RECOVERED false "$(jq -cn --arg txid "$txid" --arg phase "$phase" '{txid:$txid,phase:$phase}')" '[]' 0
if [[ "$operation" == erl-home-layout-migrate ]]; then
  data="$(jq -cn --arg txid "$txid" --arg operation "$operation" --arg phase "$phase" '{txid:$txid,operation:$operation,phase:$phase,recovery_action:"rollback"}')"
  [[ "$mode" == apply ]] || erl_emit ok OK false "$data" '[]' 0
  lock="$vault/.state/erl/locks/transaction-recover-$txid.lock"; erl_lock_acquire "$lock"
  while IFS=$'\t' read -r source target expected copied; do
    [[ "$copied" == true && -e "$target" ]] || continue
    [[ "$(erl_sha256_file "$target")" == "$expected" ]] || erl_fail 40 blocked RECOVERY_CONFLICT "Migrated target changed unexpectedly: $target"
    if [[ ! -e "$source" ]]; then
      mkdir -p -- "${source:h}" || erl_fail 60 error TRANSACTION_FAILED "Cannot restore migration source directory"
      cp -- "$target" "$source" || erl_fail 60 error TRANSACTION_FAILED "Cannot restore migration source: $source"
    fi
    [[ "$(erl_sha256_file "$source")" == "$expected" ]] || erl_fail 40 blocked RECOVERY_CONFLICT "Migration source changed unexpectedly: $source"
    rm -f -- "$target" || erl_fail 60 error TRANSACTION_FAILED "Cannot remove migrated target: $target"
  done < <(jq -r '.items|reverse[]|[.source,.target,.hash,.copied]|@tsv' "$tx_file")
  jq '.phase="rolled_back"' "$tx_file" | erl_atomic_write "$tx_file" || erl_fail 60 error TRANSACTION_FAILED "Cannot finalize home-layout rollback"
  erl_emit ok OK true "$data" '[]' 0
fi
if [[ "$operation" == erl-book-ingest ]]; then
  generation="$(jq -r '.generation_uuid // empty' "$tx_file")"; manifest="$(jq -r '.work_manifest_path // empty' "$tx_file")"
  action=rollback
  if [[ -n "$generation" && -f "$manifest" ]] && jq -e --arg generation "$generation" 'any(.generation_uuids[]?; .==$generation)' "$manifest" >/dev/null 2>&1; then action=commit; fi
  data="$(jq -cn --arg txid "$txid" --arg operation "$operation" --arg action "$action" --arg phase "$phase" '{txid:$txid,operation:$operation,phase:$phase,recovery_action:$action}')"
  [[ "$mode" == apply ]] || erl_emit ok OK false "$data" '[]' 0
  lock="$vault/.state/erl/locks/transaction-recover-$txid.lock"; erl_lock_acquire "$lock"
  if [[ "$action" == commit ]]; then
    jq '.phase="committed"' "$tx_file" | erl_atomic_write "$tx_file" || erl_fail 60 error TRANSACTION_FAILED "Cannot finalize recovered Book ingest"
    rm -rf -- "$tx_dir/backups"
    erl_emit ok OK true "$data" '[]' 0
  fi
  # Refuse to delete any artifact whose content no longer matches the journal.
  while IFS=$'\t' read -r artifact_path artifact_hash; do
    [[ -e "$artifact_path" ]] || continue
    [[ "$(erl_sha256_file "$artifact_path")" == "$artifact_hash" ]] || erl_fail 40 blocked RECOVERY_CONFLICT "Created Book-ingest artifact changed unexpectedly: $artifact_path"
  done < <(jq -r '.created_artifacts[]? | [.path,.hash]|@tsv' "$tx_file")
  while IFS= read -r artifact_path; do [[ -n "$artifact_path" ]] && rm -f -- "$artifact_path"; done < <(jq -r '.created_artifacts | reverse[]? | .path' "$tx_file")
  while IFS=$'\t' read -r uuid modified_path pre_hash post_hash; do
    [[ -n "$modified_path" ]] || continue
    backup="$tx_dir/backups/$uuid.adoc"
    [[ -f "$backup" && "$(erl_sha256_file "$backup")" == "$pre_hash" ]] || erl_fail 40 blocked RECOVERY_CONFLICT "Book-ingest Chapter backup is missing or changed: $uuid"
    current_modified_hash="$(erl_sha256_file "$modified_path")"
    [[ "$current_modified_hash" == "$pre_hash" || ( -n "$post_hash" && "$current_modified_hash" == "$post_hash" ) ]] || erl_fail 40 blocked RECOVERY_CONFLICT "Book-ingest Chapter changed unexpectedly: $modified_path"
    cp -- "$backup" "$modified_path" || erl_fail 60 error TRANSACTION_FAILED "Cannot restore Book-ingest Chapter: $modified_path"
  done < <(jq -r '.modified_documents[]? | [.uuid,.path,.pre_hash,(.post_hash // "")]|@tsv' "$tx_file")
  manifest_pre_hash="$(jq -r '.work_manifest_pre_hash // empty' "$tx_file")"
  if [[ -n "$manifest_pre_hash" && -f "$manifest" ]]; then
    [[ "$(erl_sha256_file "$manifest")" == "$manifest_pre_hash" ]] || erl_fail 40 blocked RECOVERY_CONFLICT "Existing work manifest changed unexpectedly; recovery refused"
    [[ -f "$tx_dir/backups/work.json" ]] && cp -- "$tx_dir/backups/work.json" "$manifest"
  fi
  work_dir="$(jq -r '.work_dir // empty' "$tx_file")"
  [[ -n "$work_dir" ]] && { rmdir -- "$work_dir/generations" "$work_dir/sources" "$work_dir" 2>/dev/null || true; }
  jq '.phase="rolled_back"' "$tx_file" | erl_atomic_write "$tx_file" || erl_fail 60 error TRANSACTION_FAILED "Cannot finalize Book-ingest rollback"
  rm -rf -- "$tx_dir/backups"
  erl_emit ok OK true "$data" '[]' 0
fi
if [[ "$operation" == erl-card-content-repair ]]; then
  data="$(jq -cn --arg txid "$txid" --arg operation "$operation" --arg phase "$phase" '{txid:$txid,operation:$operation,phase:$phase,recovery_action:"rollback"}')"
  [[ "$mode" == apply ]] || erl_emit ok OK false "$data" '[]' 0
  lock="$vault/.state/erl/locks/transaction-recover-$txid.lock"; erl_lock_acquire "$lock"
  while IFS=$'\t' read -r document_uuid document_path pre_hash post_hash; do
    backup="$tx_dir/backups/$document_uuid.adoc"
    [[ -f "$backup" && "$(erl_sha256_file "$backup")" == "$pre_hash" ]] || erl_fail 40 blocked RECOVERY_CONFLICT "Repair backup is missing or changed: $document_uuid"
    if [[ "$phase" == applied ]]; then
      [[ -f "$document_path" && -n "$post_hash" && "$(erl_sha256_file "$document_path")" == "$post_hash" ]] || erl_fail 40 blocked RECOVERY_CONFLICT "Repaired document changed unexpectedly: $document_path"
      cp -- "$backup" "$document_path" || erl_fail 60 error TRANSACTION_FAILED "Cannot restore repaired document: $document_path"
    fi
  done < <(jq -r '.documents[] | [.document_uuid,.path,.pre_hash,(.post_hash // "")]|@tsv' "$tx_file")
  jq '.phase="rolled_back"' "$tx_file" | erl_atomic_write "$tx_file" || erl_fail 60 error TRANSACTION_FAILED "Cannot finalize card-content repair rollback"
  rm -rf -- "$tx_dir/backups"
  erl_emit ok OK true "$data" '[]' 0
fi
if [[ "$operation" == erl-chapter-chain-handoff ]]; then
  data="$(jq -cn --arg txid "$txid" --arg operation "$operation" --arg phase "$phase" '{txid:$txid,operation:$operation,phase:$phase,recovery_action:"rollback"}')"
  [[ "$mode" == apply ]] || erl_emit ok OK false "$data" '[]' 0
  lock="$vault/.state/erl/locks/transaction-recover-$txid.lock"; erl_lock_acquire "$lock"
  while IFS=$'\t' read -r document_uuid document_path pre_hash post_hash; do
    backup="$tx_dir/backups/$document_uuid.adoc"
    [[ -f "$backup" && "$(erl_sha256_file "$backup")" == "$pre_hash" ]] || erl_fail 40 blocked RECOVERY_CONFLICT "Handoff backup is missing or changed: $document_uuid"
    if [[ "$phase" == applied ]]; then
      [[ -f "$document_path" && -n "$post_hash" && "$(erl_sha256_file "$document_path")" == "$post_hash" ]] || erl_fail 40 blocked RECOVERY_CONFLICT "Handoff document changed unexpectedly: $document_path"
      cp -- "$backup" "$document_path" || erl_fail 60 error TRANSACTION_FAILED "Cannot restore handoff document: $document_path"
    fi
  done < <(jq -r '.documents[] | [.document_uuid,.path,.pre_hash,(.post_hash // "")]|@tsv' "$tx_file")
  jq '.phase="rolled_back"' "$tx_file" | erl_atomic_write "$tx_file" || erl_fail 60 error TRANSACTION_FAILED "Cannot finalize Chapter handoff rollback"
  rm -rf -- "$tx_dir/backups"
  erl_emit ok OK true "$data" '[]' 0
fi
if [[ "$operation" == erl-chapter-memo-chain-migrate ]]; then
  data="$(jq -cn --arg txid "$txid" --arg operation "$operation" --arg phase "$phase" '{txid:$txid,operation:$operation,phase:$phase,recovery_action:"rollback"}')"
  [[ "$mode" == apply ]] || erl_emit ok OK false "$data" '[]' 0
  lock="$vault/.state/erl/locks/transaction-recover-$txid.lock"; erl_lock_acquire "$lock"
  while IFS=$'\t' read -r uuid document_path pre_hash; do
    backup="$tx_dir/backups/$uuid.adoc"
    [[ -f "$backup" && "$(erl_sha256_file "$backup")" == "$pre_hash" ]] || erl_fail 40 blocked RECOVERY_CONFLICT "Chapter Memo Chain migration backup is missing or changed: $uuid"
    cp -- "$backup" "$document_path" || erl_fail 60 error TRANSACTION_FAILED "Cannot restore Chapter Memo Chain document: $document_path"
  done < <(jq -r '.documents[]|[.uuid,.path,.pre_hash]|@tsv' "$tx_file")
  jq '.phase="rolled_back"' "$tx_file" | erl_atomic_write "$tx_file" || erl_fail 60 error TRANSACTION_FAILED "Cannot finalize Chapter Memo Chain rollback"
  rm -rf -- "$tx_dir/backups"
  erl_emit ok OK true "$data" '[]' 0
fi
if [[ "$operation" == erl-chapter-topic-binding-migrate ]]; then
  data="$(jq -cn --arg txid "$txid" --arg operation "$operation" --arg phase "$phase" '{txid:$txid,operation:$operation,phase:$phase,recovery_action:"rollback"}')"
  [[ "$mode" == apply ]] || erl_emit ok OK false "$data" '[]' 0
  lock="$vault/.state/erl/locks/transaction-recover-$txid.lock"; erl_lock_acquire "$lock"
  while IFS=$'\t' read -r uuid document_path pre_hash post_hash; do
    backup="$tx_dir/backups/$uuid.adoc"
    [[ -f "$backup" && "$(erl_sha256_file "$backup")" == "$pre_hash" ]] || erl_fail 40 blocked RECOVERY_CONFLICT "Chapter Topic binding backup is missing or changed: $uuid"
    current_hash="$(erl_sha256_file "$document_path")"
    [[ "$current_hash" == "$pre_hash" || ( -n "$post_hash" && "$current_hash" == "$post_hash" ) ]] || erl_fail 40 blocked RECOVERY_CONFLICT "Chapter Topic binding document changed unexpectedly: $document_path"
    cp -- "$backup" "$document_path" || erl_fail 60 error TRANSACTION_FAILED "Cannot restore Chapter Topic binding document: $document_path"
  done < <(jq -r '.documents[]|[.uuid,.path,.pre_hash,(.post_hash // "")]|@tsv' "$tx_file")
  jq '.phase="rolled_back"' "$tx_file" | erl_atomic_write "$tx_file" || erl_fail 60 error TRANSACTION_FAILED "Cannot finalize Chapter Topic binding rollback"
  rm -rf -- "$tx_dir/backups"
  erl_emit ok OK true "$data" '[]' 0
fi
if [[ "$operation" == erl-book-title-key-topic-migrate ]]; then
  data="$(jq -cn --arg txid "$txid" --arg operation "$operation" --arg phase "$phase" '{txid:$txid,operation:$operation,phase:$phase,recovery_action:"rollback"}')"
  [[ "$mode" == apply ]] || erl_emit ok OK false "$data" '[]' 0
  lock="$vault/.state/erl/locks/transaction-recover-$txid.lock"; erl_lock_acquire "$lock"
  while IFS=$'\t' read -r uuid document_path pre_hash post_hash; do
    backup="$tx_dir/backups/$uuid.adoc"
    [[ -f "$backup" && "$(erl_sha256_file "$backup")" == "$pre_hash" ]] || erl_fail 40 blocked RECOVERY_CONFLICT "Book-title migration backup is missing or changed: $uuid"
    current_hash="$(erl_sha256_file "$document_path")"
    [[ "$current_hash" == "$pre_hash" || ( -n "$post_hash" && "$current_hash" == "$post_hash" ) ]] || erl_fail 40 blocked RECOVERY_CONFLICT "Book-title migration document changed unexpectedly: $document_path"
    cp -- "$backup" "$document_path" || erl_fail 60 error TRANSACTION_FAILED "Cannot restore Book-title migration document: $document_path"
  done < <(jq -r '.documents[]|[.uuid,.path,.pre_hash,(.post_hash // "")]|@tsv' "$tx_file")
  jq '.phase="rolled_back"' "$tx_file" | erl_atomic_write "$tx_file" || erl_fail 60 error TRANSACTION_FAILED "Cannot finalize Book-title migration rollback"
  rm -rf -- "$tx_dir/backups"
  erl_emit ok OK true "$data" '[]' 0
fi
[[ "$operation" == erl-vocabulary-ingest ]] || erl_fail 40 blocked RECOVERY_UNSUPPORTED "Automatic recovery is not implemented for transaction operation: $operation"
generation="$(jq -r .generation_uuid "$tx_file")"; extraction="$(jq -r .extraction_id "$tx_file")"; candidate="$(jq -r .candidate_ordinal "$tx_file")"
generation_file="$(jq -r '.generation_path // empty' "$tx_file")"; [[ -f "$generation_file" ]] || generation_file="$(erl_find_generation_file "$vault" "$generation" 2>/dev/null)" || erl_fail 30 error STATE_CONFLICT "Generation state is unavailable for recovery"
completed=false
if jq -e --arg extraction "$extraction" --argjson candidate "$candidate" 'any(.ingestion_receipts[]?; .extraction_id==$extraction and any(.candidates[]?; .ordinal==$candidate and .status=="completed"))' "$generation_file" >/dev/null; then completed=true; fi
action=rollback
[[ "$completed" == true ]] && action=commit
data="$(jq -cn --arg txid "$txid" --arg operation "$operation" --arg action "$action" --arg phase "$phase" '{txid:$txid,operation:$operation,phase:$phase,recovery_action:$action}')"
[[ "$mode" == apply ]] || erl_emit ok OK false "$data" '[]' 0
lock="$vault/.state/erl/locks/transaction-recover-$txid.lock"; erl_lock_acquire "$lock"
if [[ "$action" == commit ]]; then
  jq '.phase="committed"' "$tx_file" | erl_atomic_write "$tx_file" || erl_fail 60 error TRANSACTION_FAILED "Cannot finalize recovered transaction"
  rm -rf -- "$tx_dir/backups"
  erl_emit ok OK true "$data" '[]' 0
fi
pre_hash="$(jq -r '.generation_pre_hash // empty' "$tx_file")"; current_hash="$(erl_sha256_file "$generation_file")"
[[ -n "$pre_hash" && "$current_hash" == "$pre_hash" ]] || erl_fail 40 blocked RECOVERY_CONFLICT "Generation changed unexpectedly; automatic rollback would overwrite newer state"
document_path="$(jq -r '.document_path // empty' "$tx_file")"; document_hash="$(jq -r '.document_hash // empty' "$tx_file")"
if [[ -n "$document_path" && -e "$document_path" ]]; then
  [[ -n "$document_hash" && "$(erl_sha256_file "$document_path")" == "$document_hash" ]] || erl_fail 40 blocked RECOVERY_CONFLICT "Created document changed unexpectedly; automatic rollback refused"
  rm -f -- "$document_path"
fi
for item in chapter predecessor; do
  item_path="$(jq -r --arg item "$item" '.[$item].path // empty' "$tx_file")"
  [[ -n "$item_path" ]] || continue
  item_pre_hash="$(jq -r --arg item "$item" '.[$item].pre_hash // empty' "$tx_file")"
  item_post_hash="$(jq -r --arg item "$item" '.[$item].post_hash // empty' "$tx_file")"
  backup="$tx_dir/backups/${item}.adoc"
  [[ -f "$backup" && "$(erl_sha256_file "$backup")" == "$item_pre_hash" ]] || erl_fail 40 blocked RECOVERY_CONFLICT "Vocabulary-ingest backup is missing or changed: $item"
  current_item_hash="$(erl_sha256_file "$item_path")"
  [[ "$current_item_hash" == "$item_pre_hash" || ( -n "$item_post_hash" && "$current_item_hash" == "$item_post_hash" ) ]] || erl_fail 40 blocked RECOVERY_CONFLICT "Vocabulary-ingest document changed unexpectedly: $item_path"
  cp -- "$backup" "$item_path" || erl_fail 60 error TRANSACTION_FAILED "Cannot restore Vocabulary-ingest document: $item_path"
done
jq '.phase="rolled_back"' "$tx_file" | erl_atomic_write "$tx_file" || erl_fail 60 error TRANSACTION_FAILED "Cannot finalize rollback recovery"
rm -rf -- "$tx_dir/backups"
erl_emit ok OK true "$data" '[]' 0
