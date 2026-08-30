#!/bin/zsh

#------------------------------------------------------------------------------
# common.zsh
# Тип: ERL library
# Назначение: предоставить общие JSON, state, identity, locking, validation и atomic-write primitives
#------------------------------------------------------------------------------

erl_require_command() {
  command -v "$1" >/dev/null 2>&1 || erl_fail 50 error IO_ERROR "Required command not found: $1"
}

erl_emit() {
  local result_status="$1" code="$2" changed="$3" data diagnostics exit_code
  data="${4-}"
  diagnostics="${5-}"
  exit_code="${6:-0}"
  [[ -n "$data" ]] || data='{}'
  [[ -n "$diagnostics" ]] || diagnostics='[]'
  if (( ERL_JSON_MODE )); then
    jq -n --arg command "$ERL_COMMAND" --arg status "$result_status" --arg code "$code" \
      --argjson changed "$changed" --argjson data "$data" --argjson diagnostics "$diagnostics" \
      '{schema_version:1,command:$command,status:$status,code:$code,changed:$changed,data:$data,diagnostics:$diagnostics}'
  else
    print -r -- "${ERL_COMMAND}: ${(U)result_status} ($code)"
    [[ "$data" == '{}' ]] || print -r -- "$data" | jq .
    [[ "$diagnostics" == '[]' ]] || print -r -- "$diagnostics" | jq -r '.[] | "[\(.severity)] \(.code): \(.message)"'
  fi
  exit "$exit_code"
}

erl_fail() {
  local exit_code="$1" result_status="$2" code="$3" message="$4" data
  data="${5-}"
  [[ -n "$data" ]] || data='{}'
  local diagnostics
  diagnostics="$(jq -cn --arg severity error --arg code "$code" --arg message "$message" '[{severity:$severity,code:$code,message:$message}]')"
  erl_emit "$result_status" "$code" false "$data" "$diagnostics" "$exit_code"
}

erl_usage_error() { erl_fail 2 error INVALID_INPUT "$1"; }

erl_resolve_vault() {
  local explicit="${1:-}" candidate
  if [[ -n "$explicit" ]]; then
    candidate="$explicit"
  elif [[ -n "${ERL_VAULT:-}" ]]; then
    candidate="$ERL_VAULT"
  else
    candidate="$PWD"
    while [[ "$candidate" != / ]]; do
      if [[ -d "$candidate/notes" || -n "$(find "$candidate" -maxdepth 1 -name '*.adoc' -print -quit 2>/dev/null)" ]]; then
        break
      fi
      candidate="${candidate:h}"
    done
    [[ "$candidate" != / ]] || candidate=""
  fi
  [[ -n "$candidate" && -d "$candidate" ]] || erl_fail 20 error NOT_FOUND "Vault cannot be resolved; use --vault DIR or ERL_VAULT"
  print -r -- "${candidate:A}"
}

erl_uuid_v4() {
  local value
  if command -v uuidgen >/dev/null 2>&1; then
    value="$(uuidgen)" || return 1
  elif command -v uuid >/dev/null 2>&1; then
    value="$(uuid)" || return 1
  else
    return 1
  fi
  print -r -- "${value:l}"
}

erl_sha256_file() {
  shasum -a 256 "$1" | awk '{print "sha256:" $1}'
}

erl_sha256_stdin() {
  shasum -a 256 | awk '{print "sha256:" $1}'
}

erl_json_hash() {
  jq -cS . "$1" | erl_sha256_stdin
}

erl_atomic_write() {
  local target="$1" tmp
  mkdir -p -- "${target:h}" || return 1
  tmp="$(mktemp "${target}.tmp.XXXXXX")" || return 1
  if ! cat > "$tmp"; then
    rm -f -- "$tmp"
    return 1
  fi
  jq -e . "$tmp" >/dev/null 2>&1 || { rm -f -- "$tmp"; return 1; }
  mv -- "$tmp" "$target"
}

erl_find_work_file() {
  local vault="$1" work_id="$2" file
  for file in "$vault/.state/erl/works"/*/work.json(N); do
    [[ "$(jq -r '.work_id // empty' "$file" 2>/dev/null)" == "$work_id" ]] && { print -r -- "$file"; return 0; }
  done
  return 1
}

erl_find_generation_file() {
  local vault="$1" generation="$2" file
  for file in "$vault/.state/erl/works"/*/generations/"$generation.json"(N); do
    print -r -- "$file"
    return 0
  done
  return 1
}

