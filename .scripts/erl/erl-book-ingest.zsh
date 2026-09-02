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
source "$script_dir/lib/chapter-memo-chain.zsh"

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
topic_constructor="$(erl_host_object_command "$vault" topic-create.zsh)" || erl_fail 50 error HOST_CONTRACT_UNAVAILABLE "Target host does not provide executable .scripts/objects/topic-create.zsh"
note_constructor="$(erl_host_object_command "$vault" note-create.zsh)" || erl_fail 50 error HOST_CONTRACT_UNAVAILABLE "Target host does not provide executable .scripts/objects/note-create.zsh"
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
reuse_source=0
for candidate in "$work_dir"/sources/*.json(N); do
  [[ "$(jq -r '.source_fingerprint // empty' "$candidate")" == "$fingerprint" ]] && { existing_source="$candidate"; break; }
done
if [[ -n "$existing_source" ]]; then
  reuse_source=1
  source_id="$(jq -r .source_id "$existing_source")"
  chapter_count="$(jq '.chapters|length' "$existing_source")"
fi

plan="$(jq -cn --argjson work_id "$(if [[ -n "$work_id" ]]; then jq -cn --arg v "$work_id" '$v'; else print null; fi)" \
  --arg fingerprint "$fingerprint" --argjson chapter_count "$chapter_count" --arg work_dir "$work_dir" \
  --arg source_id "${source_id:-}" --argjson existing "$([[ -n "$work_id" ]] && print true || print false)" --argjson reuse "$reuse_source" \
  '{work_id:$work_id,source_id:(if $source_id=="" then null else $source_id end),generation_uuid:null,source_fingerprint:$fingerprint,chapter_count:$chapter_count,work_state_path:$work_dir,reuses_source:($reuse==1),will_generate_work_id:($existing|not),will_generate_source_id:($reuse!=1),will_generate_generation_uuid:true}')"
[[ "$mode" == apply ]] || erl_emit ok OK false "$plan" '[]' 0

lock="$vault/.state/erl/locks/book-ingest-${work_id:-$work_slug}.lock"
erl_lock_acquire "$lock"
tmp_tx=""; created_docs=(); modified_chapter_files=(); created_work=0; created_source_file=""; created_generation_file=""
cleanup_ingest() { erl_lock_release "$lock"; }
trap cleanup_ingest EXIT HUP INT TERM

[[ -n "$work_id" ]] || work_id="$(erl_uuid_v4)" || erl_fail 50 error IO_ERROR "Cannot generate WORK_ID"
if (( ! reuse_source )); then
  source_id="$(erl_uuid_v4)" || erl_fail 50 error IO_ERROR "Cannot generate SOURCE_ID"
fi
txid="$(erl_uuid_v4)" || erl_fail 50 error IO_ERROR "Cannot generate TXID"
tx_dir="$vault/.state/erl/transactions/$txid"
[[ -z "$existing_work_file" ]] && created_work=1
mkdir -p -- "$tx_dir/backups" "$work_dir/sources" "$work_dir/generations" || erl_fail 50 error IO_ERROR "Cannot create ERL state directories"
print -r -- "$(jq -cn --arg txid "$txid" --arg work_id "$work_id" --arg work_dir "$work_dir" --argjson created_work "$created_work" '{schema_version:1,txid:$txid,operation:"erl-book-ingest",phase:"applying",work_id:$work_id,work_dir:$work_dir,created_work:($created_work==1),created_artifacts:[]}')" | erl_atomic_write "$tx_dir/transaction.json" || erl_fail 50 error IO_ERROR "Cannot create transaction journal"

journal_created_artifact() {
  local artifact_path="$1" artifact_kind="$2"
  jq --arg path "$artifact_path" --arg kind "$artifact_kind" --arg hash "$(erl_sha256_file "$artifact_path")" '.created_artifacts += [{path:$path,kind:$kind,hash:$hash}]' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json"
}

rollback_ingest() {
  local file chapter_uuid
  for file in "${created_docs[@]}"; do rm -f -- "$file"; done
  for file in "${modified_chapter_files[@]}"; do
    chapter_uuid="${file:t:r}"
    [[ -f "$tx_dir/backups/$chapter_uuid.adoc" ]] && cp -- "$tx_dir/backups/$chapter_uuid.adoc" "$file"
  done
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

topic_title="$title"
generation_fname="$(ZK_HOME="$vault" "$topic_constructor" "$topic_title" "$key_topic" topic "$topic_title")" || { rollback_ingest; erl_fail 50 error IO_ERROR "Canonical Topic constructor failed"; }
generation_uuid="${generation_fname%.adoc}"
created_docs+=("$vault/notes/$generation_fname")
{
  print -r -- "== Book"
  print -r -- ""
  print -r -- "Title:: $(erl_json_escape_asciidoc "$title")"
  print -r -- "Reading topic:: $(erl_json_escape_asciidoc "$key_topic")"
  print -r -- ""
  print -r -- "This card is the reading hub for _$(erl_json_escape_asciidoc "$title")_."
} >> "$vault/notes/$generation_fname"
journal_created_artifact "$vault/notes/$generation_fname" document || { rollback_ingest; erl_fail 60 error TRANSACTION_FAILED "Cannot journal created Book Topic"; }
jq --arg generation_uuid "$generation_uuid" '.generation_uuid=$generation_uuid' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json" || { rollback_ingest; erl_fail 60 error TRANSACTION_FAILED "Cannot journal generation identity"; }
topic_file="$vault/notes/$generation_fname"
topic_type="$(awk '/^:type:/{sub(/^:type:[[:space:]]*/,"");print;exit}' "$topic_file")"
topic_key="$(awk '/^:key-topic:/{sub(/^:key-topic:[[:space:]]*/,"");print;exit}' "$topic_file")"
topic_visible_title="$(awk 'NR==1{sub(/^= /,"");print;exit}' "$topic_file")"
topic_description="$(awk '/^:description:/{sub(/^:description:[[:space:]]*/,"");print;exit}' "$topic_file")"
topic_doclink="$(awk '/^:doclink:/{sub(/^:doclink:[[:space:]]*/,"");print;exit}' "$topic_file")"
if [[ ! "$generation_uuid" =~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' || \
      ! -f "$topic_file" || "$topic_type" != topic || "$topic_key" != "$key_topic" || \
      "$topic_visible_title" != "$title" || "$topic_description" != "$title" || \
      "$topic_doclink" != "link:${generation_fname}[$title]" ]]; then
  rollback_ingest
  erl_fail 60 error TRANSACTION_FAILED "Created Book Topic failed post-construction validation"
fi
chapter_records=()
if (( ! reuse_source )); then
  while IFS= read -r chapter_row; do
    chapter_title="$(jq -r .title <<< "$chapter_row")"
    locator="$(jq -r .chapter_locator <<< "$chapter_row")"
    source_order="$(jq -r .source_order <<< "$chapter_row")"
    chapter_fname="$(ZK_HOME="$vault" "$note_constructor" "$chapter_title" note "$chapter_title" ":key-topic: $key_topic")" || { rollback_ingest; erl_fail 50 error IO_ERROR "Canonical Note constructor failed"; }
    chapter_uuid="${chapter_fname%.adoc}"
    created_docs+=("$vault/notes/$chapter_fname")
    {
      print -r -- "== Book"
      print -r -- ""
      print -r -- "link:$generation_uuid.adoc[$title]"
      print -r -- ""
      print -r -- "== Source"
      print -r -- ""
      print -r -- "Book:: $(erl_json_escape_asciidoc "$title")"
      print -r -- "Chapter locator:: $(erl_json_escape_asciidoc "$locator")"
    } >> "$vault/notes/$chapter_fname"
    journal_created_artifact "$vault/notes/$chapter_fname" document || { rollback_ingest; erl_fail 60 error TRANSACTION_FAILED "Cannot journal created Chapter Note"; }
    chapter_records+=("$(jq -cn --arg chapter_uuid "$chapter_uuid" --arg source_id "$source_id" --arg locator "$locator" --argjson source_order "$source_order" '{chapter_uuid:$chapter_uuid,source_id:$source_id,chapter_locator:$locator,source_order:$source_order}')")
  done < <(jq -c '.[]' <<< "$chapters")

  source_json="$(printf '%s\n' "${chapter_records[@]}" | jq -s --arg source_id "$source_id" --arg work_id "$work_id" --arg fingerprint "$fingerprint" --arg source_path "$source_file" '{schema_version:1,source_id:$source_id,work_id:$work_id,source_fingerprint:$fingerprint,source_path:$source_path,chapters:.}')"
  created_source_file="$work_dir/sources/$source_id.json"
  print -r -- "$source_json" | erl_atomic_write "$created_source_file" || { rollback_ingest; erl_fail 50 error IO_ERROR "Cannot write source state"; }
  journal_created_artifact "$created_source_file" state || { rollback_ingest; erl_fail 60 error TRANSACTION_FAILED "Cannot journal created source state"; }
else
  while IFS= read -r chapter_record; do chapter_records+=("$chapter_record"); done < <(jq -c '.chapters | sort_by(.source_order)[]' "$existing_source")
fi

topic_links_file="$tx_dir/topic-chapters.links"; : > "$topic_links_file"
modified_documents='[]'
for chapter_record in "${chapter_records[@]}"; do
  chapter_uuid="$(jq -r .chapter_uuid <<< "$chapter_record")"
  chapter_file="$vault/notes/$chapter_uuid.adoc"
  [[ -f "$chapter_file" ]] || { rollback_ingest; erl_fail 30 error STATE_CONFLICT "Durable Chapter Note is missing: $chapter_uuid"; }
  chapter_title="$(awk 'NR==1{sub(/^= /,"");print;exit}' "$chapter_file")"
  print -r -- "link:$chapter_uuid.adoc[$chapter_title]" >> "$topic_links_file"
  if (( reuse_source )); then
    current_book_links=("${(@f)$(erl_section_links "$chapter_file" Book)}"); current_book_links=("${(@)current_book_links:#}")
    if (( ${#current_book_links} > 1 )); then rollback_ingest; erl_fail 30 error STATE_CONFLICT "Durable Chapter has multiple Book Topic attachments: $chapter_uuid"; fi
    if (( ${#current_book_links} == 1 )); then
      previous_topic_file="$vault/notes/${current_book_links[1]}.adoc"
      if [[ ! -f "$previous_topic_file" || "$(erl_doc_attr "$previous_topic_file" type)" != topic || "$(erl_doc_attr "$previous_topic_file" key-topic)" != "$(erl_doc_attr "$chapter_file" key-topic)" ]]; then
        rollback_ingest; erl_fail 30 error STATE_CONFLICT "Durable Chapter has a user-owned Book section conflict: $chapter_uuid"
      fi
    fi
    cp -- "$chapter_file" "$tx_dir/backups/$chapter_uuid.adoc" || { rollback_ingest; erl_fail 50 error IO_ERROR "Cannot back up durable Chapter"; }
    modified_chapter_files+=("$chapter_file")
    modified_documents="$(jq -c --arg uuid "$chapter_uuid" --arg path "$chapter_file" --arg hash "$(erl_sha256_file "$chapter_file")" '.+[{uuid:$uuid,path:$path,pre_hash:$hash}]' <<< "$modified_documents")"
    chapter_book_links="$tx_dir/$chapter_uuid-book.links"; print -r -- "link:$generation_uuid.adoc[$title]" > "$chapter_book_links"
    erl_replace_key_topic "$chapter_file" "$topic_key" && erl_replace_section_links "$chapter_file" Book "$chapter_book_links" || { rollback_ingest; erl_fail 60 error TRANSACTION_FAILED "Cannot rebind durable Chapter to Book Topic"; }
  fi
done
erl_replace_section_links "$topic_file" Chapters "$topic_links_file" || { rollback_ingest; erl_fail 60 error TRANSACTION_FAILED "Cannot materialize Book Topic Chapter links"; }
for file in "${modified_chapter_files[@]}"; do
  chapter_uuid="${file:t:r}"
  modified_documents="$(jq -c --arg uuid "$chapter_uuid" --arg hash "$(erl_sha256_file "$file")" 'map(if .uuid==$uuid then .post_hash=$hash else . end)' <<< "$modified_documents")"
done
jq --arg path "$topic_file" --arg hash "$(erl_sha256_file "$topic_file")" --argjson modified "$modified_documents" '(.created_artifacts[] | select(.path==$path).hash)=$hash|.modified_documents=$modified|.phase="bindings_updated"' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json" || { rollback_ingest; erl_fail 60 error TRANSACTION_FAILED "Cannot journal Chapter bindings"; }
if [[ "${ERL_TEST_FAIL_BOOK_BINDING_AFTER_DOCUMENTS:-0}" == 1 ]]; then rollback_ingest; erl_fail 60 error TRANSACTION_FAILED "Injected Chapter binding failure"; fi
if [[ "${ERL_TEST_INTERRUPT_BOOK_BINDING_AFTER_DOCUMENTS:-0}" == 1 ]]; then erl_fail 60 blocked RECOVERY_REQUIRED "Injected Chapter binding interruption"; fi
generation_json="$(jq -cn --arg generation_uuid "$generation_uuid" --arg work_id "$work_id" --arg source_id "$source_id" --argjson policy "$(cat "$policy_file")" '{schema_version:1,generation_uuid:$generation_uuid,work_id:$work_id,source_id:$source_id,status:"active",policy:$policy,policy_identity:$policy.identity,sequence:[],members:[],ingestion_receipts:[]}')"
created_generation_file="$work_dir/generations/$generation_uuid.json"
print -r -- "$generation_json" | erl_atomic_write "$created_generation_file" || { rollback_ingest; erl_fail 50 error IO_ERROR "Cannot write generation state"; }
journal_created_artifact "$created_generation_file" state || { rollback_ingest; erl_fail 60 error TRANSACTION_FAILED "Cannot journal created generation state"; }
if [[ -n "$existing_work_file" ]]; then
  cp -- "$existing_work_file" "$tx_dir/backups/work.json"
  jq --arg path "$existing_work_file" --arg hash "$(erl_sha256_file "$existing_work_file")" '.work_manifest_path=$path|.work_manifest_pre_hash=$hash' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json" || { rollback_ingest; erl_fail 60 error TRANSACTION_FAILED "Cannot journal work manifest backup"; }
  jq --arg source_id "$source_id" --arg generation "$generation_uuid" '.source_ids=((.source_ids//[])+[$source_id]|unique)|.generation_uuids=((.generation_uuids//[])+[$generation]|unique)|.active_generation_uuid=$generation' "$existing_work_file" | erl_atomic_write "$existing_work_file" || { rollback_ingest; cp "$tx_dir/backups/work.json" "$existing_work_file"; erl_fail 50 error IO_ERROR "Cannot update work manifest"; }
else
  jq -cn --arg work_id "$work_id" --arg title "$title" --arg slug "${work_dir:t}" --arg source_id "$source_id" --arg generation "$generation_uuid" '{schema_version:1,work_id:$work_id,title:$title,work_slug:$slug,source_ids:[$source_id],generation_uuids:[$generation],active_generation_uuid:$generation}' | erl_atomic_write "$work_dir/work.json" || { rollback_ingest; erl_fail 50 error IO_ERROR "Cannot write work manifest"; }
  journal_created_artifact "$work_dir/work.json" state || { rollback_ingest; erl_fail 60 error TRANSACTION_FAILED "Cannot journal created work manifest"; }
fi
jq --arg generation_uuid "$generation_uuid" --arg source_id "$source_id" --arg manifest "$work_dir/work.json" --arg hash "$(erl_sha256_file "$work_dir/work.json")" '.generation_uuid=$generation_uuid|.source_id=$source_id|.work_manifest_path=$manifest|.work_manifest_post_hash=$hash|.phase="state_updated"' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json" || { rollback_ingest; erl_fail 60 error TRANSACTION_FAILED "Cannot journal updated work manifest"; }

set +e
check_output="$(erl_run_check "$vault" work "$work_id")"; check_rc=$?
set -e
if (( check_rc != 0 )); then
  rollback_ingest
  erl_fail 60 error TRANSACTION_FAILED "Post-ingest validation failed and changes were rolled back" "$(jq -cn --argjson check "$check_output" '{check:$check}')"
fi
jq --argjson docs "$(printf '%s\n' "${created_docs[@]}" | jq -Rsc 'split("\n")|map(select(length>0))')" '.phase="committed"|.created_documents=$docs' "$tx_dir/transaction.json" | erl_atomic_write "$tx_dir/transaction.json"
rm -rf -- "$tx_dir/backups"
data="$(jq -cn --arg work_id "$work_id" --arg source_id "$source_id" --arg generation_uuid "$generation_uuid" --arg fingerprint "$fingerprint" --argjson chapter_count "$chapter_count" --argjson reuse "$reuse_source" '{work_id:$work_id,source_id:$source_id,generation_uuid:$generation_uuid,source_fingerprint:$fingerprint,chapter_count:$chapter_count,reused_source:($reuse==1),created:{topics:1,notes:(if $reuse==1 then 0 else $chapter_count end)}}')"
erl_emit ok OK true "$data" '[]' 0
