#!/bin/zsh

#------------------------------------------------------------------------------
# erl-work-rename.zsh
# Тип: ERL CLI
# Назначение: атомарно переименовать human-readable work slug без смены identity
#------------------------------------------------------------------------------

emulate -L zsh
setopt pipe_fail no_unset
script_dir="${0:A:h}"
source "$script_dir/lib/common.zsh"
ERL_COMMAND="erl-work-rename"; ERL_JSON_MODE=0
vault_arg=""; work_id=""; new_slug=""; mode=""; lock=""
trap 'erl_lock_release "$lock"' EXIT HUP INT TERM

while (( $# )); do
  case "$1" in
    --vault) (( $#>=2 )) || erl_usage_error "--vault requires DIR"; vault_arg="$2"; shift 2 ;;
    --work-id) (( $#>=2 )) || erl_usage_error "--work-id requires UUID"; work_id="$2"; shift 2 ;;
    --new-slug) (( $#>=2 )) || erl_usage_error "--new-slug requires SLUG"; new_slug="$2"; shift 2 ;;
    --dry-run|--apply) [[ -z "$mode" ]] || erl_usage_error "Select exactly one mode"; mode="${1#--}"; shift ;;
    --json) ERL_JSON_MODE=1; shift ;;
    --help) print -- "Usage: $ERL_COMMAND --vault DIR --work-id UUID --new-slug SLUG (--dry-run|--apply) [--json]"; exit 0 ;;
    *) erl_usage_error "Unknown argument: $1" ;;
  esac
done

erl_require_command jq
[[ -n "$mode" ]] || erl_usage_error "Select exactly one of --dry-run or --apply"
[[ "$work_id" =~ '^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' ]] || erl_usage_error "--work-id must be lowercase UUID v4"
[[ "$new_slug" =~ '^[a-z0-9]+([a-z0-9-]*[a-z0-9])?$' ]] || erl_usage_error "--new-slug must contain lowercase letters, digits, and internal hyphens"
vault="$(erl_resolve_vault "$vault_arg")"
work_file="$(erl_find_work_file "$vault" "$work_id" 2>/dev/null)" || erl_fail 20 error NOT_FOUND "WORK_ID not found: $work_id"
old_dir="${work_file:h}"; old_slug="${old_dir:t}"; new_dir="${old_dir:h}/$new_slug"
data="$(jq -cn --arg work_id "$work_id" --arg old_slug "$old_slug" --arg new_slug "$new_slug" --arg old_path "$old_dir" --arg new_path "$new_dir" '{work_id:$work_id,old_slug:$old_slug,new_slug:$new_slug,old_path:$old_path,new_path:$new_path}')"
[[ "$old_slug" != "$new_slug" ]] || erl_emit ok ALREADY_CURRENT false "$data" '[]' 0
[[ ! -e "$new_dir" ]] || erl_fail 30 error STATE_CONFLICT "Target work slug already exists: $new_slug"
[[ "$mode" == apply ]] || erl_emit ok OK false "$data" '[]' 0

lock="$vault/.state/erl/locks/work-rename-$work_id.lock"; erl_lock_acquire "$lock"
# Re-resolve after locking to reject a stale plan.
work_file="$(erl_find_work_file "$vault" "$work_id" 2>/dev/null)" || erl_fail 30 error STATE_CONFLICT "Work moved during rename preflight"
[[ "${work_file:h}" == "$old_dir" && ! -e "$new_dir" ]] || erl_fail 30 error STATE_CONFLICT "Work slug state changed during rename preflight"
txid="$(erl_uuid_v4)" || erl_fail 50 error IO_ERROR "Cannot generate TXID"
tx_dir="$vault/.state/erl/transactions/$txid"; mkdir -p -- "$tx_dir/backups" || erl_fail 50 error IO_ERROR "Cannot create transaction journal"
cp -- "$work_file" "$tx_dir/backups/work.json" || erl_fail 50 error IO_ERROR "Cannot back up work manifest"
jq -cn --arg txid "$txid" --arg work_id "$work_id" --arg old_path "$old_dir" --arg new_path "$new_dir" '{schema_version:1,txid:$txid,operation:"erl-work-rename",phase:"applying",work_id:$work_id,old_path:$old_path,new_path:$new_path}' | erl_atomic_write "$tx_dir/transaction.json" || erl_fail 50 error IO_ERROR "Cannot create transaction journal"

mv -- "$old_dir" "$new_dir" || { jq '.phase="rolled_back"' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json" || true; erl_fail 50 error IO_ERROR "Cannot atomically rename work directory"; }
new_work_file="$new_dir/work.json"
if ! jq --arg slug "$new_slug" '.work_slug=$slug' "$new_work_file" | erl_atomic_write "$new_work_file"; then
  mv -- "$new_dir" "$old_dir" 2>/dev/null || true
  cp -- "$tx_dir/backups/work.json" "$old_dir/work.json" 2>/dev/null || true
  jq '.phase="rolled_back"' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json" || true
  erl_fail 60 error TRANSACTION_FAILED "Cannot update renamed work manifest; migration rolled back"
fi
set +e; check="$(erl_run_check "$vault" work "$work_id")"; check_rc=$?; set -e
if (( check_rc != 0 )); then
  mv -- "$new_dir" "$old_dir" 2>/dev/null || true
  cp -- "$tx_dir/backups/work.json" "$old_dir/work.json" 2>/dev/null || true
  jq '.phase="rolled_back"' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json" || true
  erl_fail 60 error TRANSACTION_FAILED "Post-rename validation failed; migration rolled back" "$(jq -cn --argjson check "$check" '{check:$check}')"
fi
jq '.phase="committed"' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json" || erl_fail 60 error TRANSACTION_FAILED "Cannot commit rename journal"
rm -rf -- "$tx_dir/backups"
erl_emit ok OK true "$data" '[]' 0
