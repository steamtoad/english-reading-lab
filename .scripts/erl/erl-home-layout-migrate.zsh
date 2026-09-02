#!/bin/zsh

#------------------------------------------------------------------------------
# erl-home-layout-migrate.zsh
# Тип: ERL CLI
# Назначение: безопасно перенести legacy vault/{notes,.state/erl} в target home
#------------------------------------------------------------------------------

emulate -L zsh
setopt pipe_fail no_unset
script_dir="${0:A:h}"
source "$script_dir/lib/common.zsh"
ERL_COMMAND="erl-home-layout-migrate"; ERL_JSON_MODE=0
home_arg=""; mode=""; lock=""
trap 'erl_lock_release "$lock"' EXIT HUP INT TERM

while (( $# )); do
  case "$1" in
    --vault|--home) (( $#>=2 )) || erl_usage_error "$1 requires DIR"; home_arg="$2"; shift 2 ;;
    --dry-run|--apply) [[ -z "$mode" ]] || erl_usage_error "Select exactly one mode"; mode="${1#--}"; shift ;;
    --json) ERL_JSON_MODE=1; shift ;;
    --help) print -- "Usage: $ERL_COMMAND (--home DIR|--vault DIR) (--dry-run|--apply) [--json]"; exit 0 ;;
    *) erl_usage_error "Unknown argument: $1" ;;
  esac
done

erl_require_command jq
[[ -n "$mode" ]] || erl_usage_error "Select exactly one of --dry-run or --apply"
[[ -n "$home_arg" && -d "$home_arg" ]] || erl_fail 20 error NOT_FOUND "Target Zettelkasten home does not exist: $home_arg"
home="${home_arg:A}"; erl_validate_target_root_role "$home"; legacy_root="$home/vault"
[[ -d "$legacy_root/notes" || -d "$legacy_root/.state/erl" ]] || erl_fail 20 error NOT_FOUND "Legacy nested layout not found under: $legacy_root"

typeset -a sources targets hashes collisions
sources=(); targets=(); hashes=(); collisions=()
while IFS= read -r source; do
  [[ -n "$source" ]] || continue
  if [[ "$source" == "$legacy_root/notes/"* ]]; then
    target="$home/notes/${source#$legacy_root/notes/}"
  else
    target="$home/.state/erl/${source#$legacy_root/.state/erl/}"
  fi
  sources+=("$source"); targets+=("$target"); hashes+=("$(erl_sha256_file "$source")")
  [[ ! -e "$target" ]] || collisions+=("$target")
done < <(find "$legacy_root/notes" "$legacy_root/.state/erl" -type f 2>/dev/null | sort)

