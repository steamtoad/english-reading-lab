#!/bin/zsh

#------------------------------------------------------------------------------
# erl-card-content-repair.zsh
# Тип: ERL CLI
# Назначение: проверить и явно исправить безопасно восстанавливаемые ERL-DOC-008 blocks
#------------------------------------------------------------------------------

emulate -L zsh
setopt errexit pipe_fail no_unset

script_dir="${0:A:h}"
source "$script_dir/lib/common.zsh"

ERL_COMMAND="erl-card-content-repair"
ERL_JSON_MODE=0
vault_arg="" mode="" document_uuid="" tmp_dir=""

for option in "$@"; do
  [[ "$option" == --json ]] && ERL_JSON_MODE=1
done

while (( $# )); do
  case "$1" in
    --vault) (( $# >= 2 )) || erl_usage_error "--vault requires DIR"; vault_arg="$2"; shift 2 ;;
    --document) (( $# >= 2 )) || erl_usage_error "--document requires UUID"; document_uuid="$2"; shift 2 ;;
    --dry-run|--apply) [[ -z "$mode" ]] || erl_usage_error "Select exactly one of --dry-run or --apply"; mode="${1#--}"; shift ;;
    --json) ERL_JSON_MODE=1; shift ;;
    --help) print -r -- "Usage: $ERL_COMMAND --vault DIR [--document UUID] (--dry-run|--apply) [--json]"; exit 0 ;;
    *) erl_usage_error "Unknown argument: $1" ;;
  esac
done

