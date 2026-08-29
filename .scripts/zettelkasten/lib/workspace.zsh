#!/bin/zsh

#------------------------------------------------------------------------------
# workspace.zsh
# Тип: Zettelkasten Library
# Назначение: Zettelkasten policy для выбора и именования Workspace
#------------------------------------------------------------------------------

zt_workspaces_dir() {
  print -r -- "$(zk_home)/workspaces"
}


zt_workspace_link() {
  local fname="$1"
  local title="$2"

  zk_link "../notes/${fname}" "$title"
}

zt_workspace_title() {
  local file="$1"
  local title

  title="$(sed -n '1s/^= //p' "$file")"
  [[ -n "$title" ]] || title="${file:t:r}"

  print -r -- "$title"
}

zt_workspace_filename() {
  local title="$1"
  local slug

  title="${title#"${title%%[![:space:]]*}"}"
  title="${title%"${title##*[![:space:]]}"}"

  [[ -n "$title" ]] || return 1
  [[ "$title" != "." && "$title" != ".." ]] || return 1
  [[ "$title" != */* && "$title" != *\\* ]] || return 1
  [[ "$title" != .* ]] || return 1

  slug="$(print -r -- "$title" | awk '{ gsub(/[[:space:]]+/, "-"); print }')"

  [[ -n "$slug" && "$slug" != "." && "$slug" != ".." ]] || return 1
  print -r -- "${slug}.adoc"
}

zt_require_workspaces() {
  local workspaces_dir
  local -a files

  workspaces_dir="$(zt_workspaces_dir)"

  [[ -d "$workspaces_dir" ]] || {
    print -ru2 -- "ERROR workspaces not found: $workspaces_dir"
    return 1
  }

  files=("$workspaces_dir"/*.adoc(N))

  (( ${#files} > 0 )) || {
    print -ru2 -- "ERROR no workspaces found in: $workspaces_dir"
    return 1
  }
}

zt_select_workspace() {
  local prompt="${1:-workspace> }"
  local sep=$'\x1f'
  local workspaces_dir
  local file
  local title

  workspaces_dir="$(zt_workspaces_dir)"

  for file in "$workspaces_dir"/*.adoc(N); do
    [[ -f "$file" ]] || continue

    title="$(zt_workspace_title "$file")"
    print -r -- "${title} - workspaces/${file:t}${sep}${file}"
  done |
    fzf \
      --delimiter="$sep" \
      --with-nth=1 \
      --prompt="$prompt"
}
