#!/bin/zsh

#------------------------------------------------------------------------------
# erl-book-title-key-topic-migrate.zsh
# Тип: ERL CLI
# Назначение: атомарно синхронизировать active Book projection с logical-work title
#------------------------------------------------------------------------------

emulate -L zsh
setopt pipe_fail no_unset
script_dir="${0:A:h}"
source "$script_dir/lib/common.zsh"
source "$script_dir/lib/chapter-memo-chain.zsh"
ERL_COMMAND="erl-book-title-key-topic-migrate"; ERL_JSON_MODE=0
vault_arg=""; work_id=""; mode=""; lock=""
trap 'erl_lock_release "$lock"' EXIT HUP INT TERM

while (( $# )); do
  case "$1" in
    --vault) (( $#>=2 )) || erl_usage_error "--vault requires DIR"; vault_arg="$2"; shift 2 ;;
    --work) (( $#>=2 )) || erl_usage_error "--work requires UUID"; work_id="$2"; shift 2 ;;
    --dry-run|--apply) [[ -z "$mode" ]] || erl_usage_error "Select exactly one mode"; mode="${1#--}"; shift ;;
    --json) ERL_JSON_MODE=1; shift ;;
    --help) print -- "Usage: $ERL_COMMAND --vault DIR --work UUID (--dry-run|--apply) [--json]"; exit 0 ;;
    *) erl_usage_error "Unknown argument: $1" ;;
  esac
done
erl_require_command jq
[[ -n "$mode" ]] || erl_usage_error "Select exactly one of --dry-run or --apply"
[[ "$work_id" =~ '^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' ]] || erl_usage_error "--work must be lowercase UUID v4"
vault="$(erl_resolve_vault "$vault_arg")"; erl_validate_target_root_role "$vault"
work_file="$(erl_find_work_file "$vault" "$work_id" 2>/dev/null)" || erl_fail 20 error NOT_FOUND "Work manifest not found: $work_id"
title="$(jq -r '.title // empty' "$work_file")"; [[ -n "$title" ]] || erl_fail 30 error STATE_CONFLICT "Logical work has no canonical title"
generation="$(jq -r '.active_generation_uuid // empty' "$work_file")"; [[ -n "$generation" ]] || erl_fail 30 error STATE_CONFLICT "Logical work has no active generation"
generation_file="$(erl_find_generation_file "$vault" "$generation" 2>/dev/null)" || erl_fail 20 error NOT_FOUND "Active generation is missing: $generation"
[[ "$(jq -r '.status // "active"' "$generation_file")" == active ]] || erl_fail 30 error STATE_CONFLICT "Active generation is not open"
topic_file="$(erl_doc_path "$vault" "$generation" 2>/dev/null)" || erl_fail 20 error NOT_FOUND "Active Book Topic is missing: $generation"
[[ "$(erl_doc_attr "$topic_file" type)" == topic ]] || erl_fail 30 error STATE_CONFLICT "Active Book document is not a Topic"
topic_title="$(awk 'NR==1{sub(/^= /,"");print;exit}' "$topic_file")"
topic_description="$(erl_doc_attr "$topic_file" description)"; topic_doclink="$(erl_doc_attr "$topic_file" doclink)"
expected_doclink="link:$generation.adoc[$title]"
[[ "$topic_title" == "$title" && "$topic_description" == "$title" && "$topic_doclink" == "$expected_doclink" ]] || erl_fail 30 error STATE_CONFLICT "Book Topic presentation conflicts with the canonical logical-work title"

source_id="$(jq -r '.source_id // empty' "$generation_file")"
source_file="$(erl_find_source_file "$vault" "$source_id" 2>/dev/null)" || erl_fail 20 error NOT_FOUND "Active generation source is missing"
chapters=("${(@f)$(jq -r '.chapters|sort_by(.source_order)[]?.chapter_uuid' "$source_file")}"); chapters=("${(@)chapters:#}")
memo_rows=("${(@f)$(jq -r '.sequence[]? | [.document_uuid,.chapter_uuid] | @tsv' "$generation_file")}"); memo_rows=("${(@)memo_rows:#}")
conflicts=(); updates=(); documents='[]'
topic_key="$(erl_doc_attr "$topic_file" key-topic)"
[[ "$topic_key" == "$title" ]] || updates+=("$generation")
documents="$(jq -c --arg uuid "$generation" --arg path "$topic_file" --arg role topic --arg actual "$topic_key" --arg expected "$title" '.+[{uuid:$uuid,path:$path,role:$role,actual_key_topic:$actual,expected_key_topic:$expected}]' <<< "$documents")"

