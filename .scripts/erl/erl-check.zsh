#!/bin/zsh

#------------------------------------------------------------------------------
# erl-check.zsh
# Тип: ERL CLI
# Назначение: выполнить read-only проверку согласованности Vault documents и persistent ERL state
#------------------------------------------------------------------------------

emulate -L zsh
setopt pipe_fail no_unset

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

doc_path() {
  local uuid="$1"
  if [[ -f "$vault/notes/$uuid.adoc" ]]; then
    print -r -- "$vault/notes/$uuid.adoc"
  elif [[ -f "$vault/$uuid.adoc" ]]; then
    print -r -- "$vault/$uuid.adoc"
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
    add_diag error ERL-CHECK-001 "Recorded Vault document does not exist" document_uuid "$uuid" generation_uuid "$generation" work_id "$work_id"
    return
  }
  type="$(doc_attr "$file" type)"

  if grep -Eq '^:erl-[[:alnum:]_-]*:' "$file"; then
    add_diag error ERL-CHECK-020 "ERL document contains forbidden :erl-* attribute" document_uuid "$uuid"
  fi

  case "$role" in
    book)
      [[ "$type" == topic ]] || add_diag error ERL-CHECK-002 "Book role requires canonical Topic" document_uuid "$uuid"
      local key title description doclink expected_title
      key="$(doc_attr "$file" key-topic)"
      title="$(awk 'NR==1{sub(/^= /,"");print;exit}' "$file")"
      description="$(doc_attr "$file" description)"
      doclink="$(doc_attr "$file" doclink)"
      expected_title="$key - ключевая тема"
      if [[ -z "$key" || "$title" != "$expected_title" || "$description" != "$expected_title" || "$doclink" != "link:$uuid.adoc[$expected_title]" ]]; then
        add_diag error ERL-CHECK-021 "Book Topic violates host key-topic presentation contract" document_uuid "$uuid"
      fi
      ;;
    chapter)
      [[ "$type" == note ]] || add_diag error ERL-CHECK-002 "Chapter role requires canonical Note" document_uuid "$uuid"
      doc_is_deprecated "$file" && add_diag error ERL-CHECK-016 "Durable Chapter Note is deprecated" document_uuid "$uuid" work_id "$work_id"
      ;;
    vocabulary|occurrence)
      [[ "$type" == memo ]] || add_diag error ERL-CHECK-002 "${(C)role} role requires canonical Memo" document_uuid "$uuid" generation_uuid "$generation"
      ;;
    *) add_diag error ERL-CHECK-002 "Unknown recorded ERL role" document_uuid "$uuid" role "$role" ;;
  esac

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
    if [[ -d "$candidate/.state/erl/works" && ( -d "$candidate/notes" || -n "$(find "$candidate" -maxdepth 1 -name '*.adoc' -print -quit 2>/dev/null)" ) ]]; then
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
  jq -cr '.chapters[]? | [(.chapter_uuid // ""),(.chapter_locator // ""),((.source_order // "")|tostring)] | @tsv' "$source_file" 2>/dev/null | while IFS=$'\t' read -r chapter_uuid locator source_order; do
    [[ -n "$chapter_uuid" && -n "$locator" && -n "$source_order" ]] || add_diag error ERL-CHECK-011 "Chapter record lacks UUID, locator, or source order" path "$source_file" source_id "$source_id"
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
      for successor_file in "$vault/notes"/*.adoc(N) "$vault"/*.adoc(N); do
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
  while IFS=$'\t' read -r ordinal chapter_uuid role document_uuid; do
    [[ -n "$ordinal$chapter_uuid$role$document_uuid" ]] || continue
    if [[ "$ordinal" != <-> || "$ordinal" -le "$previous" ]]; then
      add_diag error ERL-CHECK-013 "Sequence ordinals must be unique and strictly increasing" generation_uuid "$generation_uuid" document_uuid "$document_uuid"
    fi
    previous="${ordinal:-0}"
    [[ "$role" == vocabulary || "$role" == occurrence ]] || add_diag error ERL-CHECK-002 "Sequence role must be vocabulary or occurrence" generation_uuid "$generation_uuid" document_uuid "$document_uuid" role "$role"
    record_reference "$document_uuid" "$role" "$generation_uuid" "$chapter_uuid" "$work_id"
    file="$(doc_path "$document_uuid")" || file=""
    if [[ -n "$file" ]] && doc_is_deprecated "$file"; then
      add_diag warning ERL-CHECK-015 "Deprecated document occurs in active generation sequence; closure or reconciliation is required" generation_uuid "$generation_uuid" document_uuid "$document_uuid"
    fi
  done < "$sequence_tsv"

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
