#!/bin/zsh

#------------------------------------------------------------------------------
# erl-openspec-archive-check.zsh
# Тип: ERL development check
# Назначение: проверить readiness и postconditions архивирования OpenSpec change
#------------------------------------------------------------------------------

emulate -L zsh
setopt errexit pipe_fail no_unset

repo="${0:A:h:h:h:h}"
change_name=""
archive_dir=""
phase=""

fail() {
  print -ru2 -- "FAIL: $1"
  exit "${2:-10}"
}

while (( $# )); do
  case "$1" in
    --repo) (( $# >= 2 )) || fail '--repo requires DIR' 2; repo="$2"; shift 2 ;;
    --change) (( $# >= 2 )) || fail '--change requires NAME' 2; change_name="$2"; shift 2 ;;
    --archive) (( $# >= 2 )) || fail '--archive requires DIR' 2; archive_dir="$2"; shift 2 ;;
    --pre) [[ -z "$phase" ]] || fail 'select exactly one phase' 2; phase=pre; shift ;;
    --post) [[ -z "$phase" ]] || fail 'select exactly one phase' 2; phase=post; shift ;;
    --help)
      print -- 'Usage: erl-openspec-archive-check.zsh [--repo DIR] (--pre --change NAME | --post --archive DIR)'
      exit 0
      ;;
    *) fail "unknown argument: $1" 2 ;;
  esac
done

repo="${repo:A}"
[[ -d "$repo/openspec/changes" && -d "$repo/openspec/specs" && -d "$repo/tests" ]] || fail "invalid ERL OpenSpec repository: $repo" 2
command -v rg >/dev/null 2>&1 || fail 'required command not found: rg' 2
command -v openspec >/dev/null 2>&1 || fail 'required command not found: openspec' 2

check_complete_artifacts() {
  local root="$1" artifact
  for artifact in proposal.md design.md tasks.md; do
    [[ -f "$root/$artifact" ]] || fail "missing Change artifact: $artifact"
  done
  [[ -d "$root/specs" ]] || fail 'missing Change artifact: specs/'
  rg -q '^### Requirement:' "$root/specs" --glob 'spec.md' || fail 'Change contains no delta requirements'
}

if [[ "$phase" == pre ]]; then
  [[ -n "$change_name" && -z "$archive_dir" ]] || fail 'pre phase requires --change NAME' 2
  change_root="$repo/openspec/changes/$change_name"
  [[ -d "$change_root" ]] || fail "active Change not found: $change_name"
  check_complete_artifacts "$change_root"
  rg -q '^- \[[ xX]\] [0-9]+\.[0-9]+ ' "$change_root/tasks.md" || fail 'tasks.md contains no parseable tasks'
  ! rg -q '^- \[ \] [0-9]+\.[0-9]+ ' "$change_root/tasks.md" || fail 'Change has incomplete tasks'

  behavior_slug="$(print -r -- "$change_name" | sed -E 's/^(fix|add|change|update|migrate|refactor|implement|remove)-//')"
  primary_test="$repo/tests/erl-$behavior_slug.zsh"
  [[ -f "$primary_test" && -x "$primary_test" ]] || fail "missing executable primary regression test: ${primary_test:t}"
  "$primary_test" >/dev/null || fail "primary regression test failed: ${primary_test:t}"
  if [[ "$change_name" == add-openclaw-agent-setup ]]; then
    setup_checker="$repo/.scripts/erl/dev/erl-openclaw-agent-setup.zsh"
    [[ -x "$setup_checker" ]] || fail 'OpenClaw agent setup synchronization checker is missing'
    "$setup_checker" --check-reference-skills "$repo/skills" >/dev/null || \
      fail 'embedded Lexi skills differ from reference skills'
  fi
  (cd "$repo" && openspec validate "$change_name" --strict >/dev/null) || fail "strict specification validation failed: $change_name"
  print -r -- "PASS: OpenSpec archive readiness: $change_name"
  exit 0
fi

[[ "$phase" == post ]] || fail 'select exactly one of --pre or --post' 2
[[ -n "$archive_dir" && -z "$change_name" ]] || fail 'post phase requires --archive DIR' 2
[[ "$archive_dir" == /* ]] || archive_dir="$repo/$archive_dir"
archive_dir="${archive_dir:A}"
[[ -d "$archive_dir" && "$archive_dir" == "$repo/openspec/changes/archive/"* ]] || fail "invalid ERL archive directory: $archive_dir"
check_complete_artifacts "$archive_dir"

archive_name="${archive_dir:t}"
change_name="$(print -r -- "$archive_name" | sed -E 's/^[0-9]{4}-[0-9]{2}-[0-9]{2}-//')"
[[ ! -e "$repo/openspec/changes/$change_name" ]] || fail "active Change remains after archive: $change_name"

for delta_spec in "$archive_dir/specs"/*/spec.md(N); do
  capability="${delta_spec:h:t}"
  canonical="$repo/openspec/specs/$capability/spec.md"
  [[ -f "$canonical" ]] || fail "canonical specification missing for capability: $capability"
  while IFS= read -r heading; do
    [[ -n "$heading" ]] || continue
    rg -qF "$heading" "$canonical" || fail "delta requirement is not synchronized: $heading"
  done < <(rg '^### Requirement:' "$delta_spec" --no-filename)
  while IFS= read -r scenario; do
    [[ -n "$scenario" ]] || continue
    rg -qF "$scenario" "$canonical" || fail "delta scenario is not synchronized: $scenario"
  done < <(rg '^#### Scenario:' "$delta_spec" --no-filename)
done

(cd "$repo" && openspec validate --all >/dev/null) || fail 'canonical OpenSpec baseline validation failed'
print -r -- "PASS: OpenSpec archive postconditions: $archive_name"
