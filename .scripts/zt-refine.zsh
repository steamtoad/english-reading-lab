#!/bin/zsh

#------------------------------------------------------------------------------
# zt-refine.zsh
# Тип: Refine
# Назначение: выделение выбранных документов Topic в новую тематическую линию
#------------------------------------------------------------------------------

emulate -L zsh
setopt null_glob

script_dir="${0:A:h}"

source "$script_dir/lib/paths.zsh"
source "$script_dir/lib/uuid.zsh"
source "$script_dir/lib/asciidoc.zsh"

sep=$'\x1f'

header_attr_line() {
  local file="$1"
  local attr="$2"

  awk -v attr="$attr" '
    NR == 1 { next }
    /^$/ { exit }

    index($0, ":" attr ":") == 1 {
      print
      exit
    }
  ' "$file"
}

header_attr_value() {
  local line
  local attr="$2"

  line="$(header_attr_line "$1" "$attr")"
  [[ -n "$line" ]] || return 1

  line="${line#:$attr:}"
  line="${line#"${line%%[![:space:]]*}"}"
  print -r -- "$line"
}

is_header_deprecated() {
  [[ -n "$(header_attr_line "$1" "deprecated")" ]]
}

validate_header() {
  local file="$1"

  awk '
    NR == 1 {
      if ($0 !~ /^= /) invalid = 1
      next
    }

    /^$/ {
      boundary = 1
      exit
    }

    $0 !~ /^:[^:]+:/ {
      invalid = 1
      exit
    }

    END {
      exit invalid || !boundary
    }
  ' "$file"
}

validate_topic_metadata() {
  local file="$1"
  local key_topic="$2"
  local expected_title="${key_topic} - ключевая тема"

  [[ "$(zk_file_title "$file")" == "$expected_title" ]] &&
    [[ "$(header_attr_value "$file" "description")" == "$expected_title" ]] &&
    [[ "$(header_attr_value "$file" "doclink")" == "$(zk_link "$file" "$expected_title")" ]] &&
    [[ "$(header_attr_value "$file" "docfilename")" == "$file" ]]
}

select_topic_file() {
  local file
  local description

  for file in *.adoc; do
    is_header_deprecated "$file" && continue
    [[ "$(header_attr_value "$file" "type")" == "topic" ]] || continue

    description="$(zk_link_description "$file")"
    print -r -- "${file} - ${description}${sep}${file}"
  done |
    fzf \
      --delimiter="$sep" \
      --with-nth=1 \
      --prompt='refine source topic> '
}

select_documents() {
  local file
  local description
  local type

  for file in "${candidate_files[@]}"; do
    type="$(header_attr_value "$file" "type")"
    description="$(zk_link_description "$file")"
    print -r -- "${type} - ${file} - ${description}${sep}${file}"
  done |
    fzf \
      --multi \
      --delimiter="$sep" \
      --with-nth=1 \
      --prompt='refine documents> '
}

select_archive_source() {
  {
    print -r -- "Нет"
    print -r -- "Да"
  } | fzf --prompt='Архивировать исходную Topic? '
}

replace_header_key_topic() {
  local file="$1"
  local new_key="$2"
  local tmp

  tmp="$(mktemp "${TMPDIR:-/tmp}/zk-refine-key.XXXXXX")" || return 1

  if ! awk -v new_key="$new_key" '
    BEGIN { in_header = 1 }

    in_header && /^:key-topic:/ {
      print ":key-topic: " new_key
      replaced = 1
      next
    }

    in_header && /^$/ {
      in_header = 0
    }

    { print }

    END {
      if (!replaced) exit 2
    }
  ' "$file" > "$tmp"; then
    rm -f "$tmp"
    return 1
  fi

  mv "$tmp" "$file"
}

remove_related_link() {
  local file="$1"
  local target="$2"
  local tmp

  tmp="$(mktemp "${TMPDIR:-/tmp}/zk-refine-link.XXXXXX")" || return 1

  if ! awk -v target="link:${target}[" '
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

    /^[*][[:space:]]/ && index($0, target) {
      next
    }

    { print }
  ' "$file" > "$tmp"; then
    rm -f "$tmp"
    return 1
  fi

  mv "$tmp" "$file"
}

mark_deprecated() {
  local file="$1"
  local tmp

  is_header_deprecated "$file" && return 0

  tmp="$(mktemp "${TMPDIR:-/tmp}/zk-refine-deprecated.XXXXXX")" || return 1

  if ! awk '
    NR == 1 {
      print
      next
    }

    /^$/ && !inserted {
      print ":deprecated:"
      inserted = 1
      print
      next
    }

    { print }

    END {
      if (!inserted) exit 2
    }
  ' "$file" > "$tmp"; then
    rm -f "$tmp"
    return 1
  fi

  mv "$tmp" "$file"
}

