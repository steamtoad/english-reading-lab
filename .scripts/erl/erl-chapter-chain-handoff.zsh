#!/bin/zsh

#------------------------------------------------------------------------------
# erl-chapter-chain-handoff.zsh
# Тип: ERL CLI
# Назначение: материализовать или перестроить reciprocal Chapter-chain handoff
#------------------------------------------------------------------------------

emulate -L zsh
setopt errexit pipe_fail no_unset

script_dir="${0:A:h}"
source "$script_dir/lib/common.zsh"
ERL_COMMAND="erl-chapter-chain-handoff"; ERL_JSON_MODE=0
vault_arg="" generation="" chapter="" mode="" lock="" tmp_dir=""
trap 'erl_lock_release "$lock"; [[ -n "$tmp_dir" ]] && rm -rf -- "$tmp_dir"' EXIT HUP INT TERM

for option in "$@"; do [[ "$option" == --json ]] && ERL_JSON_MODE=1; done
while (( $# )); do
  case "$1" in
    --vault) (( $# >= 2 )) || erl_usage_error "--vault requires DIR"; vault_arg="$2"; shift 2 ;;
    --generation) (( $# >= 2 )) || erl_usage_error "--generation requires UUID"; generation="$2"; shift 2 ;;
    --chapter) (( $# >= 2 )) || erl_usage_error "--chapter requires UUID"; chapter="$2"; shift 2 ;;
    --dry-run|--apply) [[ -z "$mode" ]] || erl_usage_error "Select exactly one mode"; mode="${1#--}"; shift ;;
    --json) ERL_JSON_MODE=1; shift ;;
    --help) print -r -- "Usage: $ERL_COMMAND --vault DIR --generation UUID [--chapter UUID] (--dry-run|--apply) [--json]"; exit 0 ;;
    *) erl_usage_error "Unknown argument: $1" ;;
  esac
done
erl_require_command jq
[[ -n "$mode" ]] || erl_usage_error "Select exactly one of --dry-run or --apply"
[[ "$generation" =~ '^[0-9a-f-]{36}$' ]] || erl_usage_error "--generation must be a lowercase UUID"
[[ -z "$chapter" || "$chapter" =~ '^[0-9a-f-]{36}$' ]] || erl_usage_error "--chapter must be a lowercase UUID"
vault="$(erl_resolve_vault "$vault_arg")"
erl_validate_target_root_role "$vault"
generation_file="$(erl_find_generation_file "$vault" "$generation" 2>/dev/null)" || erl_fail 20 error NOT_FOUND "Generation not found: $generation"
source_id="$(jq -r '.source_id // empty' "$generation_file")"
source_file="$(erl_find_source_file "$vault" "$source_id" 2>/dev/null)" || erl_fail 30 error STATE_CONFLICT "Generation source is unavailable"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/erl-chapter-handoff.XXXXXX")" || erl_fail 50 error IO_ERROR "Cannot allocate handoff workspace"
: > "$tmp_dir/pairs.jsonl"; : > "$tmp_dir/conflicts.jsonl"

section_lines() {
  awk '
    $0=="== Reading handoff" {inside=1; next}
    inside && /^== / {exit}
    inside && $0 !~ /^[[:space:]]*$/ {print}
  ' "$1"
}

record_conflict() {
  jq -cn --arg document_uuid "$1" --arg reason "$2" '{document_uuid:$document_uuid,reason:$reason}' >> "$tmp_dir/conflicts.jsonl"
}

chapters=("${(@f)$(jq -r '.sequence[]?.chapter_uuid // empty' "$generation_file" | awk 'NF && !seen[$0]++')}")
[[ -z "$chapter" ]] || chapters=("$chapter")
for current in "${chapters[@]}"; do
  current_order="$(jq -r --arg uuid "$current" '.chapters[]? | select(.chapter_uuid==$uuid) | .source_order' "$source_file" | head -n 1)"
  [[ -n "$current_order" ]] || { record_conflict "$current" "Chapter is not registered in generation source"; continue; }
  nodes=("${(@f)$(jq -r --arg chapter "$current" '.sequence | map(select(.chapter_uuid==$chapter)) | sort_by(.ordinal) | .[].document_uuid' "$generation_file")}")
  [[ -n "${nodes[1]-}" ]] || nodes=()
  (( ${#nodes} > 0 )) || continue
  tail_uuid="${nodes[-1]}"
  next_uuid="$(jq -r --argjson order "$current_order" --arg source "$source_id" '[.chapters[]? | select(.source_id==$source and .source_order>$order)] | sort_by(.source_order) | .[0].chapter_uuid // empty' "$source_file")"
  [[ -n "$next_uuid" ]] || continue
  tail_file="$(erl_doc_path "$vault" "$tail_uuid" 2>/dev/null)" || { record_conflict "$tail_uuid" "Tail Memo document is missing"; continue; }
  next_file="$(erl_doc_path "$vault" "$next_uuid" 2>/dev/null)" || { record_conflict "$next_uuid" "Next Chapter document is missing"; continue; }
  needs_change=0

  # Any existing generated outgoing link within this Chapter is owned by this
  # projection and may be moved from a stale tail. Other section content blocks.
  for node_uuid in "${nodes[@]}"; do
    node_file="$(erl_doc_path "$vault" "$node_uuid" 2>/dev/null)" || continue
    lines="$(section_lines "$node_file")"
    if [[ "$node_uuid" == "$tail_uuid" ]]; then
      [[ "$lines" == "link:$next_uuid.adoc[Следующая глава]" ]] || needs_change=1
    elif [[ -n "$lines" ]]; then
      needs_change=1
    fi
    [[ -z "$lines" ]] && continue
    if [[ "$lines" =~ '^link:[0-9a-f-]{36}\.adoc\[Следующая глава\]$' ]]; then
      :
    else
      record_conflict "$node_uuid" "Conflicting Reading handoff section on Chapter Memo"
    fi
  done
  incoming="$(section_lines "$next_file")"
  [[ "$incoming" == "link:$tail_uuid.adoc[Последнее memo предыдущей главы]" ]] || needs_change=1
  if [[ -n "$incoming" && ! "$incoming" =~ '^link:[0-9a-f-]{36}\.adoc\[Последнее memo предыдущей главы\]$' ]]; then
    record_conflict "$next_uuid" "Conflicting Reading handoff section on next Chapter"
  fi
  jq -cn --arg source_id "$source_id" --arg current_chapter_uuid "$current" --arg next_chapter_uuid "$next_uuid" \
    --arg tail_memo_uuid "$tail_uuid" --argjson source_order "$current_order" --argjson nodes "$(printf '%s\n' "${nodes[@]}" | jq -R . | jq -s .)" --argjson needs_change "$needs_change" \
    '{source_id:$source_id,current_chapter_uuid:$current_chapter_uuid,next_chapter_uuid:$next_chapter_uuid,tail_memo_uuid:$tail_memo_uuid,source_order:$source_order,chapter_nodes:$nodes,needs_change:($needs_change==1)}' >> "$tmp_dir/pairs.jsonl"
done

pairs="$(jq -s 'unique_by(.current_chapter_uuid)' "$tmp_dir/pairs.jsonl")"
conflicts="$(jq -s 'unique_by(.document_uuid,.reason)' "$tmp_dir/conflicts.jsonl")"
data="$(jq -cn --arg generation_uuid "$generation" --argjson pairs "$pairs" --argjson conflicts "$conflicts" '{generation_uuid:$generation_uuid,pairs:$pairs,conflicts:$conflicts,pair_count:($pairs|length),conflict_count:($conflicts|length)}')"
[[ "$mode" == apply ]] || erl_emit ok OK false "$data" '[]' 0
[[ "$(jq length <<< "$conflicts")" == 0 ]] || erl_fail 30 blocked STATE_CONFLICT "Conflicting Reading handoff content requires user resolution" "$data"
[[ "$(jq length <<< "$pairs")" != 0 ]] || erl_emit ok NO_HANDOFF_REQUIRED false "$data" '[]' 0
mutation_pairs="$(jq '[.[] | select(.needs_change)]' <<< "$pairs")"
[[ "$(jq length <<< "$mutation_pairs")" != 0 ]] || erl_emit ok ALREADY_MATERIALIZED false "$data" '[]' 0

lock="$vault/.state/erl/locks/chapter-chain-handoff-$generation.lock"; erl_lock_acquire "$lock"
txid="$(erl_uuid_v4)" || erl_fail 50 error IO_ERROR "Cannot generate TXID"
tx_dir="$vault/.state/erl/transactions/$txid"; mkdir -p -- "$tx_dir/backups"

# Build the exact mutation set before the first write.
jq -r '.[] | .chapter_nodes[], .next_chapter_uuid' <<< "$mutation_pairs" | sort -u > "$tmp_dir/uuids"
: > "$tmp_dir/documents.jsonl"
while IFS= read -r uuid; do
  document_path="$(erl_doc_path "$vault" "$uuid" 2>/dev/null)" || erl_fail 30 error STATE_CONFLICT "Handoff document disappeared: $uuid"
  cp -- "$document_path" "$tx_dir/backups/$uuid.adoc"
  jq -cn --arg document_uuid "$uuid" --arg path "$document_path" --arg pre_hash "$(erl_sha256_file "$document_path")" '{document_uuid:$document_uuid,path:$path,pre_hash:$pre_hash}' >> "$tmp_dir/documents.jsonl"
done < "$tmp_dir/uuids"
documents="$(jq -s '.' "$tmp_dir/documents.jsonl")"
jq -cn --arg txid "$txid" --arg generation_uuid "$generation" --argjson pairs "$mutation_pairs" --argjson documents "$documents" \
  '{schema_version:1,txid:$txid,operation:"erl-chapter-chain-handoff",phase:"prepared",generation_uuid:$generation_uuid,pairs:$pairs,documents:$documents}' | erl_atomic_write "$tx_dir/transaction.json" || erl_fail 50 error IO_ERROR "Cannot write handoff transaction journal"

strip_handoff_section() {
  local file="$1" output="$2"
  awk '
    $0=="== Reading handoff" {skip=1; next}
    skip && /^== / {skip=0}
    !skip {print}
  ' "$file" > "$output"
}
replace_section() {
  local file="$1" target="$2" label="$3" rewritten="$tmp_dir/rewrite-${RANDOM}.adoc"
  strip_handoff_section "$file" "$rewritten"
  { sed -e '${/^$/d;}' "$rewritten"; print -r -- ""; print -r -- "== Reading handoff"; print -r -- ""; print -r -- "link:$target.adoc[$label]"; } > "$file"
  rm -f -- "$rewritten"
}
remove_section() {
  local file="$1" rewritten="$tmp_dir/rewrite-${RANDOM}.adoc"
  strip_handoff_section "$file" "$rewritten"; mv -- "$rewritten" "$file"
}
rollback_handoff() {
  local row uuid document_path
  for row in "${(@f)$(jq -c '.documents[]' "$tx_dir/transaction.json")}"; do
    uuid="$(jq -r .document_uuid <<< "$row")"; document_path="$(jq -r .path <<< "$row")"
    [[ -f "$tx_dir/backups/$uuid.adoc" ]] && cp -- "$tx_dir/backups/$uuid.adoc" "$document_path"
  done
  jq '.phase="rolled_back"' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json" || true
}

for pair in "${(@f)$(print -r -- "$mutation_pairs" | jq -c '.[]')}"; do
  tail_uuid="$(jq -r .tail_memo_uuid <<< "$pair")"; next_uuid="$(jq -r .next_chapter_uuid <<< "$pair")"
  for node_uuid in "${(@f)$(jq -r '.chapter_nodes[]' <<< "$pair")}"; do
    node_file="$(erl_doc_path "$vault" "$node_uuid")"
    if [[ "$node_uuid" == "$tail_uuid" ]]; then
      replace_section "$node_file" "$next_uuid" "Следующая глава"
    elif [[ -n "$(section_lines "$node_file")" ]]; then
      remove_section "$node_file"
    fi
  done
  if [[ -n "${ERL_TEST_FAIL_HANDOFF_AFTER_TAIL:-}" ]]; then rollback_handoff; erl_fail 60 error TRANSACTION_FAILED "Injected handoff failure; original bytes restored"; fi
  replace_section "$(erl_doc_path "$vault" "$next_uuid")" "$tail_uuid" "Последнее memo предыдущей главы"
done

for row in "${(@f)$(jq -c '.documents[]' "$tx_dir/transaction.json")}"; do
  uuid="$(jq -r .document_uuid <<< "$row")"; document_path="$(jq -r .path <<< "$row")"
  jq --arg uuid "$uuid" --arg hash "$(erl_sha256_file "$document_path")" '(.documents[] | select(.document_uuid==$uuid) | .post_hash)=$hash' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json" || { rollback_handoff; erl_fail 60 error TRANSACTION_FAILED "Cannot record handoff post-hash"; }
done
jq '.phase="applied"' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json"
if [[ -n "${ERL_TEST_INTERRUPT_HANDOFF:-}" ]]; then erl_fail 60 blocked RECOVERY_REQUIRED "Injected interruption; run erl-transaction-recover" "$data"; fi

jq '.phase="committed"' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json" || { rollback_handoff; erl_fail 60 error TRANSACTION_FAILED "Cannot commit handoff journal"; }
rm -rf -- "$tx_dir/backups"
data="$(jq -c --arg txid "$txid" '. + {txid:$txid}' <<< "$data")"
erl_emit ok OK true "$data" '[]' 0
