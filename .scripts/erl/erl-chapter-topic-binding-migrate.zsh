#!/bin/zsh

#------------------------------------------------------------------------------
# erl-chapter-topic-binding-migrate.zsh
# Тип: ERL CLI
# Назначение: атомарно мигрировать legacy Chapter–Book Topic bindings
#------------------------------------------------------------------------------

emulate -L zsh
setopt pipe_fail no_unset
script_dir="${0:A:h}"
source "$script_dir/lib/common.zsh"
source "$script_dir/lib/chapter-memo-chain.zsh"
ERL_COMMAND="erl-chapter-topic-binding-migrate"; ERL_JSON_MODE=0
vault_arg=""; generation=""; mode=""; lock=""
trap 'erl_lock_release "$lock"' EXIT HUP INT TERM
while (( $# )); do
  case "$1" in
    --vault) (( $#>=2 )) || erl_usage_error "--vault requires DIR"; vault_arg="$2"; shift 2 ;;
    --generation) (( $#>=2 )) || erl_usage_error "--generation requires UUID"; generation="$2"; shift 2 ;;
    --dry-run|--apply) [[ -z "$mode" ]] || erl_usage_error "Select exactly one mode"; mode="${1#--}"; shift ;;
    --json) ERL_JSON_MODE=1; shift ;;
    --help) print -- "Usage: $ERL_COMMAND --vault DIR --generation UUID (--dry-run|--apply) [--json]"; exit 0 ;;
    *) erl_usage_error "Unknown argument: $1" ;;
  esac