(( ${#sources[@]} > 0 )) || erl_fail 20 error NOT_FOUND "Legacy nested layout contains no files"
inventory="$(jq -cn --arg home "$home" --arg legacy "$legacy_root" --argjson files "${#sources[@]}" --argjson collisions "${#collisions[@]}" '{target_home:$home,legacy_root:$legacy,files:$files,collisions:$collisions}')"
if (( ${#collisions[@]} > 0 )); then
  collision_json="$(printf '%s\n' "${collisions[@]}" | jq -Rsc 'split("\n")|map(select(length>0))')"
  erl_fail 30 blocked MIGRATION_COLLISION "Canonical target paths already exist; resolve collisions before migration" "$(jq -cn --argjson inventory "$inventory" --argjson paths "$collision_json" '$inventory+{collision_paths:$paths}')"
fi
[[ "$mode" == apply ]] || erl_emit ok OK false "$inventory" '[]' 0

lock="$home/.state/erl/locks/home-layout-migrate.lock"; erl_lock_acquire "$lock"
txid="$(erl_uuid_v4)" || erl_fail 50 error IO_ERROR "Cannot generate TXID"
tx_dir="$home/.state/erl/transactions/$txid"; tx_file="$tx_dir/transaction.json"
mkdir -p -- "$tx_dir" || erl_fail 50 error IO_ERROR "Cannot create migration transaction directory"
items='[]'
for (( i=1; i<=${#sources[@]}; i++ )); do
  items="$(jq -cn --argjson items "$items" --arg source "${sources[$i]}" --arg target "${targets[$i]}" --arg hash "${hashes[$i]}" '$items+[{source:$source,target:$target,hash:$hash,copied:false,source_removed:false}]')"
done
print -r -- "$(jq -cn --arg txid "$txid" --arg home "$home" --arg legacy "$legacy_root" --argjson items "$items" '{schema_version:1,txid:$txid,operation:"erl-home-layout-migrate",phase:"copying",target_home:$home,legacy_root:$legacy,items:$items}')" | erl_atomic_write "$tx_file" || erl_fail 50 error IO_ERROR "Cannot create migration journal"

rollback_migration() {
  local source target expected
  while IFS=$'\t' read -r source target expected; do
    [[ -n "$target" && -e "$target" ]] || continue
    [[ "$(erl_sha256_file "$target")" == "$expected" ]] || return 1
    if [[ ! -e "$source" ]]; then
      mkdir -p -- "${source:h}" || return 1
      cp -- "$target" "$source" || return 1
    fi
    [[ "$(erl_sha256_file "$source")" == "$expected" ]] || return 1
    rm -f -- "$target" || return 1
  done < <(jq -r '.items|reverse[]|select(.copied==true)|[.source,.target,.hash]|@tsv' "$tx_file")
  jq '.phase="rolled_back"' "$tx_file" | erl_atomic_write "$tx_file"
}

for (( i=1; i<=${#sources[@]}; i++ )); do
  source="${sources[$i]}"; target="${targets[$i]}"; expected="${hashes[$i]}"
  mkdir -p -- "${target:h}" || { rollback_migration || true; erl_fail 60 error TRANSACTION_FAILED "Cannot create target directory: ${target:h}"; }
  cp -- "$source" "$target" || { rollback_migration || true; erl_fail 60 error TRANSACTION_FAILED "Cannot copy migration artifact: $source"; }
  [[ "$(erl_sha256_file "$target")" == "$expected" ]] || { rollback_migration || true; erl_fail 60 error TRANSACTION_FAILED "Migration copy hash mismatch: $target"; }
  jq --arg target "$target" '(.items[]|select(.target==$target)|.copied)=true' "$tx_file" | erl_atomic_write "$tx_file" || { rollback_migration || true; erl_fail 60 error TRANSACTION_FAILED "Cannot update migration journal"; }
done

jq '.phase="removing_sources"' "$tx_file" | erl_atomic_write "$tx_file" || { rollback_migration || true; erl_fail 60 error TRANSACTION_FAILED "Cannot advance migration journal"; }
for (( i=1; i<=${#sources[@]}; i++ )); do
  source="${sources[$i]}"; target="${targets[$i]}"; expected="${hashes[$i]}"
  [[ "$(erl_sha256_file "$source")" == "$expected" && "$(erl_sha256_file "$target")" == "$expected" ]] || { rollback_migration || true; erl_fail 40 blocked RECOVERY_CONFLICT "Migration artifact changed unexpectedly: $source"; }
  rm -f -- "$source" || { rollback_migration || true; erl_fail 60 error TRANSACTION_FAILED "Cannot remove migrated source: $source"; }
  jq --arg target "$target" '(.items[]|select(.target==$target)|.source_removed)=true' "$tx_file" | erl_atomic_write "$tx_file" || { rollback_migration || true; erl_fail 60 error TRANSACTION_FAILED "Cannot update migration journal"; }
done

jq '.phase="committed"' "$tx_file" | erl_atomic_write "$tx_file" || erl_fail 60 error TRANSACTION_FAILED "Cannot commit migration journal"
find "$legacy_root" -depth -type d -empty -delete 2>/dev/null || true
data="$(jq -cn --arg txid "$txid" --arg home "$home" --argjson files "${#sources[@]}" '{txid:$txid,target_home:$home,files:$files,layout:"canonical"}')"
erl_emit ok OK true "$data" '[]' 0