typeset -A chapter_keys
for chapter in "${chapters[@]}"; do
  chapter_file="$(erl_doc_path "$vault" "$chapter" 2>/dev/null)" || { conflicts+=("missing Chapter $chapter"); continue; }
  [[ "$(erl_doc_attr "$chapter_file" type)" == note ]] || conflicts+=("Chapter $chapter has wrong canonical type")
  chapter_key="$(erl_doc_attr "$chapter_file" key-topic)"; chapter_keys[$chapter]="$chapter_key"
  book_links=("${(@f)$(erl_section_links "$chapter_file" Book)}"); book_links=("${(@)book_links:#}")
  (( ${#book_links} == 1 )) && [[ "${book_links[1]}" == "$generation" ]] || conflicts+=("Chapter $chapter has conflicting Book section")
  [[ "$chapter_key" == "$title" || "$chapter_key" == "$topic_key" ]] || conflicts+=("Chapter $chapter has conflicting key-topic")
  [[ "$chapter_key" == "$title" ]] || updates+=("$chapter")
  documents="$(jq -c --arg uuid "$chapter" --arg path "$chapter_file" --arg role chapter --arg actual "$chapter_key" --arg expected "$title" '.+[{uuid:$uuid,path:$path,role:$role,actual_key_topic:$actual,expected_key_topic:$expected}]' <<< "$documents")"
done

typeset -A seen_memos
for row in "${memo_rows[@]}"; do
  memo="${row%%$'\t'*}"; chapter="${row#*$'\t'}"
  [[ -n "${chapter_keys[$chapter]+yes}" ]] || { conflicts+=("Memo $memo belongs to a Chapter outside the active source"); continue; }
  [[ -z "${seen_memos[$memo]+yes}" ]] || continue; seen_memos[$memo]=1
  memo_file="$(erl_doc_path "$vault" "$memo" 2>/dev/null)" || { conflicts+=("missing Memo $memo"); continue; }
  [[ "$(erl_doc_attr "$memo_file" type)" == memo ]] || conflicts+=("Memo $memo has wrong canonical type")
  memo_key="$(erl_doc_attr "$memo_file" key-topic)"
  chapter_links=("${(@f)$(erl_section_links "$memo_file" Chapter)}"); chapter_links=("${(@)chapter_links:#}")
  (( ${#chapter_links} == 1 )) && [[ "${chapter_links[1]}" == "$chapter" ]] || conflicts+=("Memo $memo has conflicting Chapter section")
  [[ "$memo_key" == "$title" || "$memo_key" == "${chapter_keys[$chapter]}" ]] || conflicts+=("Memo $memo has conflicting key-topic")
  [[ "$memo_key" == "$title" ]] || updates+=("$memo")
  documents="$(jq -c --arg uuid "$memo" --arg path "$memo_file" --arg role memo --arg actual "$memo_key" --arg expected "$title" '.+[{uuid:$uuid,path:$path,role:$role,actual_key_topic:$actual,expected_key_topic:$expected}]' <<< "$documents")"
done

conflicts_json="$(printf '%s\n' "${conflicts[@]}" | jq -Rsc 'split("\n")|map(select(length>0))')"
(( ${#conflicts} == 0 )) || erl_fail 30 error STATE_CONFLICT "Book title migration has user-owned conflicts" "$(jq -cn --argjson conflicts "$conflicts_json" '{conflicts:$conflicts}')"
updates_json="$(printf '%s\n' "${updates[@]}" | jq -Rsc 'split("\n")|map(select(length>0))|unique')"
data="$(jq -cn --arg work "$work_id" --arg generation "$generation" --arg title "$title" --argjson documents "$documents" --argjson updates "$updates_json" '{work_id:$work,generation_uuid:$generation,title:$title,migration:"book-title-key-topic-v1",documents:$documents,updates:$updates,document_count:($documents|length),update_count:($updates|length)}')"
(( ${#updates} > 0 )) || erl_emit ok ALREADY_CURRENT false "$data" '[]' 0
[[ "$mode" == apply ]] || erl_emit ok OK false "$data" '[]' 0

lock="$vault/.state/erl/locks/book-title-key-topic-migrate-$work_id.lock"; erl_lock_acquire "$lock"
txid="$(erl_uuid_v4)" || erl_fail 50 error IO_ERROR "Cannot generate TXID"
tx_dir="$vault/.state/erl/transactions/$txid"; mkdir -p -- "$tx_dir/backups" || erl_fail 50 error IO_ERROR "Cannot create migration journal"
tx_documents='[]'
for uuid in "${updates[@]}"; do
  file="$(jq -r --arg uuid "$uuid" '.documents[]|select(.uuid==$uuid)|.path' <<< "$data")"
  cp -- "$file" "$tx_dir/backups/$uuid.adoc" || erl_fail 50 error IO_ERROR "Cannot back up migration document: $uuid"
  tx_documents="$(jq -c --arg uuid "$uuid" --arg path "$file" --arg hash "$(erl_sha256_file "$file")" '.+[{uuid:$uuid,path:$path,pre_hash:$hash}]' <<< "$tx_documents")"
done
journal="$(jq -cn --arg txid "$txid" --arg work "$work_id" --arg generation "$generation" --argjson documents "$tx_documents" '{schema_version:1,txid:$txid,operation:"erl-book-title-key-topic-migrate",phase:"applying",work_id:$work,generation_uuid:$generation,documents:$documents}')"
print -r -- "$journal" | erl_atomic_write "$tx_dir/transaction.json" || erl_fail 50 error IO_ERROR "Cannot create migration journal"
rollback() {
  local uuid path
  while IFS=$'\t' read -r uuid path; do cp -- "$tx_dir/backups/$uuid.adoc" "$path" || true; done < <(jq -r '.documents[]|[.uuid,.path]|@tsv' "$tx_dir/transaction.json")
  jq '.phase="rolled_back"' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json" || true
}
for uuid in "${updates[@]}"; do
  file="$(jq -r --arg uuid "$uuid" '.documents[]|select(.uuid==$uuid)|.path' <<< "$data")"
  erl_replace_key_topic "$file" "$title" || { rollback; erl_fail 60 error TRANSACTION_FAILED "Cannot migrate key-topic: $uuid"; }
  tx_documents="$(jq -c --arg uuid "$uuid" --arg hash "$(erl_sha256_file "$file")" 'map(if .uuid==$uuid then .post_hash=$hash else . end)' <<< "$tx_documents")"
done
jq --argjson documents "$tx_documents" '.documents=$documents|.phase="applied"' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json" || { rollback; erl_fail 60 error TRANSACTION_FAILED "Cannot journal migrated documents"; }
if [[ "${ERL_TEST_FAIL_BOOK_TITLE_KEY_TOPIC_AFTER_MUTATION:-0}" == 1 ]]; then rollback; erl_fail 60 error TRANSACTION_FAILED "Injected Book title key-topic migration failure"; fi
if [[ "${ERL_TEST_INTERRUPT_BOOK_TITLE_KEY_TOPIC_AFTER_MUTATION:-0}" == 1 ]]; then erl_fail 60 blocked RECOVERY_REQUIRED "Injected Book title key-topic migration interruption"; fi
set +e; check="$(erl_run_check "$vault" work "$work_id")"; rc=$?; set -e
(( rc==0 )) || { rollback; erl_fail 60 error TRANSACTION_FAILED "Post-migration validation failed" "$(jq -cn --argjson check "$check" '{check:$check}')"; }
jq '.phase="committed"' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json" || { rollback; erl_fail 60 error TRANSACTION_FAILED "Cannot commit migration journal"; }
rm -rf -- "$tx_dir/backups"
erl_emit ok OK true "$(jq -c --arg txid "$txid" '.+{txid:$txid}' <<< "$data")" '[]' 0