[[ -n "$mode" ]] || erl_usage_error "Select exactly one of --dry-run or --apply"
if [[ -n "$document_uuid" && ! "$document_uuid" =~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' ]]; then
  erl_usage_error "--document must be a lowercase UUID"
fi
erl_require_command jq
vault="$(erl_resolve_vault "$vault_arg")"
erl_validate_target_root_role "$vault"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/erl-card-repair.XXXXXX")" || erl_fail 50 error IO_ERROR "Cannot allocate audit workspace"
trap 'rm -rf -- "$tmp_dir"' EXIT HUP INT TERM

check_args=(--vault "$vault" --json)
[[ -n "$document_uuid" ]] && check_args+=(--document "$document_uuid")
set +e
"$script_dir/erl-check.zsh" "${check_args[@]}" > "$tmp_dir/check.json"
check_rc=$?
set -e
(( check_rc == 0 || check_rc == 10 )) || erl_fail "$check_rc" error CHECK_FAILED "Cannot audit ERL card content" "$(jq -c '{check:.}' "$tmp_dir/check.json")"

jq -c '[.diagnostics[]? | select(.code=="ERL-CHECK-030")]' "$tmp_dir/check.json" > "$tmp_dir/findings.json"
jq -c '[.[] | {document_uuid,role,work_id:(.work_id // ""),condition}] | unique_by(.document_uuid,.condition)' "$tmp_dir/findings.json" > "$tmp_dir/exact-findings.json"
: > "$tmp_dir/plans.jsonl"
: > "$tmp_dir/conflicts.jsonl"

for uuid in ${(f)$(jq -r '.[].document_uuid' "$tmp_dir/findings.json" | sort -u)}; do
  [[ -n "$uuid" ]] || continue
  role="$(jq -r --arg uuid "$uuid" 'map(select(.document_uuid==$uuid))[0].role' "$tmp_dir/findings.json")"
  conditions="$(jq -c --arg uuid "$uuid" '[.[] | select(.document_uuid==$uuid) | .condition] | unique' "$tmp_dir/findings.json")"
  file="$vault/notes/$uuid.adoc"
  action="" content="" work_id="$(jq -r --arg uuid "$uuid" 'map(select(.document_uuid==$uuid))[0].work_id // ""' "$tmp_dir/findings.json")"

  if [[ "$role" == book ]] && jq -e 'all(. == "empty document body" or . == "Book body lacks readable book identity or navigation")' <<< "$conditions" >/dev/null; then
    work_file="$(erl_find_work_file "$vault" "$work_id" 2>/dev/null || true)"
    title="$(jq -r '.title // empty' "$work_file" 2>/dev/null || true)"
    key_topic="$(awk '/^:key-topic:/{sub(/^:key-topic:[[:space:]]*/,"");print;exit}' "$file")"
    if [[ -n "$title" && -n "$key_topic" ]]; then
      action="append Book readability section"
      content="== Book

Title:: $(erl_json_escape_asciidoc "$title")
Reading topic:: $(erl_json_escape_asciidoc "$key_topic")

This card is the reading hub for _$(erl_json_escape_asciidoc "$title")_."
    fi
  elif [[ "$role" == chapter ]] && jq -e 'all(. == "Chapter body lacks labelled Book context")' <<< "$conditions" >/dev/null; then
    work_file="$(erl_find_work_file "$vault" "$work_id" 2>/dev/null || true)"
    title="$(jq -r '.title // empty' "$work_file" 2>/dev/null || true)"
    locator=""
    for source_file in "${work_file:h}"/sources/*.json(N); do
      locator="$(jq -r --arg uuid "$uuid" '.chapters[]? | select(.chapter_uuid==$uuid) | .chapter_locator' "$source_file" | head -n 1)"
      [[ -n "$locator" ]] && break
    done
    if [[ -n "$title" && -n "$locator" ]]; then
      action="append Chapter source context"
      content="== Source

Book:: $(erl_json_escape_asciidoc "$title")
Chapter locator:: $(erl_json_escape_asciidoc "$locator")"
    fi
  fi

  if [[ -n "$action" ]]; then
    encoded="$(print -rn -- "$content" | base64 | tr -d '\n')"
    jq -cn --arg document_uuid "$uuid" --arg role "$role" --arg path "$file" --arg action "$action" \
      --arg content_base64 "$encoded" --arg pre_hash "$(erl_sha256_file "$file")" \
      '{document_uuid:$document_uuid,role:$role,path:$path,action:$action,content_base64:$content_base64,pre_hash:$pre_hash}' >> "$tmp_dir/plans.jsonl"
  else
    jq -cn --arg document_uuid "$uuid" --arg role "$role" --argjson conditions "$conditions" \
      '{document_uuid:$document_uuid,role:$role,conditions:$conditions,reason:"required readable content cannot be reconstructed without overwriting or inventing user content"}' >> "$tmp_dir/conflicts.jsonl"
  fi
done

plans="$(jq -s '.' "$tmp_dir/plans.jsonl")"
conflicts="$(jq -s '.' "$tmp_dir/conflicts.jsonl")"
findings="$(cat "$tmp_dir/exact-findings.json")"
data="$(jq -cn --arg vault "$vault" --argjson findings "$findings" --argjson proposed_changes "$plans" --argjson conflicts "$conflicts" \
  '{vault:$vault,findings:$findings,proposed_changes:$proposed_changes,conflicts:$conflicts,repairable:($proposed_changes|length),blocked:($conflicts|length)}')"

[[ "$mode" == apply ]] || erl_emit ok AUDIT_COMPLETE false "$data" '[]' 0
[[ "$(jq length <<< "$conflicts")" == 0 ]] || erl_fail 30 blocked REPAIR_CONFLICT \
  "Some card content cannot be repaired deterministically" "$data"
[[ "$(jq length <<< "$plans")" != 0 ]] || erl_emit ok ALREADY_VALID false "$data" '[]' 0

lock="$vault/.state/erl/locks/card-content-repair.lock"
erl_lock_acquire "$lock"
trap 'erl_lock_release "$lock"; rm -rf -- "$tmp_dir"' EXIT HUP INT TERM
txid="$(erl_uuid_v4)" || erl_fail 50 error IO_ERROR "Cannot generate TXID"
tx_dir="$vault/.state/erl/transactions/$txid"
mkdir -p -- "$tx_dir/backups" || erl_fail 50 error IO_ERROR "Cannot create repair journal"
print -r -- "$plans" | jq --arg txid "$txid" '{schema_version:1,txid:$txid,operation:"erl-card-content-repair",phase:"prepared",documents:.}' | erl_atomic_write "$tx_dir/transaction.json" || erl_fail 50 error IO_ERROR "Cannot write repair journal"

rollback_repair() {
  local row document_path uuid
  for row in ${(f)$(print -r -- "$plans" | jq -c '.[]')}; do
    document_path="$(jq -r .path <<< "$row")"; uuid="$(jq -r .document_uuid <<< "$row")"
    [[ -f "$tx_dir/backups/$uuid.adoc" ]] && cp -- "$tx_dir/backups/$uuid.adoc" "$document_path"
  done
  jq '.phase="rolled_back"' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json" || true
}

for row in ${(f)$(print -r -- "$plans" | jq -c '.[]')}; do
  document_path="$(jq -r .path <<< "$row")"; uuid="$(jq -r .document_uuid <<< "$row")"
  [[ "$(erl_sha256_file "$document_path")" == "$(jq -r .pre_hash <<< "$row")" ]] || { rollback_repair; erl_fail 30 blocked REPAIR_CONFLICT "Card changed after audit: $uuid"; }
  cp -- "$document_path" "$tx_dir/backups/$uuid.adoc"
  { print -r -- ""; jq -r .content_base64 <<< "$row" | base64 --decode; print -r -- ""; } >> "$document_path"
done
for row in ${(f)$(print -r -- "$plans" | jq -c '.[]')}; do
  uuid="$(jq -r .document_uuid <<< "$row")"; document_path="$(jq -r .path <<< "$row")"
  jq --arg uuid "$uuid" --arg hash "$(erl_sha256_file "$document_path")" \
    '(.documents[] | select(.document_uuid==$uuid) | .post_hash)=$hash' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json" || { rollback_repair; erl_fail 60 error TRANSACTION_FAILED "Cannot record repaired document hash"; }
done
jq '.phase="applied"' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json" || { rollback_repair; erl_fail 60 error TRANSACTION_FAILED "Cannot advance repair journal"; }

if [[ -n "${ERL_TEST_INTERRUPT_CARD_REPAIR_AFTER_MUTATION:-}" ]]; then
  erl_fail 60 error TRANSACTION_FAILED "Injected interruption; use erl-transaction-recover"
fi

if [[ -n "${ERL_TEST_FAIL_CARD_REPAIR_AFTER_MUTATION:-}" ]]; then
  rollback_repair
  erl_fail 60 error TRANSACTION_FAILED "Injected card repair failure; exact bytes restored"
fi

for uuid in ${(f)$(print -r -- "$plans" | jq -r '.[].document_uuid')}; do
  set +e
  "$script_dir/erl-check.zsh" --vault "$vault" --document "$uuid" --json > "$tmp_dir/post-$uuid.json"
  post_rc=$?
  set -e
  (( post_rc == 0 )) || { rollback_repair; erl_fail 60 error TRANSACTION_FAILED "Post-repair validation failed; exact bytes restored" "$(jq -c '{check:.}' "$tmp_dir/post-$uuid.json")"; }
done

jq '.phase="committed" | .documents |= map(del(.content_base64))' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json"
rm -rf -- "$tx_dir/backups"
data="$(jq -c --arg txid "$txid" '. + {txid:$txid}' <<< "$data")"
erl_emit ok OK true "$data" '[]' 0
