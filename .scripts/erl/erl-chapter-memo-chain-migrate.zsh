#!/bin/zsh

#------------------------------------------------------------------------------
# erl-chapter-memo-chain-migrate.zsh
# Тип: ERL CLI
# Назначение: атомарно мигрировать legacy Chapter–Memo attachments и chains
#------------------------------------------------------------------------------

emulate -L zsh
setopt pipe_fail no_unset
script_dir="${0:A:h}"
source "$script_dir/lib/common.zsh"
source "$script_dir/lib/chapter-memo-chain.zsh"
ERL_COMMAND="erl-chapter-memo-chain-migrate"; ERL_JSON_MODE=0
vault_arg=""; generation=""; mode=""; lock=""
trap 'erl_lock_release "$lock"' EXIT HUP INT TERM
while (( $# )); do
  case "$1" in
    --vault) vault_arg="$2"; shift 2 ;;
    --generation) generation="$2"; shift 2 ;;
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
generation_file="$(erl_find_generation_file "$vault" "$generation" 2>/dev/null)" || erl_fail 20 error NOT_FOUND "Generation not found: $generation"

updates=(); conflicts=()
for chapter in "${(@f)$(jq -r '.sequence[]?.chapter_uuid // empty' "$generation_file" | sort -u)}"; do
  [[ -n "$chapter" ]] || continue
  chapter_file="$(erl_doc_path "$vault" "$chapter" 2>/dev/null)" || { conflicts+=("missing Chapter $chapter"); continue; }
  key="$(erl_doc_attr "$chapter_file" key-topic)"; [[ -n "$key" ]] || { conflicts+=("Chapter $chapter has no key-topic"); continue; }
  nodes=("${(@f)$(jq -r --arg chapter "$chapter" '[.sequence[]|select(.chapter_uuid==$chapter)]|sort_by(.ordinal)|.[].document_uuid' "$generation_file")}")
  for (( i=1; i<=${#nodes}; i++ )); do
    uuid="${nodes[$i]}"; file="$(erl_doc_path "$vault" "$uuid" 2>/dev/null)" || { conflicts+=("missing Memo $uuid"); continue; }
    memo_key="$(erl_doc_attr "$file" key-topic)"; [[ -z "$memo_key" || "$memo_key" == "$key" ]] || conflicts+=("Memo $uuid has conflicting key-topic")
    current_chapters=("${(@f)$(erl_section_links "$file" Chapter)}")
    current_chapters=("${(@)current_chapters:#}")
    (( ${#current_chapters} == 0 )) || { (( ${#current_chapters} == 1 )) && [[ "${current_chapters[1]}" == "$chapter" ]] || conflicts+=("Memo $uuid has conflicting Chapter section"); }
    prev=""; next=""; (( i>1 )) && prev="${nodes[$((i-1))]}"; (( i<${#nodes} )) && next="${nodes[$((i+1))]}"
    current_prev=("${(@f)$(erl_section_links "$file" "Memo Chain" "Предыдущее memo")}"); current_next=("${(@f)$(erl_section_links "$file" "Memo Chain" "Следующее memo")}")
    current_edges=("${(@f)$(erl_section_links "$file" "Memo Chain")}")
    current_prev=("${(@)current_prev:#}"); current_next=("${(@)current_next:#}"); current_edges=("${(@)current_edges:#}")
    (( ${#current_edges} == ${#current_prev} + ${#current_next} )) || conflicts+=("Memo $uuid has unsupported branch or chain link")
    (( ${#current_prev}==0 )) || [[ ${#current_prev}==1 && "${current_prev[1]}" == "$prev" ]] || conflicts+=("Memo $uuid has conflicting predecessor")
    (( ${#current_next}==0 )) || [[ ${#current_next}==1 && "${current_next[1]}" == "$next" ]] || conflicts+=("Memo $uuid has conflicting successor")
    chapter_count="$(erl_section_links "$chapter_file" Vocabulary | awk -v uuid="$uuid" '$0==uuid{n++}END{print n+0}')"
    (( chapter_count <= 1 )) || conflicts+=("Chapter $chapter has duplicate Memo link $uuid")
    if [[ -z "$memo_key" || ${#current_chapters} -eq 0 || ( -n "$prev" && ${#current_prev} -eq 0 ) || ( -n "$next" && ${#current_next} -eq 0 ) || "$chapter_count" == 0 ]]; then updates+=("$uuid"); fi
  done
done
conflicts_json="$(printf '%s\n' "${conflicts[@]}" | jq -Rsc 'split("\n")|map(select(length>0))')"
(( ${#conflicts} == 0 )) || erl_fail 30 error STATE_CONFLICT "Legacy Chapter Memo Chain has user-owned conflicts" "$(jq -cn --argjson conflicts "$conflicts_json" '{conflicts:$conflicts}')"
updates_json="$(printf '%s\n' "${updates[@]}" | jq -Rsc 'split("\n")|map(select(length>0))|unique')"
data="$(jq -cn --arg generation "$generation" --argjson documents "$updates_json" '{generation_uuid:$generation,migration:"chapter-memo-chain-v1",documents:$documents,document_count:($documents|length)}')"
(( ${#updates} > 0 )) || erl_emit ok ALREADY_CURRENT false "$data" '[]' 0
[[ "$mode" == apply ]] || erl_emit ok OK false "$data" '[]' 0

lock="$vault/.state/erl/locks/chapter-memo-chain-migrate-$generation.lock"; erl_lock_acquire "$lock"
txid="$(erl_uuid_v4)" || erl_fail 50 error IO_ERROR "Cannot generate TXID"; tx_dir="$vault/.state/erl/transactions/$txid"; mkdir -p "$tx_dir/backups"
documents='[]'
for uuid in "${(@f)$(jq -r '.[]' <<< "$updates_json")}"; do
  file="$vault/notes/$uuid.adoc"; cp -- "$file" "$tx_dir/backups/$uuid.adoc"
  documents="$(jq -c --arg uuid "$uuid" --arg path "$file" --arg hash "$(erl_sha256_file "$file")" '.+[{uuid:$uuid,path:$path,pre_hash:$hash}]' <<< "$documents")"
done
for chapter in "${(@f)$(jq -r '.sequence[]?.chapter_uuid // empty' "$generation_file" | sort -u)}"; do
  chapter_file="$vault/notes/$chapter.adoc"
  if ! jq -e --arg path "$chapter_file" 'any(.[];.path==$path)' <<< "$documents" >/dev/null; then cp -- "$chapter_file" "$tx_dir/backups/$chapter.adoc"; documents="$(jq -c --arg uuid "$chapter" --arg path "$chapter_file" --arg hash "$(erl_sha256_file "$chapter_file")" '.+[{uuid:$uuid,path:$path,pre_hash:$hash}]' <<< "$documents")"; fi
done
jq -cn --arg txid "$txid" --arg generation "$generation" --argjson documents "$documents" '{schema_version:1,txid:$txid,operation:"erl-chapter-memo-chain-migrate",phase:"applying",generation_uuid:$generation,documents:$documents}' | erl_atomic_write "$tx_dir/transaction.json" || erl_fail 50 error IO_ERROR "Cannot create migration journal"
rollback() { local row uuid document_path; while IFS=$'\t' read -r uuid document_path; do cp -- "$tx_dir/backups/$uuid.adoc" "$document_path"; done < <(jq -r '.documents[]|[.uuid,.path]|@tsv' "$tx_dir/transaction.json"); jq '.phase="rolled_back"' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json" || true; }
for chapter in "${(@f)$(jq -r '.sequence[]?.chapter_uuid // empty' "$generation_file" | sort -u)}"; do
  chapter_file="$vault/notes/$chapter.adoc"; key="$(erl_doc_attr "$chapter_file" key-topic)"; nodes=("${(@f)$(jq -r --arg chapter "$chapter" '[.sequence[]|select(.chapter_uuid==$chapter)]|sort_by(.ordinal)|.[].document_uuid' "$generation_file")}")
  for (( i=1; i<=${#nodes}; i++ )); do uuid="${nodes[$i]}"; file="$vault/notes/$uuid.adoc"; title="$(awk 'NR==1{sub(/^= /,"");print;exit}' "$file")"; chapter_title="$(awk 'NR==1{sub(/^= /,"");print;exit}' "$chapter_file")"; erl_set_missing_key_topic "$file" "$key" || { rollback; erl_fail 60 error TRANSACTION_FAILED "Cannot migrate Memo key-topic"; }; erl_append_link_to_section "$file" Chapter "$chapter" "$chapter_title"; erl_append_link_to_section "$chapter_file" Vocabulary "$uuid" "$title"; (( i>1 )) && erl_memo_chain_add_predecessor "$file" "${nodes[$((i-1))]}"; (( i<${#nodes} )) && erl_memo_chain_add_successor "$file" "${nodes[$((i+1))]}"; done
done
jq '.phase="applied"' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json"
set +e; check="$(erl_run_check "$vault" generation "$generation")"; rc=$?; set -e
(( rc==0 )) || { rollback; erl_fail 60 error TRANSACTION_FAILED "Post-migration validation failed" "$(jq -cn --argjson check "$check" '{check:$check}')"; }
jq '.phase="committed"' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json"; rm -rf -- "$tx_dir/backups"
erl_emit ok OK true "$(jq -c --arg txid "$txid" '.+{txid:$txid}' <<< "$data")" '[]' 0