create_topic() {
  local output_file="$1"
  local file="$2"
  local key="$3"
  local title="${key} - ключевая тема"

  {
    zk_metadata "$file" "$title" "topic" "topic"
    print -r -- ":key-topic: $key"
    print -r -- ""
    print -r -- ""
  } > "$output_file"
}

print_plan() {
  print -r -- "== Refine plan"
  print -r -- "Source Topic: $source_topic"
  print -r -- "Source Key Topic: $source_key"
  print -r -- "New Topic: $new_fname"
  print -r -- "New Key Topic: $new_key"
  print -r -- "Archive Source Topic: $archive_source"
  print -r -- "Selected Documents: ${#selected_files}"

  for file in "${selected_files[@]}"; do
    print -r -- "  rekey: $file"
    print -r -- "  remove link: $source_topic <-> $file"
    print -r -- "  add link: $new_fname <-> $file"
  done

  if [[ "$archive_source" == "Да" ]]; then
    print -r -- "  archive: $source_topic"

    for file in "${unselected_files[@]}"; do
      print -r -- "  archive with source: $file"
    done
  fi

  print -r -- "  provenance: $source_topic <-> $new_fname"
}

confirm_refine() {
  local answer

  read -r "?Применить Refine? [y/N]: " answer
  [[ "$answer" == [yY] ]]
}

rollback_apply() {
  local file

  for file in "${existing_apply_files[@]}"; do
    cp "$backup_dir/${file:t}" "$file" || true
  done

  rm -f "$new_fname"

  if [[ -n "$today_file" && ! -f "$backup_dir/${today_file:t}" ]]; then
    rm -f "$today_file"
  fi
}

zk_ensure_notes_dir
zk_cd_notes

selected="$(select_topic_file)"
[[ -n "$selected" ]] || exit 0

selected="${selected%%$'\n'*}"
source_topic="${selected##*$sep}"
source_key="$(header_attr_value "$source_topic" "key-topic")"

if [[ -z "$source_key" ]]; then
  print -ru2 -- "ERROR selected Topic has no header :key-topic:"
  exit 1
fi

if ! validate_header "$source_topic" || ! validate_topic_metadata "$source_topic" "$source_key"; then
  print -ru2 -- "ERROR source Topic metadata is not canonical"
  exit 1
fi

read -r "?Введите название новой тематической линии: " new_key
new_key="${new_key#"${new_key%%[![:space:]]*}"}"
new_key="${new_key%"${new_key##*[![:space:]]}"}"

if [[ -z "$new_key" || "$new_key" == "$source_key" ]]; then
  print -ru2 -- "ERROR new :key-topic: must be non-empty and different from source"
  exit 1
fi

for file in *.adoc; do
  is_header_deprecated "$file" && continue
  [[ "$(header_attr_value "$file" "type")" == "topic" ]] || continue

  if [[ "$(header_attr_value "$file" "key-topic")" == "$new_key" ]]; then
    print -ru2 -- "ERROR active Topic already exists for :key-topic: $new_key"
    exit 1
  fi
done

typeset -a candidate_files
typeset -a selected_files
typeset -a unselected_files
typeset -A selected_file_set

candidate_files=()
selected_files=()
unselected_files=()
selected_file_set=()

for file in *.adoc; do
  [[ "$file" == "$source_topic" ]] && continue
  is_header_deprecated "$file" && continue
  [[ "$(header_attr_value "$file" "key-topic")" == "$source_key" ]] || continue

  case "$(header_attr_value "$file" "type")" in
    memo|note|todo|diary) candidate_files+=("$file") ;;
  esac
done