erl_find_source_file() {
  local vault="$1" source_id="$2" file
  for file in "$vault/.state/erl/works"/*/sources/"$source_id.json"(N); do
    print -r -- "$file"
    return 0
  done
  return 1
}

erl_doc_path() {
  local vault="$1" uuid="$2"
  [[ -f "$vault/notes/$uuid.adoc" ]] && { print -r -- "$vault/notes/$uuid.adoc"; return 0; }
  [[ -f "$vault/$uuid.adoc" ]] && { print -r -- "$vault/$uuid.adoc"; return 0; }
  return 1
}

erl_doc_attr() {
  local file="$1" attr="$2"
  awk -v attr="$attr" 'NR==1{if($0!~/^= /)exit;next} /^[[:space:]]*$/{exit} /^:[[:alnum:]_-]+:/{if(index($0,":" attr ":")==1){sub("^:" attr ":[[:space:]]*","");print;exit}next} {exit}' "$file"
}

erl_doc_deprecated() {
  local file="$1"
  awk 'NR==1{next} /^[[:space:]]*$/{exit} /^:deprecated:/{found=1;exit} /^:[[:alnum:]_-]+:/{next} {exit} END{exit(found?0:1)}' "$file"
}

erl_deprecate_document() {
  local file="$1" tmp
  erl_doc_deprecated "$file" && return 0
  tmp="$(mktemp "${file}.tmp.XXXXXX")" || return 1
  awk 'NR==1{print;next} !done && /^:[[:alnum:]_-]+:/{print;next} !done{print ":deprecated:";done=1;print;next} {print} END{if(!done)print ":deprecated:"}' "$file" > "$tmp" || { rm -f -- "$tmp"; return 1; }
  mv -- "$tmp" "$file"
}

erl_slugify() {
  print -rn -- "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^[:alnum:]]+/-/g; s/^-+//; s/-+$//' | cut -c1-80
}

erl_lock_acquire() {
  local lock="$1"
  mkdir -p -- "${lock:h}"
  mkdir -- "$lock" 2>/dev/null || erl_fail 30 blocked STATE_CONFLICT "ERL operation is already locked: $lock"
}

erl_lock_release() { [[ -n "${1:-}" && -d "$1" ]] && rmdir -- "$1" 2>/dev/null || true; }

erl_policy_validate() {
  local file="$1" declared calculated
  jq -e 'type=="object" and .schema_version==1 and (.identity|test("^sha256:[0-9a-f]{64}$")) and (.threshold|type=="array" and length>0) and (.lexical_types|type=="array" and length>0)' "$file" >/dev/null 2>&1 || return 1
  declared="$(jq -r '.identity' "$file")"
  calculated="$(jq -cS 'del(.identity)' "$file" | erl_sha256_stdin)"
  [[ "$declared" == "$calculated" ]]
}

erl_candidate_payload_validate() {
  local file="$1"
  jq -e '
    def exact_keys($expected):
      ((keys - $expected) | length) == 0 and (($expected - keys) | length) == 0;
    def nonempty_strings:
      type=="array" and all(.[]; type=="string" and length>0);
    def object_array:
      type=="array" and all(.[]; type=="object");

    .schema_version==1 and (.generation_uuid|type=="string") and (.chapter_uuid|type=="string") and
    (.policy_identity|test("^sha256:[0-9a-f]{64}$")) and (.candidates|type=="array") and
    all(.candidates[];
      exact_keys(["ordinal","surface_form","lemma","pos","lexical_type","candidate_confidence","first_relevant_occurrence","context","enrichment"]) and
      (.ordinal|type=="number" and .>=1 and floor==.) and
      ([.surface_form,.lemma,.pos,.lexical_type,.context,.first_relevant_occurrence.text]|all(type=="string" and length>0)) and
      (.first_relevant_occurrence|type=="object") and
      (.candidate_confidence|type=="number" and .>=0 and .<=1) and
      (.lexical_type|IN("word","phrase","phrasal_verb","idiom","collocation","fixed_expression")) and
      (.enrichment|type=="object") and
      (.enrichment|exact_keys(["ipa","translation_ru","definition_en","sense_gloss","cefr","register","rarity","labels","semantic_relations","collocations"])) and
      (.enrichment.cefr|type=="object" and exact_keys(["value","confidence","provenance"])) and
      (.enrichment.cefr.value|IN("A1","A2","B1","B2","C1","C2")) and
      (.enrichment.cefr.confidence|type=="number" and .>=0 and .<=1) and
      (.enrichment.cefr.provenance|type=="string" and length>0) and
      (.enrichment.ipa|type=="string") and
      (.enrichment.translation_ru|nonempty_strings and length>0) and
      (.enrichment.definition_en|type=="string" and length>0) and
      (.enrichment.sense_gloss|type=="string" and length>0) and
      (.enrichment.register|nonempty_strings) and
      (.enrichment.rarity|type=="string") and
      (.enrichment.labels|nonempty_strings and ((length) == (unique|length))) and
      (.enrichment.semantic_relations|object_array) and
      (.enrichment.collocations|object_array)
    ) and
    (([.candidates[].ordinal]|length) == ([.candidates[].ordinal]|unique|length)) and
    ([.candidates[].ordinal] == ([.candidates[].ordinal]|sort))
  ' "$file" >/dev/null 2>&1
}

erl_extraction_file() {
  local vault="$1" extraction_id="$2" file
  file="$vault/.state/erl/staging/$extraction_id.json"
  [[ -f "$file" ]] || return 1
  print -r -- "$file"
}

erl_normalize_identity() {
  jq -cn --arg lemma "$1" --arg pos "$2" --arg lexical_type "$3" \
    '{lemma:($lemma|gsub("\\s+";" ")|ascii_downcase),pos:($pos|gsub("\\s+";" ")|ascii_downcase),lexical_type:($lexical_type|gsub("\\s+";"_")|ascii_downcase)}'
}

erl_identity_key() { print -r -- "$1" | jq -r '[.lemma,.pos,.lexical_type]|join("|")'; }

erl_run_check() {
  local vault="$1" scope_kind="${2:-}" scope_value="${3:-}" checker="${ERL_LIB_DIR:h}/erl-check.zsh"
  local -a args=(--vault "$vault" --json)
  [[ -n "$scope_kind" ]] && args+=("--$scope_kind" "$scope_value")
  "$checker" "${args[@]}"
}

erl_json_escape_asciidoc() {
  print -r -- "$1" | tr '\r\n' '  '
}

typeset -gr ERL_LIB_DIR="${${(%):-%N}:A:h}"
