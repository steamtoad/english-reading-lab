#!/bin/zsh

#------------------------------------------------------------------------------
# erl-chapter-export.zsh
# Тип: ERL CLI
# Назначение: экспортировать проверенный контекст Chapter и immutable policy для semantic extraction
#------------------------------------------------------------------------------

emulate -L zsh
setopt pipe_fail no_unset
script_dir="${0:A:h}"
source "$script_dir/lib/common.zsh"
source "$script_dir/lib/source.zsh"
ERL_COMMAND="erl-chapter-export"; ERL_JSON_MODE=0
vault_arg="" generation="" chapter=""
while (( $# )); do
  case "$1" in
    --vault) (( $#>=2 )) || erl_usage_error "--vault requires DIR"; vault_arg="$2"; shift 2 ;;
    --generation) (( $#>=2 )) || erl_usage_error "--generation requires UUID"; generation="$2"; shift 2 ;;
    --chapter) (( $#>=2 )) || erl_usage_error "--chapter requires UUID"; chapter="$2"; shift 2 ;;
    --json) ERL_JSON_MODE=1; shift ;;
    --help) print -- "Usage: $ERL_COMMAND --vault DIR --generation UUID --chapter UUID [--json]"; exit 0 ;;
    --dry-run|--apply|--fix) erl_usage_error "$1 is not valid for read-only $ERL_COMMAND" ;;
    *) erl_usage_error "Unknown argument: $1" ;;
  esac
done
erl_require_command jq
[[ -n "$generation" && -n "$chapter" ]] || erl_usage_error "--generation and --chapter are required"
vault="$(erl_resolve_vault "$vault_arg")"
generation_file="$(erl_find_generation_file "$vault" "$generation" 2>/dev/null)" || erl_fail 20 error NOT_FOUND "Generation not found: $generation"
[[ "$(jq -r '.status // "active"' "$generation_file")" == active ]] || erl_fail 40 blocked GENERATION_CLOSED_EXTERNALLY "Generation is not active: $generation"
work_id="$(jq -r .work_id "$generation_file")"; source_id="$(jq -r '.source_id // empty' "$generation_file")"
work_file="$(erl_find_work_file "$vault" "$work_id" 2>/dev/null)" || erl_fail 20 error NOT_FOUND "Work manifest not found: $work_id"
[[ "$(jq -r '.active_generation_uuid // empty' "$work_file")" == "$generation" ]] || erl_fail 30 error STATE_CONFLICT "Generation is not the active generation pointer"
source_file="$(erl_find_source_file "$vault" "$source_id" 2>/dev/null)" || erl_fail 20 error NOT_FOUND "Source state not found: $source_id"
chapter_row="$(jq -c --arg chapter "$chapter" '.chapters[]? | select(.chapter_uuid==$chapter)' "$source_file")"
[[ -n "$chapter_row" ]] || erl_fail 20 error NOT_FOUND "Chapter is not registered for generation source: $chapter"
chapter_doc="$(erl_doc_path "$vault" "$chapter" 2>/dev/null)" || erl_fail 20 error NOT_FOUND "Chapter Note not found: $chapter"
[[ "$(erl_doc_attr "$chapter_doc" type)" == note ]] || erl_fail 10 error VALIDATION_FAILED "Chapter UUID does not identify a canonical Note"
source_path="$(jq -r '.source_path // empty' "$source_file")"
[[ -f "$source_path" ]] || erl_fail 20 error NOT_FOUND "Local source book is unavailable: $source_path"
locator="$(jq -r .chapter_locator <<< "$chapter_row")"
content="$(erl_source_chapter_content "$source_path" "$locator")" || erl_fail 50 error IO_ERROR "Cannot extract Chapter content"
policy="$(jq -c '.policy // empty' "$generation_file")"
[[ -n "$policy" && "$policy" != null ]] || erl_fail 10 error VALIDATION_FAILED "Generation does not contain the immutable policy object"
data="$(jq -cn --arg work_id "$work_id" --arg source_id "$source_id" --arg generation_uuid "$generation" --arg chapter_uuid "$chapter" --arg locator "$locator" --argjson source_order "$(jq -r .source_order <<< "$chapter_row")" --argjson policy "$policy" --arg content "$content" '{work_id:$work_id,source_id:$source_id,generation_uuid:$generation_uuid,chapter_uuid:$chapter_uuid,chapter_locator:$locator,source_order:$source_order,policy:$policy,content:$content}')"
erl_emit ok OK false "$data" '[]' 0
