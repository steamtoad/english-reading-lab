#!/bin/zsh

#------------------------------------------------------------------------------
# erl-classic-reduce-reconcile.zsh
# Тип: ERL CLI
# Назначение: согласовать результат Classic Reduce с ERL state и явно принять successor при необходимости
#------------------------------------------------------------------------------

emulate -L zsh
setopt pipe_fail no_unset
script_dir="${0:A:h}"
source "$script_dir/lib/common.zsh"
ERL_COMMAND="erl-classic-reduce-reconcile"; ERL_JSON_MODE=0
vault_arg="" generation="" successor="" mode="" lock=""
cleanup_reconcile() { erl_lock_release "$lock"; }
trap cleanup_reconcile EXIT HUP INT TERM
while (( $# )); do
  case "$1" in
    --vault) (( $#>=2 )) || erl_usage_error "--vault requires DIR"; vault_arg="$2"; shift 2 ;;
    --generation) (( $#>=2 )) || erl_usage_error "--generation requires UUID"; generation="$2"; shift 2 ;;
    --adopt-successor) (( $#>=2 )) || erl_usage_error "--adopt-successor requires UUID"; successor="$2"; shift 2 ;;
    --dry-run|--apply) [[ -z "$mode" ]] || erl_usage_error "Select exactly one mode"; mode="${1#--}"; shift ;;
    --json) ERL_JSON_MODE=1; shift ;;
    --help) print -- "Usage: $ERL_COMMAND --vault DIR --generation UUID [--adopt-successor UUID] (--dry-run|--apply) [--json]"; exit 0 ;;
    *) erl_usage_error "Unknown argument: $1" ;;
  esac
done
erl_require_command jq
[[ -n "$generation" ]] || erl_usage_error "--generation is required"
[[ -n "$mode" ]] || erl_usage_error "Select exactly one of --dry-run or --apply"
vault="$(erl_resolve_vault "$vault_arg")"
generation_file="$(erl_find_generation_file "$vault" "$generation" 2>/dev/null)" || erl_fail 20 error NOT_FOUND "Generation not found: $generation"
work_id="$(jq -r .work_id "$generation_file")"; work_file="$(erl_find_work_file "$vault" "$work_id" 2>/dev/null)" || erl_fail 20 error NOT_FOUND "Work manifest not found"
topic_file="$(erl_doc_path "$vault" "$generation" 2>/dev/null)" || erl_fail 20 error NOT_FOUND "Book Topic not found: $generation"
erl_doc_deprecated "$topic_file" || erl_fail 40 blocked STATE_CONFLICT "Book Topic is still active; Classic reconciliation is not applicable"
key_topic="$(erl_doc_attr "$topic_file" key-topic)"
detected=()
for file in "$vault/notes"/*.adoc(N); do
  [[ "$file" == "$topic_file" ]] && continue
  [[ "$(erl_doc_attr "$file" type)" == topic && "$(erl_doc_attr "$file" key-topic)" == "$key_topic" ]] || continue
  erl_doc_deprecated "$file" && continue
  candidate_uuid="${file:t:r}"
  if grep -qF -- "link:$generation.adoc[" "$file" || grep -qF -- "link:$candidate_uuid.adoc[" "$topic_file"; then detected+=("$candidate_uuid"); fi
done
detected_json="$(printf '%s\n' "${detected[@]}" | jq -Rsc 'split("\n")|map(select(length>0))|unique')"
if [[ -n "$successor" ]]; then
  successor_file="$(erl_doc_path "$vault" "$successor" 2>/dev/null)" || erl_fail 20 error NOT_FOUND "Successor Topic not found: $successor"
  [[ "$(erl_doc_attr "$successor_file" type)" == topic && "$(erl_doc_attr "$successor_file" key-topic)" == "$key_topic" ]] || erl_fail 10 error VALIDATION_FAILED "Successor is not a compatible Topic"
  erl_doc_deprecated "$successor_file" && erl_fail 40 blocked STATE_CONFLICT "Successor Topic is deprecated"
  current_active="$(jq -r '.active_generation_uuid // empty' "$work_file")"
  [[ -z "$current_active" || "$current_active" == "$generation" ]] || erl_fail 30 error STATE_CONFLICT "Work already has another active generation"
fi
generation_status="$(jq -r '.status // "active"' "$generation_file")"
plan="$(jq -cn --arg generation_uuid "$generation" --arg work_id "$work_id" --arg generation_status "$generation_status" --arg successor "$successor" --argjson detected "$detected_json" '{generation_uuid:$generation_uuid,work_id:$work_id,current_status:$generation_status,detected_successors:$detected,planned_status:"GENERATION_CLOSED_EXTERNALLY",clear_active_generation:true,adopt_successor:(if $successor=="" then null else $successor end)}')"
if [[ "$generation_status" == GENERATION_CLOSED_EXTERNALLY && -z "$successor" ]]; then erl_emit ok NO_CHANGES false "$plan" '[]' 0; fi
[[ "$mode" == apply ]] || erl_emit ok GENERATION_CLOSED_EXTERNALLY false "$plan" '[]' 0

lock="$vault/.state/erl/locks/reconcile-$generation.lock"; erl_lock_acquire "$lock"
txid="$(erl_uuid_v4)" || erl_fail 50 error IO_ERROR "Cannot generate TXID"; tx_dir="$vault/.state/erl/transactions/$txid"; mkdir -p "$tx_dir/backups"
cp "$work_file" "$tx_dir/backups/work.json"; cp "$generation_file" "$tx_dir/backups/generation.json"
jq -cn --arg txid "$txid" --arg generation "$generation" '{schema_version:1,txid:$txid,operation:"erl-classic-reduce-reconcile",phase:"applying",generation_uuid:$generation}' | erl_atomic_write "$tx_dir/transaction.json"
rollback_reconcile() {
  cp -- "$tx_dir/backups/work.json" "$work_file" 2>/dev/null || true
  cp -- "$tx_dir/backups/generation.json" "$generation_file" 2>/dev/null || true
  [[ -n "${successor_generation_file:-}" ]] && rm -f -- "$successor_generation_file"
  jq '.phase="rolled_back"' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json" || true
}
jq '.status="GENERATION_CLOSED_EXTERNALLY"' "$generation_file" | erl_atomic_write "$generation_file" || { rollback_reconcile; erl_fail 60 error TRANSACTION_FAILED "Cannot update generation status"; }
jq --arg generation "$generation" 'if (.active_generation_uuid//"")==$generation then .active_generation_uuid=null else . end' "$work_file" | erl_atomic_write "$work_file" || { rollback_reconcile; erl_fail 60 error TRANSACTION_FAILED "Cannot clear active generation pointer"; }
if [[ -n "$successor" ]]; then
  successor_generation_file="${generation_file:h}/$successor.json"
  jq --arg successor "$successor" '.generation_uuid=$successor|.status="active"|.sequence=[]|.members=[]|.ingestion_receipts=[]' "$tx_dir/backups/generation.json" | erl_atomic_write "$successor_generation_file" || { rollback_reconcile; erl_fail 60 error TRANSACTION_FAILED "Cannot create successor generation state"; }
  jq --arg successor "$successor" '.generation_uuids=((.generation_uuids//[])+[$successor]|unique)|.active_generation_uuid=$successor' "$work_file" | erl_atomic_write "$work_file" || { rollback_reconcile; erl_fail 60 error TRANSACTION_FAILED "Cannot register successor generation"; }
fi
set +e; check_output="$(erl_run_check "$vault" work "$work_id")"; check_rc=$?; set -e
if (( check_rc != 0 )); then
  rollback_reconcile
  erl_fail 60 error TRANSACTION_FAILED "Reconciliation validation failed and state was rolled back" "$(jq -cn --argjson check "$check_output" '{check:$check}')"
fi
jq --arg successor "$successor" '.phase="committed"|.adopted_successor=(if $successor=="" then null else $successor end)' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json"; rm -rf "$tx_dir/backups"
data="$(jq -cn --arg generation_uuid "$generation" --arg work_id "$work_id" --arg successor "$successor" '{generation_uuid:$generation_uuid,work_id:$work_id,status:"GENERATION_CLOSED_EXTERNALLY",active_generation_cleared:true,adopted_successor:(if $successor=="" then null else $successor end)}')"
erl_emit ok GENERATION_CLOSED_EXTERNALLY true "$data" '[]' 0