(( ${#candidate_files} > 0 )) || {
  print -ru2 -- "ERROR source Topic has no active documents available for Refine"
  exit 1
}

selected="$(select_documents)"
[[ -n "$selected" ]] || exit 0

while IFS= read -r line; do
  [[ -n "$line" ]] || continue
  selected_files+=("${line##*$sep}")
done <<< "$selected"

(( ${#selected_files} > 0 )) || exit 0

for file in "${selected_files[@]}"; do
  selected_file_set[$file]=1
done

for file in "${candidate_files[@]}"; do
  [[ -n "${selected_file_set[$file]-}" ]] && continue
  unselected_files+=("$file")
done

archive_source="$(select_archive_source)"
[[ -n "$archive_source" ]] || exit 0

if [[ "$archive_source" != "Да" && "$archive_source" != "Нет" ]]; then
  print -ru2 -- "ERROR unknown archive choice: $archive_source"
  exit 1
fi

for file in "$source_topic" "${selected_files[@]}"; do
  if ! validate_header "$file"; then
    print -ru2 -- "ERROR cannot determine AsciiDoc header boundary: $file"
    exit 1
  fi
done

if [[ "$archive_source" == "Да" ]]; then
  for file in "${unselected_files[@]}"; do
    if ! validate_header "$file"; then
      print -ru2 -- "ERROR cannot determine AsciiDoc header boundary: $file"
      exit 1
    fi
  done
fi

new_fname="$(zk_new_adoc_filename)" || exit 1
new_title="${new_key} - ключевая тема"
new_link="$(zk_link "$new_fname" "$new_title")"
source_link="$(zk_link "$source_topic" "$(zk_link_description "$source_topic")")"

print_plan
confirm_refine || exit 0

stage_dir="$(mktemp -d "${TMPDIR:-/tmp}/zk-refine-stage.XXXXXX")" || exit 1
backup_dir="$(mktemp -d "${TMPDIR:-/tmp}/zk-refine-backup.XXXXXX")" || {
  rm -rf "$stage_dir"
  exit 1
}

cp "$source_topic" "$stage_dir/$source_topic" || exit 1

for file in "${selected_files[@]}"; do
  cp "$file" "$stage_dir/$file" || exit 1
done

if [[ "$archive_source" == "Да" ]]; then
  for file in "${unselected_files[@]}"; do
    cp "$file" "$stage_dir/$file" || exit 1
  done
fi

create_topic "$stage_dir/$new_fname" "$new_fname" "$new_key" || exit 1

for file in "${selected_files[@]}"; do
  staged_file="$stage_dir/$file"
  file_type="$(header_attr_value "$file" "type")"
  file_link="$(zk_link "$file" "$(zk_link_description "$file")")"

  replace_header_key_topic "$staged_file" "$new_key" || exit 1
  remove_related_link "$stage_dir/$source_topic" "$file" || exit 1
  remove_related_link "$staged_file" "$source_topic" || exit 1
  zk_append_related_link "$stage_dir/$new_fname" "== Связанные ${file_type}" "" "$file_link" || exit 1
  zk_append_related_link "$staged_file" "== Связи" "Topic" "$new_link" || exit 1
done

zk_append_related_link "$stage_dir/$source_topic" "== Связанные Topic" "Выделенная тема" "$new_link" || exit 1
zk_append_related_link "$stage_dir/$new_fname" "== Связанные Topic" "Выделено из" "$source_link" || exit 1

if [[ "$archive_source" == "Да" ]]; then
  mark_deprecated "$stage_dir/$source_topic" || exit 1

  for file in "${unselected_files[@]}"; do
    mark_deprecated "$stage_dir/$file" || exit 1
  done
fi

today_file="$(zk_today_file)"
mkdir -p "$stage_dir/all-todays" || exit 1

if [[ -f "$today_file" ]]; then
  cp "$today_file" "$stage_dir/all-todays/${today_file:t}" || exit 1
else
  print -r -- "= Заметки за $(date +"%d-%m-%Y")" > "$stage_dir/all-todays/${today_file:t}"
  print -r -- "" >> "$stage_dir/all-todays/${today_file:t}"
fi

zk_today_entry "$new_fname" "$new_title" >> "$stage_dir/all-todays/${today_file:t}"

for file in "$source_topic" "${selected_files[@]}" "$new_fname"; do
  validate_header "$stage_dir/$file" || {
    print -ru2 -- "ERROR staged document has invalid header: $file"
    exit 1
  }
done

if [[ "$archive_source" == "Да" ]]; then
  for file in "${unselected_files[@]}"; do
    validate_header "$stage_dir/$file" || {
      print -ru2 -- "ERROR staged document has invalid header: $file"
      exit 1
    }
  done
fi

typeset -a existing_apply_files
existing_apply_files=("$source_topic" "${selected_files[@]}")

if [[ "$archive_source" == "Да" ]]; then
  existing_apply_files+=("${unselected_files[@]}")
fi

for file in "${existing_apply_files[@]}"; do
  cp "$file" "$backup_dir/${file:t}" || exit 1
done

if [[ -f "$today_file" ]]; then
  existing_apply_files+=("$today_file")
  cp "$today_file" "$backup_dir/${today_file:t}" || exit 1
fi

apply_failed=0

trap 'rollback_apply; print -ru2 -- "ERROR Refine interrupted; changes rolled back"; exit 1' INT TERM HUP

for file in "$source_topic" "${selected_files[@]}" "${unselected_files[@]}" "$new_fname"; do
  [[ -f "$stage_dir/$file" ]] || continue
  cp "$stage_dir/$file" "$file" || apply_failed=1
done

mkdir -p "${today_file:h}" || apply_failed=1
cp "$stage_dir/all-todays/${today_file:t}" "$today_file" || apply_failed=1

if (( apply_failed )); then
  rollback_apply
  print -ru2 -- "ERROR Refine failed; changes rolled back"
  exit 1
fi

trap - INT TERM HUP

rm -rf "$stage_dir" "$backup_dir"

print -r -- "Refine complete"
print -r -- "Source Topic: $source_topic"
print -r -- "New Topic: $new_fname"
print -r -- "Rekeyed Documents: ${#selected_files}"
print -r -- "Archived Source Topic: $archive_source"
if [[ "$archive_source" == "Да" ]]; then
  print -r -- "Archived Unselected Documents: ${#unselected_files}"
fi

vim "$new_fname"

print -r -- "$new_link"
