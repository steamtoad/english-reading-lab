#!/bin/zsh

#------------------------------------------------------------------------------
# zt-workspace-add.zsh
# Тип: Workspace
# Назначение: добавление выбранных документов в рабочую область
#------------------------------------------------------------------------------

emulate -L zsh
setopt null_glob

script_dir="${0:A:h}"
source "$script_dir/lib/paths.zsh"
source "$script_dir/lib/asciidoc.zsh"
source "$script_dir/zettelkasten/lib/workspace.zsh"

sep=$'\x1f'

select_documents() {
  local file
  local type
  local description

  for file in "$(zk_notes_dir)"/*.adoc; do
    [[ -f "$file" ]] || continue
    zk_is_deprecated "$file" && continue

    type="$(zk_attr_value "$file" "type")"

    case "$type" in
      note|memo|todo|topic|diary) ;;
      *) continue ;;
    esac

    description="$(zk_link_description "$file")"
    print -r -- "${type} - ${file:t} - ${description}${sep}${file:t}${sep}${description}"
  done |
    fzf \
      --multi \
      --delimiter="$sep" \
      --with-nth=1 \
      --prompt='add documents> '
}

zk_cd || exit 1

zt_require_workspaces || exit 1

selected_workspace="$(zt_select_workspace 'workspace> ')"
[[ -n "$selected_workspace" ]] || exit 0

selected_workspace="${selected_workspace%%$'\n'*}"
workspace_file="${selected_workspace##*$sep}"

selected_documents="$(select_documents)"
[[ -n "$selected_documents" ]] || exit 0

while IFS= read -r selected_document; do
  [[ -n "$selected_document" ]] || continue

  doc_file="${${selected_document#*$sep}%%$sep*}"
  description="${selected_document##*$sep}"
  relative_target="../notes/${doc_file}"
  link="$(zt_workspace_link "$doc_file" "$description")"

  if zk_has_link_to "$workspace_file" "$relative_target"; then
    print -r -- "Already in workspace: $link"
    continue
  fi

  zk_append_related_link "$workspace_file" "== Документы" "" "$link" || exit 1
  print -r -- "Added to workspace: $link"
done <<< "$selected_documents"
