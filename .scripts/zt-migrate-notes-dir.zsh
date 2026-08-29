#!/bin/zsh

#------------------------------------------------------------------------------
# zt-migrate-notes-dir.zsh
# Тип: Migration
# Назначение: перенос UUID-документов ядра из корня в notes/
#------------------------------------------------------------------------------

emulate -L zsh
setopt null_glob nounset pipefail

script_dir="${0:A:h}"
source "$script_dir/lib/paths.zsh"
source "$script_dir/lib/asciidoc.zsh"

mode="dry-run"

usage() {
  print -u2 -- "Usage: ${0:t} [--dry-run|--apply]"
}

die() {
  print -u2 -- "Error: $*"
  exit 1
}

case "${1:---dry-run}" in
  --dry-run) mode="dry-run" ;;
  --apply) mode="apply" ;;
  *) usage; exit 1 ;;
esac

(( $# <= 1 )) || {
  usage
  exit 1
}

zk="$(zk_home)"
notes_dir="$(zk_notes_dir)"

[[ -d "$zk" ]] || die "Zettelkasten not found: $zk"

typeset -a documents
typeset -a indexes
documents=()
indexes=()

for file in "$zk"/*.adoc; do
  [[ -f "$file" ]] || continue
  type="$(zk_attr_value "$file" type)"

  case "$type" in
    note|memo|todo|diary|topic) documents+=("$file") ;;
  esac
done

for file in "$zk/all-todays"/*.adoc "$zk/workspaces"/*.adoc; do
  [[ -f "$file" ]] && indexes+=("$file")
done

for source_file in "${documents[@]}"; do
  destination="$notes_dir/${source_file:t}"
  [[ ! -e "$destination" ]] || die "destination already exists: $destination"
done

print -r -- "Mode: $mode"
print -r -- "Root: $zk"
print -r -- "Documents to move: ${#documents[@]}"
print -r -- "Index files to inspect: ${#indexes[@]}"

for source_file in "${documents[@]}"; do
  print -r -- "MOVE ${source_file:t} -> notes/${source_file:t}"
done

[[ "$mode" == "apply" ]] || exit 0

(( ${#documents[@]} > 0 )) || die "no root UUID documents found"

if git -C "$zk" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  [[ -z "$(git -C "$zk" status --porcelain)" ]] ||
    die "working tree must be clean before migration"
fi

backup_dir="$(mktemp -d "${TMPDIR:-/tmp}/zt-migrate-notes.XXXXXX")" ||
  die "cannot create backup directory"
mkdir -p "$backup_dir/documents" "$backup_dir/all-todays" "$backup_dir/workspaces" ||
  die "cannot initialize backup directory"
typeset -a moved
moved=()

rollback() {
  local moved_file
  local target

  for moved_file in "${moved[@]}"; do
    target="$zk/${moved_file:t}"
    rm -f "$moved_file"
    cp -p "$backup_dir/documents/${moved_file:t}" "$target"
  done

  for backup_file in "$backup_dir/all-todays"/*.adoc; do
    [[ -f "$backup_file" ]] || continue
    cp -p "$backup_file" "$zk/all-todays/${backup_file:t}"
  done

  for backup_file in "$backup_dir/workspaces"/*.adoc; do
    [[ -f "$backup_file" ]] || continue
    cp -p "$backup_file" "$zk/workspaces/${backup_file:t}"
  done

  rmdir "$notes_dir" 2>/dev/null || true
}

trap 'rollback; rm -rf "$backup_dir"; exit 1' INT TERM HUP

mkdir -p "$notes_dir" || die "cannot create notes directory"

for source_file in "${documents[@]}"; do
  cp -p "$source_file" "$backup_dir/documents/${source_file:t}" || {
    rollback
    die "cannot back up: $source_file"
  }
done

for index_file in "${indexes[@]}"; do
  case "$index_file" in
    "$zk/all-todays"/*) backup_path="$backup_dir/all-todays/${index_file:t}" ;;
    "$zk/workspaces"/*) backup_path="$backup_dir/workspaces/${index_file:t}" ;;
    *) die "unexpected index path: $index_file" ;;
  esac

  cp -p "$index_file" "$backup_path" || {
    rollback
    die "cannot back up: $index_file"
  }
done

for source_file in "${documents[@]}"; do
  destination="$notes_dir/${source_file:t}"
  mv "$source_file" "$destination" || {
    rollback
    die "cannot move: $source_file"
  }
  moved+=("$destination")
done

typeset -a moved_names
moved_names=()
for moved_file in "${moved[@]}"; do
  moved_names+=("${moved_file:t}")
done
moved_serialized="${(j:,:)moved_names}"

moved_manifest="$backup_dir/moved-names"
root_manifest="$backup_dir/root-targets"
print -rl -- "${moved_names[@]}" > "$moved_manifest"

find "$zk" -type f -name '*.adoc' ! -path "$notes_dir/*" -print |
  while IFS= read -r root_target; do
    print -r -- "${root_target#$zk/}"
  done > "$root_manifest"

for moved_file in "${moved[@]}"; do
  tmp="$(mktemp "${TMPDIR:-/tmp}/zt-migrate-note.XXXXXX")" || {
    rollback
    die "cannot create temporary file"
  }

  awk -v moved_manifest="$moved_manifest" -v root_manifest="$root_manifest" '
    BEGIN {
      while ((getline name < moved_manifest) > 0) moved[name] = 1
      close(moved_manifest)
      while ((getline name < root_manifest) > 0) root[name] = 1
      close(root_manifest)
    }

    function trimmed(value) {
      sub(/^[[:space:]]+/, "", value)
      sub(/[[:space:]]+$/, "", value)
      return value
    }

    function migrated_target(target, without_parent) {
      if (target ~ /^\.\.\/[0-9A-Fa-f-]+\.adoc$/) {
        without_parent = substr(target, 4)
        if (without_parent in moved) return without_parent
      }

      if (target in moved) return target
      if (target in root) return "../" target
      return target
    }

    in_block {
      print
      value = trimmed($0)
      if (block_delim == "```") {
        if (value ~ /^```/) in_block = 0
      } else if (value == block_delim) {
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

    /^:doclink:/ { print; next }

    {
      line = $0
      output = ""

      while (match(line, /link:[^[]+\.adoc\[/)) {
        token = substr(line, RSTART, RLENGTH)
        target = substr(token, 6, length(token) - 6)
        output = output substr(line, 1, RSTART - 1)
        output = output "link:" migrated_target(target) "["
        line = substr(line, RSTART + RLENGTH)
      }

      print output line
    }
  ' "$moved_file" > "$tmp" || {
    rm -f "$tmp"
    rollback
    die "cannot rewrite moved document: $moved_file"
  }

  if [[ "$(uname)" == Darwin ]]; then
    mode_bits="$(stat -f '%Lp' "$moved_file")"
  else
    mode_bits="$(stat -c '%a' "$moved_file")"
  fi
  chmod "$mode_bits" "$tmp" && mv "$tmp" "$moved_file" || {
    rm -f "$tmp"
    rollback
    die "cannot replace moved document: $moved_file"
  }
done

for index_file in "${indexes[@]}"; do
  tmp="$(mktemp "${TMPDIR:-/tmp}/zt-migrate-index.XXXXXX")" || {
    rollback
    die "cannot create temporary file"
  }

  awk -v moved_serialized="$moved_serialized" '
    BEGIN {
      count = split(moved_serialized, names, ",")
      for (i = 1; i <= count; i++) moved[names[i]] = 1
    }

    {
      line = $0
      output = ""

      while (match(line, /link:\.\.\/[0-9A-Fa-f-]+\.adoc\[/)) {
        token = substr(line, RSTART, RLENGTH)
        name = substr(token, 9, length(token) - 9)
        output = output substr(line, 1, RSTART - 1)

        if (name in moved) {
          output = output "link:../notes/" name "["
        } else {
          output = output token
        }

        line = substr(line, RSTART + RLENGTH)
      }

      print output line
    }
  ' "$index_file" > "$tmp" || {
    rm -f "$tmp"
    rollback
    die "cannot rewrite index: $index_file"
  }

  mode_bits=""
  if [[ "$(uname)" == Darwin ]]; then
    mode_bits="$(stat -f '%Lp' "$index_file")"
  else
    mode_bits="$(stat -c '%a' "$index_file")"
  fi
  chmod "$mode_bits" "$tmp" || {
    rm -f "$tmp"
    rollback
    die "cannot preserve mode: $index_file"
  }
  mv "$tmp" "$index_file" || {
    rm -f "$tmp"
    rollback
    die "cannot replace index: $index_file"
  }
done

trap - INT TERM HUP
rm -rf "$backup_dir"

print -r -- "Migration complete: ${#moved[@]} document(s) moved"
