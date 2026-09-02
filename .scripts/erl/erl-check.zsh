#!/bin/zsh

#------------------------------------------------------------------------------
# erl-check.zsh
# Тип: ERL CLI
# Назначение: выполнить read-only проверку согласованности Vault documents и persistent ERL state
#------------------------------------------------------------------------------

emulate -L zsh
setopt pipe_fail no_unset

script_dir="${0:A:h}"
source "$script_dir/lib/card-content.zsh"
source "$script_dir/lib/chapter-memo-chain.zsh"

readonly ERL_COMMAND="erl-check"
readonly ERL_SCHEMA_VERSION=1
readonly ERL_UUID_RE='^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
readonly ERL_UUID_V4_RE='^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
readonly ERL_FINGERPRINT_RE='^sha256:[0-9a-f]{64}$'

json_mode=0
vault=""
scope_kind="all"
scope_value=""
tmp_dir=""
diagnostics_file=""
referenced_file=""
work_index_file=""
generation_index_file=""
vocabulary_index_file=""

# Honour machine-readable mode regardless of option order, including usage errors.
for option in "$@"; do
  [[ "$option" == --json ]] && json_mode=1
done

usage() {
  print -r -- "Usage: $ERL_COMMAND [--vault DIR] [--work UUID | --generation UUID | --document UUID] [--json] [--help]"
}

cleanup() {
  [[ -n "${tmp_dir:-}" && -d "$tmp_dir" ]] && rm -rf -- "$tmp_dir"
}
trap cleanup EXIT HUP INT TERM

emit_envelope() {
  local result_status="$1" result_code="$2" exit_code="$3" data_json="${4:-}"
  [[ -n "$data_json" ]] || data_json='{}'
  local diagnostics='[]'

  if [[ -n "${diagnostics_file:-}" && -s "$diagnostics_file" ]]; then
    diagnostics="$(jq -s '.' "$diagnostics_file")" || diagnostics='[]'
  fi

  if (( json_mode )); then
    jq -n \
      --arg command "$ERL_COMMAND" \
      --arg status "$result_status" \
      --arg code "$result_code" \
      --argjson data "$data_json" \
      --argjson diagnostics "$diagnostics" \
      '{schema_version: 1, command: $command, status: $status, code: $code,
        changed: false, data: $data, diagnostics: $diagnostics}'
  else
    print -r -- "ERL check: ${(U)result_status} ($result_code)"
    print -r -- "$data_json" | jq -r '
      "Scope: \(.scope.kind // \"all\")\(if .scope.value then \" = \" + .scope.value else \"\" end)",
      "Works: \(.counts.works // 0), sources: \(.counts.sources // 0), generations: \(.counts.generations // 0), documents: \(.counts.documents // 0)",
      "Errors: \(.counts.errors // 0), warnings: \(.counts.warnings // 0)"' 2>/dev/null
    if [[ "$diagnostics" != '[]' ]]; then
      print -r -- "$diagnostics" | jq -r '.[] | "[\(.severity)] \(.code): \(.message)"'
    fi
  fi
  exit "$exit_code"
}

usage_error() {
  local message="$1"
  if (( json_mode )); then
    jq -n --arg command "$ERL_COMMAND" --arg message "$message" \
      '{schema_version:1, command:$command, status:"error", code:"INVALID_INPUT", changed:false,
        data:{}, diagnostics:[{severity:"error",code:"INVALID_INPUT",message:$message}]}'
  else
    print -ru2 -- "ERROR: $message"
    usage >&2
  fi
  exit 2
}

add_diag() {
  local severity="$1" code="$2" message="$3"
  shift 3
  local object='{}' key value
  while (( $# >= 2 )); do
    key="$1" value="$2"; shift 2
    [[ -n "$value" ]] || continue
    object="$(jq -c --arg k "$key" --arg v "$value" '. + {($k):$v}' <<< "$object")"
  done
  case "$scope_kind" in
    work)
      [[ "$(jq -r '.work_id // empty' <<< "$object")" == "$scope_value" ]] || return 0
      ;;
    generation)
      [[ "$(jq -r '.generation_uuid // empty' <<< "$object")" == "$scope_value" ]] || return 0
      ;;
    document)
      [[ "$(jq -r '.document_uuid // empty' <<< "$object")" == "$scope_value" ]] || return 0
      ;;
  esac
  jq -cn --arg severity "$severity" --arg code "$code" --arg message "$message" \
    --argjson extra "$object" '{severity:$severity,code:$code,message:$message} + $extra' >> "$diagnostics_file"
}

is_uuid() { [[ "$1" =~ $ERL_UUID_RE ]]; }
is_uuid_v4() { [[ "$1" =~ $ERL_UUID_V4_RE ]]; }

json_value() {
  local file="$1" filter="$2"
  jq -er "$filter // empty" "$file" 2>/dev/null
}

