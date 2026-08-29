#!/bin/zsh

#------------------------------------------------------------------------------
# zt-workspace-remove.zsh
# Тип: Workspace
# Назначение: удаление ссылок на документы из рабочей области
#------------------------------------------------------------------------------

emulate -L zsh
setopt null_glob

script_dir="${0:A:h}"
source "$script_dir/lib/paths.zsh"
source "$script_dir/lib/asciidoc.zsh"
source "$script_dir/zettelkasten/lib/workspace.zsh"

sep=$'\x1f'

select_workspace_documents() {
  local file="$1"
  local target
  local normalized_target
  local root_file
  local type
  local description
  local state

  while IFS= read -r target; do
    [[ -n "$target" ]] || continue
    [[ "$target" == ../notes/*.adoc ]] || continue

    normalized_target="${target#../}"
    [[ "$normalized_target" == notes/*.adoc ]] || continue
    [[ "${normalized_target#notes/}" != */* ]] || continue

    root_file="$zk/$normalized_target"

    if [[ -f "$root_file" ]]; then
      type="$(zk_attr_value "$root_file" "type")"
      description="$(zk_link_description "$root_file")"

      if zk_is_deprecated "$root_file"; then
        state="deprecated"
      else
        state="$type"
      fi
    else
      description="$normalized_target"
      state="broken"
    fi

    print -r -- "${state} - ${normalized_target} - ${description}${sep}${target}${sep}${description}"
  done < <(
    awk '
      function trimmed(line) {
        sub(/^[[:space:]]+/, "", line)
        sub(/[[:space:]]+$/, "", line)
        return line
      }

      in_block {
        line = trimmed($0)

        if (block_delim == "```") {
          if (line ~ /^```/) in_block = 0
        } else if (line == block_delim) {
          in_block = 0
        }

        next
      }

      /^```/ {
        in_block = 1
        block_delim = "```"
        next
      }

      /^(----|\.{4,}|_{4,}|\*{4,}|={4,}|\+{4,}|\/{4,})[[:space:]]*$/ {
        in_block = 1
        block_delim = trimmed($0)
        next
      }

      {
        line = $0
        while (match(line, /link:[^[]+\.adoc\[/)) {
          link = substr(line, RSTART + 5, RLENGTH - 6)
          print link
          line = substr(line, RSTART + RLENGTH)
        }
      }
    ' "$file"
  ) |
    fzf \
      --multi \
      --delimiter="$sep" \
      --with-nth=1 \
      --prompt='remove documents> '
}

remove_workspace_links() {
  local file="$1"
  shift
  local -a targets=("$@")
  local serialized_targets=""
  local target
  local tmp
  local mode

  for target in "${targets[@]}"; do
    serialized_targets+="${target}${sep}"
  done

  tmp="$(mktemp "${TMPDIR:-/tmp}/zk-workspace-remove.XXXXXX")" || return 1

  if ! awk -v serialized_targets="$serialized_targets" -v sep="$sep" '
    BEGIN {
      target_count = split(serialized_targets, targets, sep)

      if (targets[target_count] == "") {
        delete targets[target_count]
        target_count--
      }
    }

    function trimmed(line) {
      sub(/^[[:space:]]+/, "", line)
      sub(/[[:space:]]+$/, "", line)
      return line
    }

    in_block {
      print
      line = trimmed($0)

      if (block_delim == "```") {
        if (line ~ /^```/) in_block = 0
      } else if (line == block_delim) {
        in_block = 0
      }

      next
    }

    /^```/ {
      in_block = 1
      block_delim = "```"
      print
      next
    }

    /^(----|\.{4,}|_{4,}|\*{4,}|={4,}|\+{4,}|\/{4,})[[:space:]]*$/ {
      in_block = 1
      block_delim = trimmed($0)
      print
      next
    }

    /^[*][[:space:]]/ {
      remove_line = 0

      for (i = 1; i <= target_count; i++) {
        if (index($0, "link:" targets[i] "[")) {
          removed[i] = 1
          remove_line = 1
        }
      }

      if (remove_line) next
    }

    { print }

    END {
      for (i = 1; i <= target_count; i++) {
        if (!removed[i]) exit 2
      }
    }
  ' "$file" > "$tmp"; then
    rm -f "$tmp"
    return 1
  fi

  if [[ "$(uname)" == "Darwin" ]]; then
    mode="$(stat -f '%Lp' "$file")" || return 1
  else
    mode="$(stat -c '%a' "$file")" || return 1
  fi

  chmod "$mode" "$tmp" || return 1
  mv "$tmp" "$file"
}

zk="$(zk_home)"
workspaces_dir="$(zt_workspaces_dir)"

zk_cd || exit 1

zt_require_workspaces || exit 1

selected_workspace="$(zt_select_workspace 'workspace> ')"
[[ -n "$selected_workspace" ]] || exit 0

selected_workspace="${selected_workspace%%$'\n'*}"
workspace_file="${selected_workspace##*$sep}"

selected_documents="$(select_workspace_documents "$workspace_file")"
[[ -n "$selected_documents" ]] || exit 0

typeset -a selected_targets
typeset -a selected_descriptions

selected_targets=()
selected_descriptions=()

while IFS= read -r selected_document; do
  [[ -n "$selected_document" ]] || continue
  target="${${selected_document#*$sep}%%$sep*}"
  description="${selected_document##*$sep}"

  selected_targets+=("$target")
  selected_descriptions+=("$description")
done <<< "$selected_documents"

(( ${#selected_targets} > 0 )) || exit 0

remove_workspace_links "$workspace_file" "${selected_targets[@]}" || exit 1

for (( i = 1; i <= ${#selected_targets}; i++ )); do
  print -r -- "Removed from workspace: link:${selected_targets[$i]}[${selected_descriptions[$i]}]"
done
