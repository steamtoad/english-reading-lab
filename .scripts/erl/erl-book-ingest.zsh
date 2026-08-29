#!/bin/zsh

#------------------------------------------------------------------------------
# erl-book-ingest.zsh
# Тип: ERL CLI
# Назначение: импортировать локальную книгу, создать Book Topic, Chapter Notes и persistent work state
#------------------------------------------------------------------------------

emulate -L zsh
setopt pipe_fail no_unset

script_dir="${0:A:h}"
source "$script_dir/lib/common.zsh"
source "$script_dir/lib/source.zsh"

ERL_COMMAND="erl-book-ingest"
ERL_JSON_MODE=0
vault_arg="" source_file="" title="" key_topic="" policy_file="" work_id="" work_slug="" mode=""

while (( $# )); do
  case "$1" in
    --vault) (( $#>=2 )) || erl_usage_error "--vault requires DIR"; vault_arg="$2"; shift 2 ;;
    --source) (( $#>=2 )) || erl_usage_error "--source requires FILE"; source_file="$2"; shift 2 ;;
    --title) (( $#>=2 )) || erl_usage_error "--title requires TEXT"; title="$2"; shift 2 ;;
    --key-topic) (( $#>=2 )) || erl_usage_error "--key-topic requires TEXT"; key_topic="$2"; shift 2 ;;
    --policy-file) (( $#>=2 )) || erl_usage_error "--policy-file requires FILE"; policy_file="$2"; shift 2 ;;
    --work-id) (( $#>=2 )) || erl_usage_error "--work-id requires UUID"; work_id="$2"; shift 2 ;;
    --work-slug) (( $#>=2 )) || erl_usage_error "--work-slug requires SLUG"; work_slug="$2"; shift 2 ;;
    --dry-run|--apply) [[ -z "$mode" ]] || erl_usage_error "Select exactly one of --dry-run or --apply"; mode="${1#--}"; shift ;;
    --json) ERL_JSON_MODE=1; shift ;;
    --help) print -- "Usage: $ERL_COMMAND --vault DIR --source FILE --policy-file FILE [--title TEXT --key-topic TEXT] [--work-id UUID] [--work-slug SLUG] (--dry-run|--apply) [--json]"; exit 0 ;;
    *) erl_usage_error "Unknown argument: $1" ;;
  esac
done

erl_require_command jq
[[ -n "$mode" ]] || erl_usage_error "Select exactly one of --dry-run or --apply"
[[ -n "$source_file" && -f "$source_file" ]] || erl_fail 20 error NOT_FOUND "Source file not found: $source_file"
[[ -n "$policy_file" && -f "$policy_file" ]] || erl_fail 20 error NOT_FOUND "Policy file not found: $policy_file"
erl_policy_validate "$policy_file" || erl_fail 10 error VALIDATION_FAILED "Policy does not satisfy extraction-policy-v1 or identity hash mismatch"
vault="$(erl_resolve_vault "$vault_arg")"
source_file="${source_file:A}"
fingerprint="$(erl_sha256_file "$source_file")"
chapters="$(erl_source_chapters "$source_file")" || erl_fail 10 error INVALID_INPUT "Unsupported or unreadable source book: $source_file"
chapter_count="$(jq length <<< "$chapters")"
policy_identity="$(jq -r '.identity' "$policy_file")"

existing_work_file=""
if [[ -n "$work_id" ]]; then
  [[ "$work_id" =~ '^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' ]] || erl_fail 10 error INVALID_INPUT "WORK_ID must be lowercase UUID v4"
  existing_work_file="$(erl_find_work_file "$vault" "$work_id" 2>/dev/null)" || erl_fail 20 error NOT_FOUND "WORK_ID not found: $work_id"
  work_dir="${existing_work_file:h}"
  [[ -z "$(jq -r '.active_generation_uuid // empty' "$existing_work_file")" ]] || erl_fail 30 blocked STATE_CONFLICT "Existing work has an active generation; reduce it before creating another"
  [[ -n "$title" ]] || title="$(jq -r '.title // empty' "$existing_work_file")"
  [[ -n "$key_topic" ]] || erl_usage_error "--key-topic is required for a new Book generation"
else
  [[ -n "$title" ]] || erl_usage_error "--title is required for a new work"
  [[ -n "$key_topic" ]] || erl_usage_error "--key-topic is required for a new Book generation"
  [[ -n "$work_slug" ]] || work_slug="$(erl_slugify "$title")"
  [[ -n "$work_slug" ]] || erl_usage_error "Cannot derive a non-empty work slug"
  [[ ! -e "$vault/.state/erl/works/$work_slug/work.json" ]] || erl_fail 30 error STATE_CONFLICT "work-slug already exists: $work_slug"
  work_dir="$vault/.state/erl/works/$work_slug"
fi

existing_source=""
for candidate in "$work_dir"/sources/*.json(N); do
  [[ "$(jq -r '.source_fingerprint // empty' "$candidate")" == "$fingerprint" ]] && { existing_source="$candidate"; break; }
done
if [[ -n "$existing_source" ]]; then
  data="$(jq -cn --arg work_id "${work_id:-$(jq -r .work_id "$existing_work_file")}" --arg source_id "$(jq -r .source_id "$existing_source")" --arg fingerprint "$fingerprint" '{work_id:$work_id,source_id:$source_id,source_fingerprint:$fingerprint}')"
  erl_emit ok ALREADY_INGESTED false "$data" '[]' 0
fi

plan="$(jq -cn --argjson work_id "$(if [[ -n "$work_id" ]]; then jq -cn --arg v "$work_id" '$v'; else print null; fi)" \
  --arg fingerprint "$fingerprint" --argjson chapter_count "$chapter_count" --arg work_dir "$work_dir" \
  --argjson existing "$([[ -n "$work_id" ]] && print true || print false)" \
  '{work_id:$work_id,source_id:null,generation_uuid:null,source_fingerprint:$fingerprint,chapter_count:$chapter_count,work_state_path:$work_dir,will_generate_work_id:($existing|not),will_generate_source_id:true,will_generate_generation_uuid:true}')"
[[ "$mode" == apply ]] || erl_emit ok OK false "$plan" '[]' 0

lock="$vault/.state/erl/locks/book-ingest-${work_id:-$work_slug}.lock"
erl_lock_acquire "$lock"
tmp_tx=""; created_docs=(); created_work=0; created_source_file=""; created_generation_file=""
cleanup_ingest() { erl_lock_release "$lock"; }
trap cleanup_ingest EXIT HUP INT TERM

[[ -n "$work_id" ]] || work_id="$(erl_uuid_v4)" || erl_fail 50 error IO_ERROR "Cannot generate WORK_ID"
source_id="$(erl_uuid_v4)" || erl_fail 50 error IO_ERROR "Cannot generate SOURCE_ID"
txid="$(erl_uuid_v4)" || erl_fail 50 error IO_ERROR "Cannot generate TXID"
tx_dir="$vault/.state/erl/transactions/$txid"
[[ -z "$existing_work_file" ]] && created_work=1
mkdir -p -- "$tx_dir/backups" "$work_dir/sources" "$work_dir/generations" || erl_fail 50 error IO_ERROR "Cannot create ERL state directories"
print -r -- "$(jq -cn --arg txid "$txid" '{schema_version:1,txid:$txid,operation:"erl-book-ingest",phase:"applying",created_documents:[]}')" | erl_atomic_write "$tx_dir/transaction.json" || erl_fail 50 error IO_ERROR "Cannot create transaction journal"

rollback_ingest() {
  local file
  for file in "${created_docs[@]}"; do rm -f -- "$file"; done
  if (( created_work )); then
    rm -rf -- "$work_dir"
  else
    [[ -n "$created_source_file" ]] && rm -f -- "$created_source_file"
    [[ -n "$created_generation_file" ]] && rm -f -- "$created_generation_file"
    [[ -f "$tx_dir/backups/work.json" && -n "$existing_work_file" ]] && cp -- "$tx_dir/backups/work.json" "$existing_work_file"
  fi
  if [[ -f "$tx_dir/transaction.json" ]]; then
    jq '.phase="rolled_back"' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json" || true
  fi
}

objects_dir="$script_dir/../objects"
topic_title="$key_topic - ключевая тема"
generation_fname="$(ZK_HOME="$vault" "$objects_dir/topic-create.zsh" "$topic_title" "$key_topic" topic "$topic_title")" || { rollback_ingest; erl_fail 50 error IO_ERROR "Canonical Topic constructor failed"; }
generation_uuid="${generation_fname%.adoc}"
created_docs+=("$vault/notes/$generation_fname")
chapter_records=()
while IFS= read -r chapter_row; do
  chapter_title="$(jq -r .title <<< "$chapter_row")"
  locator="$(jq -r .chapter_locator <<< "$chapter_row")"
  source_order="$(jq -r .source_order <<< "$chapter_row")"
  chapter_fname="$(ZK_HOME="$vault" "$objects_dir/note-create.zsh" "$chapter_title" note "$chapter_title")" || { rollback_ingest; erl_fail 50 error IO_ERROR "Canonical Note constructor failed"; }
  chapter_uuid="${chapter_fname%.adoc}"
  created_docs+=("$vault/notes/$chapter_fname")
  {
    print -r -- "== Source"
    print -r -- ""
    print -r -- "Book:: $title"
    print -r -- "Chapter locator:: $locator"
  } >> "$vault/notes/$chapter_fname"
  chapter_records+=("$(jq -cn --arg chapter_uuid "$chapter_uuid" --arg locator "$locator" --argjson source_order "$source_order" '{chapter_uuid:$chapter_uuid,chapter_locator:$locator,source_order:$source_order}')")
done < <(jq -c '.[]' <<< "$chapters")

source_json="$(printf '%s\n' "${chapter_records[@]}" | jq -s --arg source_id "$source_id" --arg work_id "$work_id" --arg fingerprint "$fingerprint" --arg source_path "$source_file" '{schema_version:1,source_id:$source_id,work_id:$work_id,source_fingerprint:$fingerprint,source_path:$source_path,chapters:.}')"
created_source_file="$work_dir/sources/$source_id.json"
print -r -- "$source_json" | erl_atomic_write "$created_source_file" || { rollback_ingest; erl_fail 50 error IO_ERROR "Cannot write source state"; }
generation_json="$(jq -cn --arg generation_uuid "$generation_uuid" --arg work_id "$work_id" --arg source_id "$source_id" --argjson policy "$(cat "$policy_file")" '{schema_version:1,generation_uuid:$generation_uuid,work_id:$work_id,source_id:$source_id,status:"active",policy:$policy,policy_identity:$policy.identity,sequence:[],members:[],ingestion_receipts:[]}')"
created_generation_file="$work_dir/generations/$generation_uuid.json"
print -r -- "$generation_json" | erl_atomic_write "$created_generation_file" || { rollback_ingest; erl_fail 50 error IO_ERROR "Cannot write generation state"; }
if [[ -n "$existing_work_file" ]]; then
  cp -- "$existing_work_file" "$tx_dir/backups/work.json"
  jq --arg source_id "$source_id" --arg generation "$generation_uuid" '.source_ids=((.source_ids//[])+[$source_id]|unique)|.generation_uuids=((.generation_uuids//[])+[$generation]|unique)|.active_generation_uuid=$generation' "$existing_work_file" | erl_atomic_write "$existing_work_file" || { rollback_ingest; cp "$tx_dir/backups/work.json" "$existing_work_file"; erl_fail 50 error IO_ERROR "Cannot update work manifest"; }
else
  jq -cn --arg work_id "$work_id" --arg title "$title" --arg slug "${work_dir:t}" --arg source_id "$source_id" --arg generation "$generation_uuid" '{schema_version:1,work_id:$work_id,title:$title,work_slug:$slug,source_ids:[$source_id],generation_uuids:[$generation],active_generation_uuid:$generation}' | erl_atomic_write "$work_dir/work.json" || { rollback_ingest; erl_fail 50 error IO_ERROR "Cannot write work manifest"; }
fi

set +e
check_output="$(erl_run_check "$vault" work "$work_id")"; check_rc=$?
set -e
if (( check_rc != 0 )); then
  rollback_ingest
  erl_fail 60 error TRANSACTION_FAILED "Post-ingest validation failed and changes were rolled back" "$(jq -cn --argjson check "$check_output" '{check:$check}')"
fi
jq --argjson docs "$(printf '%s\n' "${created_docs[@]}" | jq -Rsc 'split("\n")|map(select(length>0))')" '.phase="committed"|.created_documents=$docs' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json"
rm -rf -- "$tx_dir/backups"
data="$(jq -cn --arg work_id "$work_id" --arg source_id "$source_id" --arg generation_uuid "$generation_uuid" --arg fingerprint "$fingerprint" --argjson chapter_count "$chapter_count" '{work_id:$work_id,source_id:$source_id,generation_uuid:$generation_uuid,source_fingerprint:$fingerprint,chapter_count:$chapter_count,created:{topics:1,notes:$chapter_count}}')"
erl_emit ok OK true "$data" '[]' 0
