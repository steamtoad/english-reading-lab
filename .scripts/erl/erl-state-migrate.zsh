#!/bin/zsh

#------------------------------------------------------------------------------
# erl-state-migrate.zsh
# Тип: ERL CLI
# Назначение: атомарно мигрировать persistent work state к текущему OpenSpec baseline
#------------------------------------------------------------------------------

emulate -L zsh
setopt pipe_fail no_unset
script_dir="${0:A:h}"
source "$script_dir/lib/common.zsh"
ERL_COMMAND="erl-state-migrate"; ERL_JSON_MODE=0
vault_arg=""; work_id=""; mode=""; lock=""
trap 'erl_lock_release "$lock"' EXIT HUP INT TERM
while (( $# )); do
  case "$1" in
    --vault) (( $#>=2 )) || erl_usage_error "--vault requires DIR"; vault_arg="$2"; shift 2 ;;
    --work-id) (( $#>=2 )) || erl_usage_error "--work-id requires UUID"; work_id="$2"; shift 2 ;;
    --dry-run|--apply) [[ -z "$mode" ]] || erl_usage_error "Select exactly one mode"; mode="${1#--}"; shift ;;
    --json) ERL_JSON_MODE=1; shift ;;
    --help) print -- "Usage: $ERL_COMMAND --vault DIR --work-id UUID (--dry-run|--apply) [--json]"; exit 0 ;;
    *) erl_usage_error "Unknown argument: $1" ;;
  esac
done
erl_require_command jq
[[ -n "$mode" ]] || erl_usage_error "Select exactly one of --dry-run or --apply"
[[ "$work_id" =~ '^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' ]] || erl_usage_error "--work-id must be lowercase UUID v4"
vault="$(erl_resolve_vault "$vault_arg")"; work_file="$(erl_find_work_file "$vault" "$work_id" 2>/dev/null)" || erl_fail 20 error NOT_FOUND "WORK_ID not found: $work_id"; work_dir="${work_file:h}"
source_files=(); chapter_updates=0
for source_file in "$work_dir/sources"/*.json(N); do
  source_id="$(jq -r .source_id "$source_file")"
  missing="$(jq '[.chapters[]? | select((.source_id // "")=="")]|length' "$source_file")"
  mismatch="$(jq --arg source "$source_id" '[.chapters[]? | select((.source_id // $source)!=$source)]|length' "$source_file")"
  (( mismatch == 0 )) || erl_fail 30 error STATE_CONFLICT "Source state contains a conflicting Chapter SOURCE_ID: $source_file"
  if (( missing > 0 )); then source_files+=("$source_file"); chapter_updates=$((chapter_updates + missing)); fi
done
files_json="$(printf '%s\n' "${source_files[@]}" | jq -Rsc 'split("\n")|map(select(length>0))')"
data="$(jq -cn --arg work_id "$work_id" --argjson files "$files_json" --argjson chapters "$chapter_updates" '{work_id:$work_id,migration:"chapter-source-id-v1",source_files:$files,chapter_records:$chapters}')"
(( chapter_updates > 0 )) || erl_emit ok ALREADY_CURRENT false "$data" '[]' 0
[[ "$mode" == apply ]] || erl_emit ok OK false "$data" '[]' 0
lock="$vault/.state/erl/locks/state-migrate-$work_id.lock"; erl_lock_acquire "$lock"
txid="$(erl_uuid_v4)" || erl_fail 50 error IO_ERROR "Cannot generate TXID"; tx_dir="$vault/.state/erl/transactions/$txid"; mkdir -p -- "$tx_dir/backups" || erl_fail 50 error IO_ERROR "Cannot create migration journal"
jq -cn --arg txid "$txid" --arg work_id "$work_id" --argjson files "$files_json" '{schema_version:1,txid:$txid,operation:"erl-state-migrate",phase:"applying",work_id:$work_id,migration:"chapter-source-id-v1",source_files:$files}' | erl_atomic_write "$tx_dir/transaction.json" || erl_fail 50 error IO_ERROR "Cannot create migration journal"
rollback_migration() {
  local backup target
  for backup in "$tx_dir/backups"/*.json(N); do target="$(jq -r --arg name "${backup:t}" '.source_files[]|select(endswith($name))' "$tx_dir/transaction.json")"; [[ -n "$target" ]] && cp -- "$backup" "$target"; done
  jq '.phase="rolled_back"' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json" || true
}
for source_file in "${source_files[@]}"; do
  cp -- "$source_file" "$tx_dir/backups/${source_file:t}"
  source_id="$(jq -r .source_id "$source_file")"
  jq --arg source "$source_id" '.chapters |= map(.source_id=(.source_id // $source))' "$source_file" | erl_atomic_write "$source_file" || { rollback_migration; erl_fail 60 error TRANSACTION_FAILED "Cannot migrate source state"; }
done
set +e; check="$(erl_run_check "$vault" work "$work_id")"; check_rc=$?; set -e
if (( check_rc != 0 )); then rollback_migration; erl_fail 60 error TRANSACTION_FAILED "Post-migration validation failed; migration rolled back" "$(jq -cn --argjson check "$check" '{check:$check}')"; fi
jq '.phase="committed"' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json" || erl_fail 60 error TRANSACTION_FAILED "Cannot commit migration journal"
rm -rf -- "$tx_dir/backups"
erl_emit ok OK true "$data" '[]' 0