chapter_source_order() {
  local generation_file="$1" chapter_uuid="$2" source_id
  local -a source_files
  source_id="$(json_value "$generation_file" '.source_id')"
  source_files=("$works_root"/*/sources/"$source_id.json"(N))
  (( ${#source_files} == 1 )) || return 1
  jq -er --arg chapter "$chapter_uuid" '.chapters[]? | select(.chapter_uuid==$chapter) | .source_order' "$source_files[1]" 2>/dev/null | head -n 1
}

doc_path() {
  local uuid="$1"
  if [[ -f "$vault/notes/$uuid.adoc" ]]; then
    print -r -- "$vault/notes/$uuid.adoc"
  else
    return 1
  fi
}

doc_attr() {
  local file="$1" attr="$2"
  awk -v attr="$attr" '
    NR == 1 { if ($0 !~ /^= /) exit; next }
    /^[[:space:]]*$/ { exit }
    /^:[[:alnum:]_-]+:/ {
      if (index($0, ":" attr ":") == 1) {
        sub("^:" attr ":[[:space:]]*", "")
        print
        exit
      }
      next
    }
    { exit }
  ' "$file"
}

doc_is_deprecated() {
  local file="$1"
  awk '
    NR == 1 { if ($0 !~ /^= /) exit; next }
    /^[[:space:]]*$/ { exit }
    /^:deprecated:/ { found=1; exit }
    /^:[[:alnum:]_-]+:/ { next }
    { exit }
    END { exit(found ? 0 : 1) }
  ' "$file"
}

handoff_targets() {
  local file="$1" label="$2"
  awk -v label="$label" '
    $0=="== Reading handoff" {inside=1; next}
    inside && /^== / {exit}
    inside {
      pattern="^link:([0-9a-f-]{36})\\.adoc\\[" label "\\]$"
      if (match($0,pattern)) {value=$0; sub(/^link:/,"",value); sub(/\.adoc\[.*$/,"",value); print value}
    }
  ' "$file"
}

record_reference() {
  local uuid="$1" role="$2" generation="$3" chapter="$4" work_id="$5"
  [[ -n "$uuid" ]] || return 0
  jq -cn --arg uuid "$uuid" --arg role "$role" --arg generation_uuid "$generation" \
    --arg chapter_uuid "$chapter" --arg work_id "$work_id" \
    '{uuid:$uuid,role:$role,generation_uuid:$generation_uuid,chapter_uuid:$chapter_uuid,work_id:$work_id}' >> "$referenced_file"
}

check_document_common() {
  local uuid="$1" role="$2" generation="$3" chapter="$4" work_id="$5"
  local file type
  file="$(doc_path "$uuid")" || {
    if [[ "$role" == book ]]; then
      add_diag error ERL-CHECK-021 "Registered Book generation has no canonical Topic" diagnostic_kind missing_topic document_uuid "$uuid" generation_uuid "$generation" work_id "$work_id"
    else
      add_diag error ERL-CHECK-001 "Recorded Vault document does not exist" document_uuid "$uuid" generation_uuid "$generation" work_id "$work_id"
    fi
    return
  }
  type="$(doc_attr "$file" type)"

  if grep -Eq '^:erl-[[:alnum:]_-]*:' "$file"; then
    add_diag error ERL-CHECK-020 "ERL document contains forbidden :erl-* attribute" document_uuid "$uuid"
  fi

  case "$role" in
    book)
      if [[ "$type" != topic ]]; then
        add_diag error ERL-CHECK-021 "Book generation document has the wrong canonical type" diagnostic_kind wrong_type document_uuid "$uuid" generation_uuid "$generation" work_id "$work_id"
        break
      fi
      local key title description doclink expected_title work_file
      key="$(doc_attr "$file" key-topic)"
      title="$(awk 'NR==1{sub(/^= /,"");print;exit}' "$file")"
      description="$(doc_attr "$file" description)"
      doclink="$(doc_attr "$file" doclink)"
      work_file="${work_ids[$work_id]-}"
      expected_title="$(json_value "$work_file" '.title')"
      if [[ -z "$key" || "$key" == "$work_id" || -z "$expected_title" || "$title" != "$expected_title" || "$description" != "$expected_title" || "$doclink" != "link:$uuid.adoc[$expected_title]" ]]; then
        add_diag error ERL-CHECK-021 "Book Topic does not present the logical work title using the host Topic contract" diagnostic_kind wrong_presentation document_uuid "$uuid" generation_uuid "$generation" work_id "$work_id"
      fi
      ;;
    chapter)
      [[ "$type" == note ]] || add_diag error ERL-CHECK-002 "Chapter role requires canonical Note" document_uuid "$uuid"
      doc_is_deprecated "$file" && add_diag error ERL-CHECK-016 "Durable Chapter Note is deprecated" document_uuid "$uuid" work_id "$work_id"
      ;;
    vocabulary|occurrence)
      [[ "$type" == memo ]] || add_diag error ERL-CHECK-002 "${(C)role} role requires canonical Memo" document_uuid "$uuid" generation_uuid "$generation"
      if [[ -n "$chapter" ]]; then
        local chapter_file memo_key chapter_key chapter_links reciprocal_count
        chapter_file="$(doc_path "$chapter")" || chapter_file=""
        if [[ -z "$chapter_file" ]]; then
          add_diag error ERL-CHECK-028 "Memo attachment Chapter is missing" reason missing_chapter generation_uuid "$generation" chapter_uuid "$chapter" document_uuid "$uuid"
        else
          memo_key="$(doc_attr "$file" key-topic)"; chapter_key="$(doc_attr "$chapter_file" key-topic)"
          [[ -n "$memo_key" && "$memo_key" == "$chapter_key" ]] || add_diag error ERL-CHECK-028 "Memo and Chapter key-topic values differ" reason mismatched_key generation_uuid "$generation" chapter_uuid "$chapter" document_uuid "$uuid"
          chapter_links=("${(@f)$(erl_section_links "$file" Chapter)}")
          chapter_links=("${(@)chapter_links:#}")
          (( ${#chapter_links} == 1 )) && [[ "${chapter_links[1]}" == "$chapter" ]] || add_diag error ERL-CHECK-028 "Memo must contain exactly one link to its recorded Chapter" reason memo_chapter_link generation_uuid "$generation" chapter_uuid "$chapter" document_uuid "$uuid"
          reciprocal_count="$(erl_section_links "$chapter_file" Vocabulary | awk -v uuid="$uuid" '$0==uuid{n++}END{print n+0}')"
          [[ "$reciprocal_count" == 1 ]] || add_diag error ERL-CHECK-028 "Chapter must contain exactly one reciprocal Memo link" reason chapter_memo_link generation_uuid "$generation" chapter_uuid "$chapter" document_uuid "$uuid"
        fi
      fi
      ;;
    *) add_diag error ERL-CHECK-002 "Unknown recorded ERL role" document_uuid "$uuid" role "$role" ;;
  esac

  local readability_condition
  while IFS= read -r readability_condition; do
    [[ -n "$readability_condition" ]] || continue
    add_diag error ERL-CHECK-030 "ERL card content is not human-readable: $readability_condition" \
      document_uuid "$uuid" role "$role" generation_uuid "$generation" work_id "$work_id" condition "$readability_condition"
  done < <(erl_card_content_findings "$file" "$role")

  if [[ "$role" == vocabulary ]]; then
    local lemma pos lexical_type identity
    lemma="$(awk '/^== Lexical identity[[:space:]]*$/{s=1;next} s && /^== /{exit} s && /^Lemma::[[:space:]]*/{sub(/^Lemma::[[:space:]]*/,"");print;exit}' "$file")"
    pos="$(awk '/^== Lexical identity[[:space:]]*$/{s=1;next} s && /^== /{exit} s && /^POS::[[:space:]]*/{sub(/^POS::[[:space:]]*/,"");print;exit}' "$file")"
    lexical_type="$(awk '/^== Lexical identity[[:space:]]*$/{s=1;next} s && /^== /{exit} s && /^Lexical type::[[:space:]]*/{sub(/^Lexical type::[[:space:]]*/,"");print;exit}' "$file")"
    if [[ -z "$lemma" || -z "$pos" || -z "$lexical_type" ]]; then
      add_diag error ERL-CHECK-003 "Vocabulary Memo has invalid Lexical identity structure" document_uuid "$uuid"
    elif ! doc_is_deprecated "$file"; then
      identity="${(L)${lemma}//[[:space:]]##/ }|${(L)${pos}//[[:space:]]##/ }|${(L)${lexical_type}//[[:space:]]##/ }"
      print -r -- "$identity"$'\t'"$uuid" >> "$vocabulary_index_file"
    fi
  elif [[ "$role" == occurrence ]]; then
    local -a targets
    targets=("${(@f)$(awk '
      /^== Vocabulary[[:space:]]*$/ { s=1; next }
      s && /^== / { exit }
      s { line=$0; while (match(line,/link:[0-9a-f-]+\.adoc\[[^]]*\]/)) { x=substr(line,RSTART,RLENGTH); sub(/^link:/,"",x); sub(/\.adoc\[.*$/,"",x); print x; line=substr(line,RSTART+RLENGTH) } }
    ' "$file")}")
    if (( ${#targets} != 1 )) || ! awk '/^== Context[[:space:]]*$/{found=1} END{exit(found?0:1)}' "$file"; then
      add_diag error ERL-CHECK-004 "Occurrence Memo requires one Vocabulary link and a Context section" document_uuid "$uuid"
    else
      local target="${targets[1]}" target_file
      target_file="$(doc_path "$target")" || {
        add_diag error ERL-CHECK-004 "Occurrence points to missing Vocabulary" document_uuid "$uuid" target_uuid "$target" generation_uuid "$generation"
        return
      }
      if ! jq -e --arg target "$target" 'any(.[]; .uuid==$target and .role=="vocabulary")' "$tmp_dir/references.json" >/dev/null 2>&1 || [[ "$(doc_attr "$target_file" type)" != memo ]]; then
        add_diag error ERL-CHECK-005 "Active Occurrence target is not a recorded Vocabulary Memo" document_uuid "$uuid" target_uuid "$target" generation_uuid "$generation"
      fi
      if doc_is_deprecated "$target_file" && ! doc_is_deprecated "$file"; then
        add_diag warning ERL-CHECK-006 "Active Occurrence points to deprecated Vocabulary; closure is required" document_uuid "$uuid" target_uuid "$target" generation_uuid "$generation" suggested_command "erl-book-reduce.zsh --generation $generation --dry-run --json"
      fi
    fi
  fi

  if [[ -n "$chapter" ]]; then
    doc_path "$chapter" >/dev/null || add_diag error ERL-CHECK-014 "Sequence node points to missing Chapter" document_uuid "$uuid" chapter_uuid "$chapter" generation_uuid "$generation"
  fi

  if [[ -n "$generation" && "$role" != book ]]; then
    local generation_file
    generation_file="$(awk -F '\t' -v g="$generation" '$1==g{print $2;exit}' "$generation_index_file")"
    [[ -n "$generation_file" ]] || add_diag error ERL-CHECK-001 "Document references unknown generation" document_uuid "$uuid" generation_uuid "$generation"
  fi
}

# Parse options before allocating temporary resources so usage errors stay clean.
while (( $# )); do
  case "$1" in
    --vault) (( $# >= 2 )) || usage_error "--vault requires DIR"; vault="$2"; shift 2 ;;
    --work|--generation|--document)
      (( $# >= 2 )) || usage_error "$1 requires UUID"
      [[ "$scope_kind" == all ]] || usage_error "Only one scope may be selected"
      scope_kind="${1#--}"; scope_value="$2"; shift 2 ;;
    --json) json_mode=1; shift ;;
    --help) usage; exit 0 ;;
    --apply|--fix|--dry-run) usage_error "$1 is not supported by read-only erl-check" ;;
    --) shift; (( $# == 0 )) || usage_error "Unexpected positional arguments" ;;
    -*) usage_error "Unknown option: $1" ;;
    *) usage_error "Unexpected argument: $1" ;;
  esac
done

command -v jq >/dev/null 2>&1 || {
  print -ru2 -- "ERROR: jq is required"
  exit 50
}

if [[ -z "$vault" ]]; then
  vault="${ERL_VAULT:-}"
fi
if [[ -z "$vault" ]]; then
  candidate="$PWD"
  while [[ "$candidate" != / ]]; do
    if [[ -d "$candidate/notes" || -d "$candidate/.state/erl" ]]; then
      vault="$candidate"
      break
    fi
    candidate="${candidate:h}"
  done
fi
[[ -n "$vault" ]] || usage_error "Vault cannot be resolved; use --vault DIR or ERL_VAULT"
vault="${vault:A}"
[[ -d "$vault" ]] || usage_error "Vault directory does not exist: $vault"

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/erl-check.XXXXXX")" || exit 50
diagnostics_file="$tmp_dir/diagnostics.jsonl"
referenced_file="$tmp_dir/referenced.jsonl"
work_index_file="$tmp_dir/works.tsv"
generation_index_file="$tmp_dir/generations.tsv"
vocabulary_index_file="$tmp_dir/vocabulary.tsv"
: > "$diagnostics_file"; : > "$referenced_file"; : > "$work_index_file"; : > "$generation_index_file"; : > "$vocabulary_index_file"

if [[ -d "$vault/vault/notes" || -d "$vault/vault/.state/erl" ]]; then
  add_diag error HOME_LAYOUT_MIGRATION_REQUIRED \
    "Legacy nested vault/ layout detected; explicit home-layout migration is required" \
    legacy_notes "$vault/vault/notes" legacy_state "$vault/vault/.state/erl" \
    canonical_notes "$vault/notes" canonical_state "$vault/.state/erl"
fi

works_root="$vault/.state/erl/works"
transactions_root="$vault/.state/erl/transactions"

typeset -i work_count=0 source_count=0 generation_count=0 document_count=0
typeset -A work_ids generation_ids referenced_seen

# Index and validate work manifests first.
for work_file in "$works_root"/*/work.json(N); do
  (( work_count++ ))
  if ! jq -e . "$work_file" >/dev/null 2>&1; then
    add_diag error VALIDATION_FAILED "Invalid JSON work manifest" path "$work_file"
    continue
  fi
  schema="$(json_value "$work_file" '.schema_version')"
  work_id="$(json_value "$work_file" '.work_id')"
  [[ "$schema" == 1 ]] || add_diag error ERL-STATE-011 "work.json schema_version must equal 1" path "$work_file" work_id "$work_id"
  is_uuid_v4 "$work_id" || add_diag error ERL-CHECK-022 "WORK_ID must be a lowercase UUID v4" path "$work_file" work_id "$work_id"
  if [[ -n "${work_ids[$work_id]-}" ]]; then
    add_diag error ERL-CHECK-022 "WORK_ID is duplicated across work manifests" work_id "$work_id" path "$work_file"
  else
    work_ids[$work_id]="$work_file"
  fi
  print -r -- "$work_id"$'\t'"$work_file" >> "$work_index_file"
done

# Index generation files before checking cross-references.
for generation_file in "$works_root"/*/generations/*.json(N); do
  (( generation_count++ ))
  if ! jq -e . "$generation_file" >/dev/null 2>&1; then
    add_diag error VALIDATION_FAILED "Invalid JSON generation state" path "$generation_file"
    continue
  fi
  generation_uuid="$(json_value "$generation_file" '.generation_uuid // .book_topic_uuid')"
  work_id="$(json_value "$generation_file" '.work_id')"
  schema="$(json_value "$generation_file" '.schema_version')"
  [[ "$schema" == 1 ]] || add_diag error ERL-STATE-011 "Generation schema_version must equal 1" path "$generation_file" generation_uuid "$generation_uuid"
  is_uuid "$generation_uuid" || add_diag error ERL-CHECK-001 "Generation UUID has invalid format" path "$generation_file" generation_uuid "$generation_uuid"
  [[ "${generation_file:t:r}" == "$generation_uuid" ]] || add_diag error ERL-STATE-012 "Generation filename must equal Book Topic UUID" path "$generation_file" generation_uuid "$generation_uuid"
  [[ -n "${work_ids[$work_id]-}" ]] || add_diag error ERL-CHECK-001 "Generation references unknown WORK_ID" path "$generation_file" work_id "$work_id"
  print -r -- "$generation_uuid"$'\t'"$generation_file"$'\t'"$work_id" >> "$generation_index_file"
  generation_ids[$generation_uuid]="$generation_file"
  record_reference "$generation_uuid" book "$generation_uuid" "" "$work_id"
done

# Validate sources and Chapter resolution records.
for source_file in "$works_root"/*/sources/*.json(N); do
  (( source_count++ ))
  if ! jq -e . "$source_file" >/dev/null 2>&1; then
    add_diag error VALIDATION_FAILED "Invalid JSON source state" path "$source_file"
    continue
  fi
  source_id="$(json_value "$source_file" '.source_id')"
  work_id="$(json_value "$source_file" '.work_id')"
  fingerprint="$(json_value "$source_file" '.source_fingerprint // .fingerprint')"
  schema="$(json_value "$source_file" '.schema_version')"
  [[ "$schema" == 1 ]] || add_diag error ERL-STATE-011 "Source schema_version must equal 1" path "$source_file" source_id "$source_id"
  is_uuid_v4 "$source_id" || add_diag error ERL-CHECK-022 "SOURCE_ID must be a lowercase UUID v4" path "$source_file" source_id "$source_id"
  [[ "${source_file:t:r}" == "$source_id" ]] || add_diag error ERL-STATE-012 "Source filename must equal SOURCE_ID" path "$source_file" source_id "$source_id"
  [[ -n "${work_ids[$work_id]-}" ]] || add_diag error ERL-CHECK-001 "Source references unknown WORK_ID" path "$source_file" work_id "$work_id"
  [[ "$fingerprint" =~ $ERL_FINGERPRINT_RE ]] || add_diag error ERL-CHECK-012 "Source fingerprint must be sha256 plus 64 lowercase hex digits" path "$source_file" source_id "$source_id"
  jq -cr '.chapters[]? | [(.chapter_uuid // "__MISSING__"),(.source_id // "__MISSING__"),(.chapter_locator // "__MISSING__"),((.source_order // "__MISSING__")|tostring)] | @tsv' "$source_file" 2>/dev/null | while IFS=$'\t' read -r chapter_uuid chapter_source_id locator source_order; do
    [[ "$chapter_uuid" != __MISSING__ && "$chapter_source_id" != __MISSING__ && "$locator" != __MISSING__ && "$source_order" != __MISSING__ ]] || add_diag error ERL-WORKSTATE-004 "Chapter record lacks UUID, SOURCE_ID, locator, or source order" path "$source_file" source_id "$source_id"
    [[ "$chapter_source_id" == __MISSING__ || "$chapter_source_id" == "$source_id" ]] || add_diag error ERL-WORKSTATE-004 "Chapter record SOURCE_ID does not match parent source" path "$source_file" source_id "$source_id" chapter_source_id "$chapter_source_id" chapter_uuid "$chapter_uuid"
    print -r -- "$work_id"$'\t'"$source_id"$'\t'"$locator"$'\t'"$chapter_uuid" >> "$tmp_dir/chapters.tsv"
    record_reference "$chapter_uuid" chapter "" "$chapter_uuid" "$work_id"
  done
done

if [[ -f "$tmp_dir/chapters.tsv" ]]; then
  awk -F '\t' '{k=$1 FS $2 FS $3; c[k]++; u[k]=$4} END{for(k in c) if(c[k]>1) print k FS u[k]}' "$tmp_dir/chapters.tsv" | while IFS=$'\t' read -r work_id source_id locator chapter_uuid; do
    add_diag error ERL-CHECK-011 "Duplicate Chapter resolution key" work_id "$work_id" source_id "$source_id" chapter_locator "$locator" chapter_uuid "$chapter_uuid"
  done
fi

# Validate manifests against indexed generations and active pointers.
for work_file in "$works_root"/*/work.json(N); do
  jq -e . "$work_file" >/dev/null 2>&1 || continue
  work_id="$(json_value "$work_file" '.work_id')"
  active_generation="$(json_value "$work_file" '.active_generation_uuid // .active_generation')"
  retained=("${(@f)$(jq -r '.generation_uuids[]? // .generations[]? | if type=="object" then (.generation_uuid // .book_topic_uuid // empty) else . end' "$work_file" 2>/dev/null)}")
  active_count=0
  active_is_retained=0
  active_topic=""
  for generation_uuid in "${retained[@]}"; do
    [[ -n "$generation_uuid" ]] || continue
    [[ -n "${generation_ids[$generation_uuid]-}" ]] || add_diag error ERL-CHECK-001 "Work manifest references missing generation state" work_id "$work_id" generation_uuid "$generation_uuid"
    [[ "$(awk -F '\t' -v g="$generation_uuid" '$1==g{print $3;exit}' "$generation_index_file")" == "$work_id" ]] || add_diag error ERL-CHECK-001 "Generation belongs to a different WORK_ID" work_id "$work_id" generation_uuid "$generation_uuid"
    [[ "$generation_uuid" == "$active_generation" ]] && active_is_retained=1
    topic_file="$(doc_path "$generation_uuid" 2>/dev/null)" || topic_file=""
    if [[ -n "$topic_file" ]] && ! doc_is_deprecated "$topic_file"; then
      (( active_count++ ))
      active_topic="$generation_uuid"
    elif [[ -n "$topic_file" ]] && doc_is_deprecated "$topic_file"; then
      generation_file="${generation_ids[$generation_uuid]-}"
      generation_status=""
      [[ -z "$generation_file" ]] || generation_status="$(json_value "$generation_file" '.status')"
      if [[ "$generation_status" != GENERATION_CLOSED_EXTERNALLY ]]; then
        add_diag warning ERL-CHECK-023 "Deprecated Book Topic requires Classic Reduce reconciliation" work_id "$work_id" generation_uuid "$generation_uuid"
      fi
      key_topic="$(doc_attr "$topic_file" key-topic)"
      for successor_file in "$vault/notes"/*.adoc(N); do
        successor_uuid="${successor_file:t:r}"
        [[ "$successor_uuid" == "$generation_uuid" || -n "${generation_ids[$successor_uuid]-}" ]] && continue
        [[ "$(doc_attr "$successor_file" type)" == topic && "$(doc_attr "$successor_file" key-topic)" == "$key_topic" ]] || continue
        doc_is_deprecated "$successor_file" && continue
        if grep -qF -- "link:$generation_uuid.adoc[" "$successor_file" || grep -qF -- "link:$successor_uuid.adoc[" "$topic_file"; then
          add_diag warning ERL-CHECK-024 "Unregistered Classic successor Topic requires explicit adoption or close-only reconciliation" work_id "$work_id" generation_uuid "$generation_uuid" successor_uuid "$successor_uuid"
        fi
      done
    fi
  done
  (( active_count <= 1 )) || add_diag error ERL-CHECK-010 "More than one retained active Book Topic generation exists for WORK_ID" work_id "$work_id" active_generation_count "$active_count"
  if (( active_count == 1 )) && [[ -z "$active_generation" ]]; then
    add_diag error ERL-CHECK-023 "Active Book Topic exists without an active-generation pointer" work_id "$work_id" generation_uuid "$active_topic"
  fi
  if [[ -n "$active_generation" ]]; then
    (( active_is_retained == 1 )) || add_diag error ERL-CHECK-023 "Active-generation pointer is not present in retained generations" work_id "$work_id" generation_uuid "$active_generation"
    [[ -n "${generation_ids[$active_generation]-}" ]] || add_diag error ERL-CHECK-023 "Active-generation pointer references missing generation" work_id "$work_id" generation_uuid "$active_generation"
    topic_file="$(doc_path "$active_generation")" || topic_file=""
    if [[ -n "$topic_file" ]] && doc_is_deprecated "$topic_file"; then
      add_diag error ERL-CHECK-023 "Deprecated Book Topic remains the active-generation pointer" work_id "$work_id" generation_uuid "$active_generation"
    fi
  fi
done

# Every retained generation file must be registered by its owning manifest.
while IFS=$'\t' read -r generation_uuid generation_file work_id; do
  [[ -n "$generation_uuid" ]] || continue
  work_file="${work_ids[$work_id]-}"
  if [[ -z "$work_file" ]] || ! jq -e --arg generation "$generation_uuid" 'any((.generation_uuids // .generations // [])[]?; (if type=="object" then (.generation_uuid // .book_topic_uuid) else . end)==$generation)' "$work_file" >/dev/null 2>&1; then
    add_diag error ERL-BOOK-008 "Generation state is not registered by its owning work manifest" work_id "$work_id" generation_uuid "$generation_uuid" path "$generation_file"
  fi
done < "$generation_index_file"

# Validate generation sequences, receipts, and recorded documents.
for generation_file in "$works_root"/*/generations/*.json(N); do
  jq -e . "$generation_file" >/dev/null 2>&1 || continue
  generation_uuid="$(json_value "$generation_file" '.generation_uuid // .book_topic_uuid')"
  work_id="$(json_value "$generation_file" '.work_id')"
  policy="$(json_value "$generation_file" '.policy.identity // .policy_identity')"
  [[ -n "$policy" ]] || add_diag error ERL-WORKSTATE-005 "Generation lacks processing policy identity" generation_uuid "$generation_uuid" path "$generation_file"

  sequence_tsv="$tmp_dir/sequence-$generation_uuid.tsv"
  jq -cr '.sequence[]? | [((.ordinal // "")|tostring),(.chapter_uuid // ""),(.role // ""),(.document_uuid // "")] | @tsv' "$generation_file" 2>/dev/null > "$sequence_tsv"
  previous=0
  previous_source_order=0
  while IFS=$'\t' read -r ordinal chapter_uuid role document_uuid; do
    [[ -n "$ordinal$chapter_uuid$role$document_uuid" ]] || continue
    if [[ "$ordinal" != <-> || "$ordinal" -le "$previous" ]]; then
      add_diag error ERL-CHECK-013 "Sequence ordinals must be unique and strictly increasing" generation_uuid "$generation_uuid" document_uuid "$document_uuid"
    fi
    previous="${ordinal:-0}"
    chapter_source_order="$(chapter_source_order "$generation_file" "$chapter_uuid" 2>/dev/null)" || chapter_source_order=""
    if [[ -z "$chapter_source_order" ]]; then
      add_diag error ERL-CHECK-014 "Sequence Chapter is not registered in generation source" generation_uuid "$generation_uuid" chapter_uuid "$chapter_uuid"
    elif (( chapter_source_order < previous_source_order )); then
      add_diag error ERL-SEQ-004 "Sequence Chapter order moves backwards in source" generation_uuid "$generation_uuid" chapter_uuid "$chapter_uuid" source_order "$chapter_source_order"
    else
      previous_source_order="$chapter_source_order"
    fi
    [[ "$role" == vocabulary || "$role" == occurrence ]] || add_diag error ERL-CHECK-002 "Sequence role must be vocabulary or occurrence" generation_uuid "$generation_uuid" document_uuid "$document_uuid" role "$role"
    record_reference "$document_uuid" "$role" "$generation_uuid" "$chapter_uuid" "$work_id"
    file="$(doc_path "$document_uuid")" || file=""
    if [[ -n "$file" ]] && doc_is_deprecated "$file"; then
      add_diag warning ERL-CHECK-015 "Deprecated document occurs in active generation sequence; closure or reconciliation is required" generation_uuid "$generation_uuid" document_uuid "$document_uuid"
    fi
  done < "$sequence_tsv"

  # ERL-CHECK-029: project the Chapter-local tail to the adjacent Chapter Note.
  source_id="$(json_value "$generation_file" '.source_id')"
  source_matches=("$works_root"/*/sources/"$source_id.json"(N))
  (( ${#source_matches} == 1 )) && source_file="${source_matches[1]}" || source_file=""
  handoff_finalize_pending=0
  for pending_tx in "$transactions_root"/*/transaction.json(N); do
    if jq -e --arg generation "$generation_uuid" 'select(.operation=="erl-vocabulary-ingest" and .generation_uuid==$generation and (.phase=="state_updated" or .phase=="document_created" or .phase=="applying"))' "$pending_tx" >/dev/null 2>&1; then
      handoff_finalize_pending=1; break
    fi
  done
  if [[ -n "$source_file" && "$handoff_finalize_pending" == 0 ]]; then
    while IFS=$'\t' read -r current_chapter current_order current_source next_chapter next_source; do
      [[ -n "$current_chapter" ]] || continue
      nodes=("${(@f)$(jq -r --arg chapter "$current_chapter" '.sequence | map(select(.chapter_uuid==$chapter)) | sort_by(.ordinal) | .[].document_uuid' "$generation_file")}")
      [[ -n "${nodes[1]-}" ]] || nodes=()
      tail_uuid=""; (( ${#nodes} > 0 )) && tail_uuid="${nodes[-1]}"
      outgoing_count=0; outgoing_target=""; outgoing_owner=""
      for node_uuid in "${nodes[@]}"; do
        node_file="$(doc_path "$node_uuid" 2>/dev/null)" || continue
        targets=("${(@f)$(handoff_targets "$node_file" "Следующая глава")}")
        [[ -n "${targets[1]-}" ]] || targets=()
        if (( ${#targets} > 0 )); then
          outgoing_count=$((outgoing_count + ${#targets}))
          outgoing_target="${targets[1]}"; outgoing_owner="$node_uuid"
        fi
      done
      if [[ -z "$next_chapter" ]]; then
        (( outgoing_count == 0 )) || add_diag error ERL-CHECK-029 "Terminal Chapter has a stale outgoing handoff" generation_uuid "$generation_uuid" source_id "$source_id" current_chapter_uuid "$current_chapter" tail_memo_uuid "$tail_uuid"
        continue
      fi
      next_file="$(doc_path "$next_chapter" 2>/dev/null)" || next_file=""
      incoming=(); [[ -z "$next_file" ]] || incoming=("${(@f)$(handoff_targets "$next_file" "Последнее memo предыдущей главы")}")
      [[ -n "${incoming[1]-}" ]] || incoming=()
      if [[ "$current_source" != "$source_id" || "$next_source" != "$source_id" ]]; then
        add_diag error ERL-CHECK-029 "Chapter handoff crosses SOURCE_ID boundary" generation_uuid "$generation_uuid" source_id "$source_id" current_chapter_uuid "$current_chapter" next_chapter_uuid "$next_chapter" tail_memo_uuid "$tail_uuid"
        continue
      fi
      if [[ -z "$tail_uuid" ]]; then
        (( outgoing_count == 0 && ${#incoming} == 0 )) || add_diag error ERL-CHECK-029 "Chapter without a Memo Chain has a synthetic handoff" generation_uuid "$generation_uuid" source_id "$source_id" current_chapter_uuid "$current_chapter" next_chapter_uuid "$next_chapter"
      else
        (( outgoing_count == 1 )) || add_diag error ERL-CHECK-029 "Chapter tail must have exactly one outgoing handoff" generation_uuid "$generation_uuid" source_id "$source_id" current_chapter_uuid "$current_chapter" next_chapter_uuid "$next_chapter" tail_memo_uuid "$tail_uuid"
        [[ "$outgoing_owner" == "$tail_uuid" ]] || add_diag error ERL-CHECK-029 "Outgoing handoff is attached to a stale non-tail Memo" generation_uuid "$generation_uuid" source_id "$source_id" current_chapter_uuid "$current_chapter" next_chapter_uuid "$next_chapter" tail_memo_uuid "$tail_uuid" handoff_owner_uuid "$outgoing_owner"
        [[ "$outgoing_target" == "$next_chapter" ]] || add_diag error ERL-CHECK-029 "Outgoing handoff does not target the adjacent Chapter" generation_uuid "$generation_uuid" source_id "$source_id" current_chapter_uuid "$current_chapter" next_chapter_uuid "$next_chapter" tail_memo_uuid "$tail_uuid"
        (( ${#incoming} == 1 )) || add_diag error ERL-CHECK-029 "Adjacent Chapter must have exactly one reciprocal incoming handoff" generation_uuid "$generation_uuid" source_id "$source_id" current_chapter_uuid "$current_chapter" next_chapter_uuid "$next_chapter" tail_memo_uuid "$tail_uuid"
        [[ "${incoming[1]-}" == "$tail_uuid" ]] || add_diag error ERL-CHECK-029 "Incoming handoff does not target the previous Chapter tail" generation_uuid "$generation_uuid" source_id "$source_id" current_chapter_uuid "$current_chapter" next_chapter_uuid "$next_chapter" tail_memo_uuid "$tail_uuid"
      fi
    done < <(jq -r '.chapters | sort_by(.source_order) as $c | range(0; $c|length) as $i | [$c[$i].chapter_uuid,($c[$i].source_order|tostring),($c[$i].source_id // ""),($c[$i+1].chapter_uuid // ""),($c[$i+1].source_id // "")] | @tsv' "$source_file")
  fi

  # Members are persistent relationships even when not duplicated in sequence.
  jq -cr '.members[]? | [(.document_uuid // ""),(.role // "")] | @tsv' "$generation_file" 2>/dev/null | while IFS=$'\t' read -r document_uuid role; do
    if [[ -z "$document_uuid" || -z "$role" ]]; then
      add_diag error ERL-CHECK-001 "Generation member lacks document UUID or role" generation_uuid "$generation_uuid"
      continue
    fi
    [[ "$role" == vocabulary || "$role" == occurrence ]] || add_diag error ERL-CHECK-002 "Member role must be vocabulary or occurrence" generation_uuid "$generation_uuid" document_uuid "$document_uuid" role "$role"
    record_reference "$document_uuid" "$role" "$generation_uuid" "" "$work_id"
  done

  jq -r '.ingestion_receipts[]? | select(.status=="completed") | .extraction_id // empty' "$generation_file" 2>/dev/null >> "$tmp_dir/receipts.txt"
done

if [[ -f "$tmp_dir/receipts.txt" ]]; then
  sort "$tmp_dir/receipts.txt" | uniq -d | while read -r extraction_id; do
    add_diag error ERL-CHECK-019 "EXTRACTION_ID has more than one completed ingestion receipt" extraction_id "$extraction_id"
  done
  while read -r extraction_id; do
    [[ -z "$extraction_id" ]] || is_uuid_v4 "$extraction_id" || add_diag error ERL-CHECK-022 "EXTRACTION_ID must be a lowercase UUID v4" extraction_id "$extraction_id"
  done < "$tmp_dir/receipts.txt"
fi

# De-duplicate recorded documents and apply requested scope.
if [[ -s "$referenced_file" ]]; then
  jq -sc 'unique_by(.uuid + "|" + .role)' "$referenced_file" > "$tmp_dir/references.json"
else
  print -r -- '[]' > "$tmp_dir/references.json"
fi

jq -cr '.[]' "$tmp_dir/references.json" | while read -r reference; do
  uuid="$(jq -r '.uuid' <<< "$reference")"
  role="$(jq -r '.role' <<< "$reference")"
  generation_uuid="$(jq -r '.generation_uuid' <<< "$reference")"
  chapter_uuid="$(jq -r '.chapter_uuid' <<< "$reference")"
  work_id="$(jq -r '.work_id' <<< "$reference")"
  case "$scope_kind" in
    work) [[ "$work_id" == "$scope_value" ]] || continue ;;
    generation) [[ "$generation_uuid" == "$scope_value" ]] || continue ;;
    document) [[ "$uuid" == "$scope_value" ]] || continue ;;
  esac
  (( document_count++ ))
  check_document_common "$uuid" "$role" "$generation_uuid" "$chapter_uuid" "$work_id"
done

# Validate active Book Topic <-> durable Chapter bindings and source order.
for work_file in "$works_root"/*/work.json(N); do
  jq -e . "$work_file" >/dev/null 2>&1 || continue
  work_id="$(json_value "$work_file" '.work_id')"
  generation_uuid="$(json_value "$work_file" '.active_generation_uuid // .active_generation')"
  [[ -n "$generation_uuid" ]] || continue
  generation_file="${generation_ids[$generation_uuid]-}"
  [[ -n "$generation_file" && -f "$generation_file" ]] || continue
  topic_file="$(doc_path "$generation_uuid" 2>/dev/null)" || continue
  topic_key="$(doc_attr "$topic_file" key-topic)"
  source_id="$(json_value "$generation_file" '.source_id')"
  source_file="$(erl_find_source_file "$vault" "$source_id" 2>/dev/null)" || continue
  expected_chapters=("${(@f)$(jq -r '.chapters | sort_by(.source_order)[]?.chapter_uuid' "$source_file")}"); expected_chapters=("${(@)expected_chapters:#}")
  topic_chapters=("${(@f)$(erl_section_links "$topic_file" Chapters)}"); topic_chapters=("${(@)topic_chapters:#}")
  if [[ "${(j:,:)topic_chapters}" != "${(j:,:)expected_chapters}" ]]; then
    add_diag error ERL-CHECK-027 "Book Topic Chapters links must be unique and match source order" reason topic_chapter_order work_id "$work_id" generation_uuid "$generation_uuid"
  fi
  for chapter_uuid in "${expected_chapters[@]}"; do
    chapter_file="$(doc_path "$chapter_uuid" 2>/dev/null)" || { add_diag error ERL-CHECK-027 "Registered Chapter Note is missing" reason missing_chapter work_id "$work_id" generation_uuid "$generation_uuid" chapter_uuid "$chapter_uuid"; continue; }
    chapter_key="$(doc_attr "$chapter_file" key-topic)"
    [[ -n "$chapter_key" && "$chapter_key" == "$topic_key" ]] || add_diag error ERL-CHECK-027 "Chapter and active Book Topic key-topic values differ" reason mismatched_key work_id "$work_id" generation_uuid "$generation_uuid" chapter_uuid "$chapter_uuid"
    book_links=("${(@f)$(erl_section_links "$chapter_file" Book)}"); book_links=("${(@)book_links:#}")
    if (( ${#book_links} != 1 )); then
      add_diag error ERL-CHECK-027 "Chapter must have exactly one active Book Topic attachment" reason chapter_topic_count work_id "$work_id" generation_uuid "$generation_uuid" chapter_uuid "$chapter_uuid"
    elif [[ "${book_links[1]}" != "$generation_uuid" ]]; then
      add_diag error ERL-CHECK-027 "Chapter Book link does not target the active Book Topic" reason wrong_active_topic work_id "$work_id" generation_uuid "$generation_uuid" chapter_uuid "$chapter_uuid" linked_topic_uuid "${book_links[1]}"
    fi
    reciprocal_count="$(erl_section_links "$topic_file" Chapters | awk -v uuid="$chapter_uuid" '$0==uuid{n++}END{print n+0}')"
    [[ "$reciprocal_count" == 1 ]] || add_diag error ERL-CHECK-027 "Book Topic must have exactly one reciprocal Chapter link" reason topic_chapter_link work_id "$work_id" generation_uuid "$generation_uuid" chapter_uuid "$chapter_uuid"
  done
done

# Validate each Chapter-local Memo Chain against persistent sequence order.
for generation_file in "$works_root"/*/generations/*.json(N); do
  generation_uuid="$(json_value "$generation_file" '.generation_uuid // .book_topic_uuid')"
  work_id="$(json_value "$generation_file" '.work_id')"
  for chapter_uuid in "${(@f)$(jq -r '.sequence[]?.chapter_uuid // empty' "$generation_file" | sort -u)}"; do
    [[ -n "$chapter_uuid" ]] || continue
    chain_nodes=("${(@f)$(jq -r --arg chapter "$chapter_uuid" '[.sequence[]? | select(.chapter_uuid==$chapter)] | sort_by(.ordinal) | .[].document_uuid' "$generation_file")}")
    for (( chain_i=1; chain_i<=${#chain_nodes}; chain_i++ )); do
      chain_uuid="${chain_nodes[$chain_i]}"; chain_file="$(doc_path "$chain_uuid" 2>/dev/null)" || continue
      predecessors=("${(@f)$(erl_section_links "$chain_file" "Memo Chain" "Предыдущее memo")}")
      successors=("${(@f)$(erl_section_links "$chain_file" "Memo Chain" "Следующее memo")}")
      chain_edges=("${(@f)$(erl_section_links "$chain_file" "Memo Chain")}")
      predecessors=("${(@)predecessors:#}"); successors=("${(@)successors:#}"); chain_edges=("${(@)chain_edges:#}")
      expected_predecessor=""; expected_successor=""
      (( chain_i > 1 )) && expected_predecessor="${chain_nodes[$((chain_i-1))]}"
      (( chain_i < ${#chain_nodes} )) && expected_successor="${chain_nodes[$((chain_i+1))]}"
      if (( ${#predecessors} > 1 || ${#successors} > 1 || ${#chain_edges} != ${#predecessors} + ${#successors} )) || \
         [[ "${predecessors[1]-}" != "$expected_predecessor" || "${successors[1]-}" != "$expected_successor" ]]; then
        add_diag error ERL-CHECK-028 "Chapter Memo Chain is not a complete linear reciprocal projection of sequence" reason chain_topology generation_uuid "$generation_uuid" chapter_uuid "$chapter_uuid" document_uuid "$chain_uuid" expected_predecessor "$expected_predecessor" expected_successor "$expected_successor"
      fi
    done
  done
done

# Active lexical identity must be globally unique.
if [[ -s "$vocabulary_index_file" ]]; then
  sort "$vocabulary_index_file" | awk -F '\t' '{c[$1]++; u[$1]=u[$1] (u[$1]?",":"") $2} END{for(k in c)if(c[k]>1)print k "\t" u[k]}' | while IFS=$'\t' read -r identity uuids; do
    add_diag error ERL-CHECK-009 "Active canonical Vocabulary identity is duplicated" lexical_identity "$identity" document_uuids "$uuids"
  done
fi

# An unfinished transaction is a recovery blocker.
for tx_file in "$transactions_root"/*/transaction.json(N) "$transactions_root"/*/manifest.json(N); do
  jq -e . "$tx_file" >/dev/null 2>&1 || {
    add_diag error ERL-CHECK-018 "Transaction journal contains invalid JSON" path "$tx_file"
    continue
  }
  phase="$(json_value "$tx_file" '.phase // .status')"
  if [[ "$phase" != committed && "$phase" != rolled_back && "$phase" != rolled-back ]]; then
    add_diag warning ERL-CHECK-018 "Unfinished transaction requires recovery before Reduce" path "$tx_file" transaction_phase "$phase"
  elif [[ "$phase" == committed ]]; then
    operation="$(json_value "$tx_file" '.operation')"
    if [[ "$operation" == erl-book-reduce && ! -f "${tx_file:h}/result.json" ]]; then
      add_diag error ERL-CHECK-025 "Committed Book Reduce lacks compact result artifact" path "$tx_file"
    fi
    for closed_generation in "${(@f)$(jq -r '(.closed_generations // .affected_generations // [])[]?' "$tx_file" 2>/dev/null)}"; do
      [[ -n "$closed_generation" ]] || continue
      if [[ -n "${generation_ids[$closed_generation]-}" ]] || grep -lF -- "$closed_generation" "$works_root"/*/work.json(N) >/dev/null 2>&1; then
        add_diag error ERL-CHECK-025 "Committed Reduce left closed generation metadata in works/" generation_uuid "$closed_generation" path "$tx_file"
      fi
    done
  fi
done

# Validate that the requested scope exists.
case "$scope_kind" in
  work) [[ -n "${work_ids[$scope_value]-}" ]] || add_diag error NOT_FOUND "Requested WORK_ID was not found" work_id "$scope_value" ;;
  generation) [[ -n "${generation_ids[$scope_value]-}" ]] || add_diag error NOT_FOUND "Requested generation was not found" generation_uuid "$scope_value" ;;
  document)
    if ! doc_path "$scope_value" >/dev/null || ! jq -e --arg uuid "$scope_value" 'any(.[]; .uuid==$uuid)' "$tmp_dir/references.json" >/dev/null 2>&1; then
      add_diag error NOT_FOUND "Requested ERL document was not found in persistent work state" document_uuid "$scope_value"
    fi
    ;;
esac

errors="$(jq -s '[.[]|select(.severity=="error")]|length' "$diagnostics_file")"
warnings="$(jq -s '[.[]|select(.severity=="warning")]|length' "$diagnostics_file")"
data="$(jq -cn --arg vault "$vault" --arg kind "$scope_kind" --arg value "$scope_value" \
  --argjson works "$work_count" --argjson sources "$source_count" --argjson generations "$generation_count" \
  --argjson documents "$document_count" --argjson errors "$errors" --argjson warnings "$warnings" \
  '{vault:$vault,scope:({kind:$kind} + if ($value|length)>0 then {value:$value} else {} end),counts:{works:$works,sources:$sources,generations:$generations,documents:$documents,errors:$errors,warnings:$warnings}}')"

if (( errors > 0 )); then
  if jq -e 'select(.code=="NOT_FOUND")' "$diagnostics_file" >/dev/null 2>&1; then
    emit_envelope error NOT_FOUND 20 "$data"
  else
    emit_envelope error VALIDATION_FAILED 10 "$data"
  fi
elif (( warnings > 0 )); then
  if jq -e 'select(.code=="ERL-CHECK-006")' "$diagnostics_file" >/dev/null 2>&1; then
    emit_envelope warning CLOSURE_REQUIRED 0 "$data"
  elif jq -e 'select(.code=="ERL-CHECK-018")' "$diagnostics_file" >/dev/null 2>&1; then
    emit_envelope warning PENDING_TRANSACTION 0 "$data"
  elif jq -e 'select(.code=="ERL-CHECK-023" or .code=="ERL-CHECK-024")' "$diagnostics_file" >/dev/null 2>&1; then
    emit_envelope warning GENERATION_CLOSED_EXTERNALLY 0 "$data"
  else
    emit_envelope warning VALIDATION_FAILED 0 "$data"
  fi
else
  if (( work_count == 0 && source_count == 0 && generation_count == 0 && document_count == 0 )); then
    emit_envelope ok NO_CHANGES 0 "$data"
  else
    emit_envelope ok OK 0 "$data"
  fi
fi
