#!/bin/zsh

#------------------------------------------------------------------------------
# erl-extraction-stage.zsh
# Тип: ERL CLI
# Назначение: проверить semantic extraction, обеспечить идемпотентность и сохранить staging batch
#------------------------------------------------------------------------------

emulate -L zsh
setopt pipe_fail no_unset
script_dir="${0:A:h}"
source "$script_dir/lib/common.zsh"
ERL_COMMAND="erl-extraction-stage"; ERL_JSON_MODE=0
vault_arg="" input="" mode="" tmp_input="" lock=""
cleanup_stage() { [[ -n "$tmp_input" && -f "$tmp_input" ]] && rm -f -- "$tmp_input"; erl_lock_release "$lock"; }
trap cleanup_stage EXIT HUP INT TERM
while (( $# )); do
  case "$1" in
    --vault) (( $#>=2 )) || erl_usage_error "--vault requires DIR"; vault_arg="$2"; shift 2 ;;
    --input) (( $#>=2 )) || erl_usage_error "--input requires FILE or -"; input="$2"; shift 2 ;;
    --dry-run|--apply) [[ -z "$mode" ]] || erl_usage_error "Select exactly one mode"; mode="${1#--}"; shift ;;
    --json) ERL_JSON_MODE=1; shift ;;
    --help) print -- "Usage: $ERL_COMMAND --vault DIR --input FILE|- (--dry-run|--apply) [--json]"; exit 0 ;;
    *) erl_usage_error "Unknown argument: $1" ;;
  esac
done
erl_require_command jq
[[ -n "$mode" ]] || erl_usage_error "Select exactly one of --dry-run or --apply"
[[ -n "$input" ]] || erl_usage_error "--input is required"
if [[ "$input" == - ]]; then tmp_input="$(mktemp "${TMPDIR:-/tmp}/erl-stage.XXXXXX")"; cat > "$tmp_input"; input="$tmp_input"; fi
[[ -f "$input" ]] || erl_fail 20 error NOT_FOUND "Input file not found: $input"
erl_candidate_payload_validate "$input" || erl_fail 10 error VALIDATION_FAILED "Candidate payload does not satisfy vocabulary-candidate-v1"
vault="$(erl_resolve_vault "$vault_arg")"
generation="$(jq -r .generation_uuid "$input")"; chapter="$(jq -r .chapter_uuid "$input")"; policy_identity="$(jq -r .policy_identity "$input")"
input_source_id="$(jq -r .source_identity.source_id "$input")"; input_source_fingerprint="$(jq -r .source_identity.source_fingerprint "$input")"
generation_file="$(erl_find_generation_file "$vault" "$generation" 2>/dev/null)" || erl_fail 20 error NOT_FOUND "Generation not found: $generation"
[[ "$(jq -r '.status // "active"' "$generation_file")" == active ]] || erl_fail 40 blocked GENERATION_CLOSED_EXTERNALLY "Generation is not active"
[[ "$(jq -r '.policy.identity // .policy_identity // empty' "$generation_file")" == "$policy_identity" ]] || erl_fail 30 error STATE_CONFLICT "Policy identity does not match generation"
source_id="$(jq -r '.source_id // empty' "$generation_file")"; source_file="$(erl_find_source_file "$vault" "$source_id" 2>/dev/null)" || erl_fail 20 error NOT_FOUND "Generation source state not found"
[[ "$input_source_id" == "$source_id" ]] || erl_fail 30 error STATE_CONFLICT "Candidate source identity does not match generation source"
[[ "$input_source_fingerprint" == "$(jq -r '.source_fingerprint // empty' "$source_file")" ]] || erl_fail 30 error STATE_CONFLICT "Candidate source fingerprint does not match generation source"
jq -e --arg chapter "$chapter" 'any(.chapters[]?; .chapter_uuid==$chapter)' "$source_file" >/dev/null || erl_fail 10 error VALIDATION_FAILED "Chapter is not registered for generation source"
fingerprint="$(jq -cS '{schema_version,generation_uuid,chapter_uuid,policy_identity,source_identity,candidates}' "$input" | erl_sha256_stdin)"
existing=""
for candidate_file in "$vault/.state/erl/staging"/*.json(N); do
  [[ "$(jq -r '.extraction_fingerprint // empty' "$candidate_file" 2>/dev/null)" == "$fingerprint" ]] && { existing="$candidate_file"; break; }
done
if [[ -n "$existing" ]]; then
  data="$(jq -cn --arg extraction_id "${existing:t:r}" --arg generation_uuid "$generation" --arg chapter_uuid "$chapter" --argjson candidate_count "$(jq '.candidates|length' "$existing")" '{extraction_id:$extraction_id,generation_uuid:$generation_uuid,chapter_uuid:$chapter_uuid,candidate_count:$candidate_count}')"
  erl_emit ok ALREADY_STAGED false "$data" '[]' 0
fi
candidate_count="$(jq '.candidates|length' "$input")"
plan="$(jq -cn --arg fingerprint "$fingerprint" --arg generation_uuid "$generation" --arg chapter_uuid "$chapter" --argjson candidate_count "$candidate_count" '{extraction_id:null,extraction_fingerprint:$fingerprint,generation_uuid:$generation_uuid,chapter_uuid:$chapter_uuid,candidate_count:$candidate_count,will_generate_extraction_id:true}')"
[[ "$mode" == apply ]] || erl_emit ok OK false "$plan" '[]' 0
lock="$vault/.state/erl/locks/extraction-${generation}-${chapter}.lock"; erl_lock_acquire "$lock"
extraction_id="$(erl_uuid_v4)" || erl_fail 50 error IO_ERROR "Cannot generate EXTRACTION_ID"
staged="$(jq -cS --arg extraction_id "$extraction_id" --arg fingerprint "$fingerprint" '. + {extraction_id:$extraction_id,extraction_fingerprint:$fingerprint,status:"staged"}' "$input")"
print -r -- "$staged" | erl_atomic_write "$vault/.state/erl/staging/$extraction_id.json" || erl_fail 50 error IO_ERROR "Cannot write staging batch"
data="$(jq -cn --arg extraction_id "$extraction_id" --arg generation_uuid "$generation" --arg chapter_uuid "$chapter" --argjson candidate_count "$candidate_count" '{extraction_id:$extraction_id,generation_uuid:$generation_uuid,chapter_uuid:$chapter_uuid,candidate_count:$candidate_count}')"
erl_emit ok OK true "$data" '[]' 0