done
erl_require_command jq
[[ -n "$mode" ]] || erl_usage_error "Select exactly one of --dry-run or --apply"
[[ "$generation" =~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' ]] || erl_usage_error "--generation must be UUID"
vault="$(erl_resolve_vault "$vault_arg")"
erl_validate_target_root_role "$vault"
generation_file="$(erl_find_generation_file "$vault" "$generation" 2>/dev/null)" || erl_fail 20 error NOT_FOUND "Generation not found: $generation"
work_id="$(jq -r .work_id "$generation_file")"; work_file="$(erl_find_work_file "$vault" "$work_id" 2>/dev/null)" || erl_fail 20 error NOT_FOUND "Work manifest not found: $work_id"
[[ "$(jq -r '.active_generation_uuid // empty' "$work_file")" == "$generation" ]] || erl_fail 30 error STATE_CONFLICT "Migration target must be the active Book generation"
topic_file="$(erl_doc_path "$vault" "$generation" 2>/dev/null)" || erl_fail 20 error NOT_FOUND "Book Topic is missing: $generation"
topic_key="$(erl_doc_attr "$topic_file" key-topic)"; [[ -n "$topic_key" ]] || erl_fail 30 error STATE_CONFLICT "Book Topic has no key-topic"
source_id="$(jq -r .source_id "$generation_file")"; source_file="$(erl_find_source_file "$vault" "$source_id" 2>/dev/null)" || erl_fail 20 error NOT_FOUND "Generation source is missing"
expected=("${(@f)$(jq -r '.chapters|sort_by(.source_order)[]?.chapter_uuid' "$source_file")}"); expected=("${(@)expected:#}")
topic_links=("${(@f)$(erl_section_links "$topic_file" Chapters)}"); topic_links=("${(@)topic_links:#}")
conflicts=(); updates=()
if (( ${#topic_links} > 0 )) && [[ "${(j:,:)topic_links}" != "${(j:,:)expected}" ]]; then conflicts+=("Book Topic has conflicting Chapters section"); fi
[[ "${(j:,:)topic_links}" == "${(j:,:)expected}" ]] || updates+=("$generation")
for chapter in "${expected[@]}"; do
  chapter_file="$(erl_doc_path "$vault" "$chapter" 2>/dev/null)" || { conflicts+=("missing Chapter $chapter"); continue; }
  chapter_key="$(erl_doc_attr "$chapter_file" key-topic)"
  book_links=("${(@f)$(erl_section_links "$chapter_file" Book)}"); book_links=("${(@)book_links:#}")
  allowed_rebind=0
  if (( ${#book_links} == 1 )) && [[ "${book_links[1]}" != "$generation" ]]; then
    previous_topic="$vault/notes/${book_links[1]}.adoc"
    [[ -f "$previous_topic" && "$(erl_doc_attr "$previous_topic" type)" == topic && "$(erl_doc_attr "$previous_topic" key-topic)" == "$chapter_key" ]] && allowed_rebind=1
  fi
  [[ -z "$chapter_key" || "$chapter_key" == "$topic_key" || $allowed_rebind == 1 ]] || conflicts+=("Chapter $chapter has conflicting key-topic")
  (( ${#book_links} == 0 )) || [[ ${#book_links} == 1 && ( "${book_links[1]}" == "$generation" || $allowed_rebind == 1 ) ]] || conflicts+=("Chapter $chapter has conflicting Book section")
  if [[ "$chapter_key" != "$topic_key" || ${#book_links} -ne 1 || "${book_links[1]-}" != "$generation" ]]; then updates+=("$chapter"); fi
done
conflicts_json="$(printf '%s\n' "${conflicts[@]}" | jq -Rsc 'split("\n")|map(select(length>0))')"
(( ${#conflicts} == 0 )) || erl_fail 30 error STATE_CONFLICT "Legacy Chapter Topic binding has user-owned conflicts" "$(jq -cn --argjson conflicts "$conflicts_json" '{conflicts:$conflicts}')"
updates_json="$(printf '%s\n' "${updates[@]}" | jq -Rsc 'split("\n")|map(select(length>0))|unique')"
data="$(jq -cn --arg generation "$generation" --argjson documents "$updates_json" '{generation_uuid:$generation,migration:"chapter-topic-binding-v1",documents:$documents,document_count:($documents|length)}')"
(( ${#updates} > 0 )) || erl_emit ok ALREADY_CURRENT false "$data" '[]' 0
[[ "$mode" == apply ]] || erl_emit ok OK false "$data" '[]' 0

lock="$vault/.state/erl/locks/chapter-topic-binding-migrate-$generation.lock"; erl_lock_acquire "$lock"
txid="$(erl_uuid_v4)" || erl_fail 50 error IO_ERROR "Cannot generate TXID"; tx_dir="$vault/.state/erl/transactions/$txid"; mkdir -p "$tx_dir/backups"
documents='[]'
for uuid in "$generation" "${expected[@]}"; do file="$vault/notes/$uuid.adoc"; cp -- "$file" "$tx_dir/backups/$uuid.adoc" || erl_fail 50 error IO_ERROR "Cannot back up binding document"; documents="$(jq -c --arg uuid "$uuid" --arg path "$file" --arg hash "$(erl_sha256_file "$file")" '.+[{uuid:$uuid,path:$path,pre_hash:$hash}]' <<< "$documents")"; done
jq -cn --arg txid "$txid" --arg generation "$generation" --argjson documents "$documents" '{schema_version:1,txid:$txid,operation:"erl-chapter-topic-binding-migrate",phase:"applying",generation_uuid:$generation,documents:$documents}' | erl_atomic_write "$tx_dir/transaction.json" || erl_fail 50 error IO_ERROR "Cannot create migration journal"
rollback() { local uuid document_path; while IFS=$'\t' read -r uuid document_path; do cp -- "$tx_dir/backups/$uuid.adoc" "$document_path"; done < <(jq -r '.documents[]|[.uuid,.path]|@tsv' "$tx_dir/transaction.json"); jq '.phase="rolled_back"' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json" || true; }
topic_links_file="$tx_dir/chapters.links"; : > "$topic_links_file"
for chapter in "${expected[@]}"; do chapter_file="$vault/notes/$chapter.adoc"; chapter_title="$(awk 'NR==1{sub(/^= /,"");print;exit}' "$chapter_file")"; print -r -- "link:$chapter.adoc[$chapter_title]" >> "$topic_links_file"; book_link_file="$tx_dir/$chapter-book.links"; topic_title="$(awk 'NR==1{sub(/^= /,"");print;exit}' "$topic_file")"; print -r -- "link:$generation.adoc[$topic_title]" > "$book_link_file"; erl_replace_key_topic "$chapter_file" "$topic_key" && erl_replace_section_links "$chapter_file" Book "$book_link_file" || { rollback; erl_fail 60 error TRANSACTION_FAILED "Cannot migrate Chapter binding"; }; done
erl_replace_section_links "$topic_file" Chapters "$topic_links_file" || { rollback; erl_fail 60 error TRANSACTION_FAILED "Cannot migrate Topic Chapters section"; }
documents="$(jq -c 'map(. + {post_hash:(.path as $p | "")})' <<< "$documents")"
for uuid in "$generation" "${expected[@]}"; do documents="$(jq -c --arg uuid "$uuid" --arg hash "$(erl_sha256_file "$vault/notes/$uuid.adoc")" 'map(if .uuid==$uuid then .post_hash=$hash else . end)' <<< "$documents")"; done
jq --argjson documents "$documents" '.documents=$documents|.phase="applied"' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json" || { rollback; erl_fail 60 error TRANSACTION_FAILED "Cannot journal migrated bindings"; }
if [[ "${ERL_TEST_INTERRUPT_CHAPTER_TOPIC_MIGRATION:-0}" == 1 ]]; then erl_fail 60 blocked RECOVERY_REQUIRED "Injected Chapter Topic migration interruption"; fi
set +e; check="$(erl_run_check "$vault" generation "$generation")"; rc=$?; set -e
(( rc==0 )) || { rollback; erl_fail 60 error TRANSACTION_FAILED "Post-migration validation failed" "$(jq -cn --argjson check "$check" '{check:$check}')"; }
jq '.phase="committed"' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json"; rm -rf -- "$tx_dir/backups"
erl_emit ok OK true "$(jq -c --arg txid "$txid" '.+{txid:$txid}' <<< "$data")" '[]' 0
