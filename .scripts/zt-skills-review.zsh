#!/bin/zsh

#------------------------------------------------------------------------------
# zt-skills-review.zsh
# Тип: Integration Maintenance
# Назначение: проверка managed skills по Git-версионируемому manifest и вывод
#------------------------------------------------------------------------------

emulate -L zsh
setopt null_glob

script_dir="${0:A:h}"
repo="${script_dir:h}"
skills_dir="${ZK_SKILLS_HOME:-$HOME/.openclaw/workspace/skills}"
manifest="${ZK_SKILLS_MANIFEST:-$script_dir/docs/managed-skills.adoc}"

fail() {
  print -ru2 -- "ERROR $1"
  exit 1
}

sha256_file() {
  local file="$1"

  if (( $+commands[shasum] )); then
    shasum -a 256 "$file" | awk '{ print $1 }'
  elif (( $+commands[sha256sum] )); then
    sha256sum "$file" | awk '{ print $1 }'
  else
    fail "neither shasum nor sha256sum is available"
  fi
}

header_is_deprecated() {
  local file="$1"

  awk '
    NR == 1 { next }
    /^[[:space:]]*$/ { exit }
    /^:deprecated:([[:space:]].*)?$/ { found = 1 }
    END { exit(found ? 0 : 1) }
  ' "$file"
}

[[ -d "$skills_dir" ]] || fail "managed skills directory not found: $skills_dir"
[[ -f "$manifest" ]] || fail "managed skills manifest not found: $manifest"

typeset -a skill_files
skill_files=("$skills_dir"/zettelkasten-*/SKILL.md)

(( ${#skill_files[@]} > 0 )) ||
  fail "managed Zettelkasten skills not found: $skills_dir/zettelkasten-*/SKILL.md"

typeset -A manifest_class manifest_script manifest_detail manifest_hash
typeset -A runtime_seen script_seen
typeset -a manifest_names

while IFS=$'\x1f' read -r name class script detail hash; do
  [[ -n "$name" ]] || continue
  [[ -z "${manifest_class[$name]-}" ]] || fail "duplicate manifest skill: $name"
  [[ "$class" == "operational" || "$class" == "meta" ]] ||
    fail "invalid manifest class for $name: $class"

  manifest_names+=("$name")
  manifest_class[$name]="$class"
  manifest_script[$name]="$script"
  manifest_detail[$name]="$detail"
  manifest_hash[$name]="$hash"
done < <(
  awk -F'|' '
    /^\|zettelkasten-/ {
      for (i = 2; i <= 6; i++) {
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i)
      }
      printf "%s\037%s\037%s\037%s\037%s\n", $2, $3, $4, $5, $6
    }
  ' "$manifest"
)

(( ${#manifest_names[@]} > 0 )) || fail "managed skills manifest has no entries: $manifest"

for f in "${skill_files[@]}"; do
  name="${f:h:t}"
  runtime_seen[$name]=1

  [[ -n "${manifest_class[$name]-}" ]] || fail "runtime skill missing from manifest: $name"

  actual_hash="$(sha256_file "$f")" || exit 1
  [[ "$actual_hash" == "${manifest_hash[$name]}" ]] ||
    fail "skill hash mismatch: $name"

  class="${manifest_class[$name]}"
  script="${manifest_script[$name]}"
  detail="${manifest_detail[$name]}"

  if [[ "$class" == "operational" ]]; then
    [[ "$script" == zt-*.zsh ]] || fail "operational skill has invalid script: $name -> $script"
    [[ -f "$repo/.scripts/$script" ]] || fail "mapped script not found: $name -> $script"
    [[ -z "${script_seen[$script]-}" ]] || fail "script mapped more than once: $script"
    script_seen[$script]="$name"

    [[ "$detail" == *.adoc && "$detail" != "-" ]] ||
      fail "operational skill has no Detailed Note: $name"
    [[ -f "$repo/notes/$detail" ]] || fail "Detailed Note not found: $name -> $detail"
    header_is_deprecated "$repo/notes/$detail" &&
      fail "Detailed Note is deprecated: $name -> $detail"
    grep -Fq -- "$detail" "$f" ||
      fail "SKILL.md does not reference manifest Detailed Note: $name"
  else
    [[ "$script" == "-" ]] || fail "meta skill must not map a top-level script: $name"
    if [[ "$detail" != "-" ]]; then
      [[ -f "$repo/notes/$detail" ]] || fail "optional Detailed Note not found: $name -> $detail"
    fi
  fi
done

for name in "${manifest_names[@]}"; do
  [[ -n "${runtime_seen[$name]-}" ]] || fail "manifest skill missing from runtime: $name"
done

for script_path in "$repo"/.scripts/zt-*.zsh; do
  script="${script_path:t}"
  [[ -n "${script_seen[$script]-}" ]] || fail "top-level script has no operational manifest skill: $script"
done

print -r -- "OK managed skills manifest: ${#manifest_names[@]} skills"
print -r -- "OK operational script mappings: ${#script_seen[@]} scripts"

for f in "${skill_files[@]}"; do
  print -r -- ""
  print -r -- "=============================================================================="
  print -r -- "FILE: ${f:h:t}/SKILL.md"
  print -r -- "=============================================================================="
  cat "$f"
done

exit 0
