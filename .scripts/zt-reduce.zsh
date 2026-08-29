#!/bin/zsh

#------------------------------------------------------------------------------
# zt-reduce.zsh
# Тип: Reduce
# Назначение: свертка Topic: новая Topic, deprecated старой Topic и Memo,
#             привязка Notes к новой Topic
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
    NR == 1 {
      next
    }

    /^$/ {
      exit
    }

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
      --prompt='reduce topic> '
}

select_reduce_mode() {
  {
    print -r -- "Full Copy"
    print -r -- "Clean Successor"
  } | fzf --prompt='Режим следующей редакции Topic> '
}

mark_deprecated() {
  local file="$1"
  local tmp

  is_header_deprecated "$file" && return 0

  tmp="$(mktemp "${TMPDIR:-/tmp}/zk-deprecated.XXXXXX")" || return 1

  if ! awk '
    BEGIN {
      in_header = 1
    }

    NR == 1 {
      if ($0 !~ /^= /) {
        exit 2
      }

      print
      next
    }

    in_header && /^:deprecated:/ {
      next
    }

    in_header && /^$/ {
      if (!inserted) {
        print ":deprecated:"
        inserted = 1
      }

      in_header = 0
      print
      next
    }

    in_header && $0 !~ /^:[^:]+:/ {
      exit 3
    }

    {
      print
    }

    END {
      if (!inserted) {
        exit 4
      }
    }
  ' "$file" > "$tmp"; then
    rm -f "$tmp"
    return 1
  fi

  if ! cat "$tmp" > "$file"; then
    rm -f "$tmp"
    return 1
  fi

  rm -f "$tmp"
}

create_full_copy_topic() {
  local src="$1"
  local dst="$2"
  local new_fname="$3"
  local title="$4"
  local key_topic_line="$5"
  local new_doclink

  new_doclink="$(zk_link "$new_fname" "$title")"

  awk \
    -v new_fname="$new_fname" \
    -v new_doclink="$new_doclink" \
    -v title="$title" \
    -v key_topic_line="$key_topic_line" '
      BEGIN {
        in_header = 1
      }

      NR == 1 {
        print "= " title
        next
      }

      in_header && /^:description:/ {
        print ":description: " title
        next
      }

      in_header && /^:doclink:/ {
        print ":doclink: " new_doclink
        next
      }

      in_header && /^:docfilename:/ {
        print ":docfilename: " new_fname
        next
      }

      in_header && /^:key-topic:/ {
        print key_topic_line
        next
      }

      in_header && /^:deprecated:/ {
        next
      }

      in_header && /^$/ {
        in_header = 0
      }

      {
        print
      }
    ' "$src" > "$dst"
}

create_clean_topic() {
  local dst="$1"
  local new_fname="$2"
  local title="$3"
  local key_topic_line="$4"

  {
    zk_metadata "$new_fname" "$title" "topic" "topic"
    print -r -- "$key_topic_line"
    print -r -- ""
    print -r -- ""
  } > "$dst"
}

validate_topic_metadata() {
  local file="$1"
  local key_topic="$2"
  local expected_title="${key_topic} - ключевая тема"
  local expected_doclink
  local actual
  local invalid=0

  expected_doclink="$(zk_link "$file" "$expected_title")"

  actual="$(zk_file_title "$file")"
  if [[ "$actual" != "$expected_title" ]]; then
    print -ru2 -- "ERROR Topic title is not canonical: '$actual'"
    print -ru2 -- "Expected: '$expected_title'"
    invalid=1
  fi

  actual="$(header_attr_value "$file" "description")"
  if [[ "$actual" != "$expected_title" ]]; then
    print -ru2 -- "ERROR Topic :description: is not canonical: '$actual'"
    print -ru2 -- "Expected: '$expected_title'"
    invalid=1
  fi

  actual="$(header_attr_value "$file" "doclink")"
  if [[ "$actual" != "$expected_doclink" ]]; then
    print -ru2 -- "ERROR Topic :doclink: is not canonical"
    print -ru2 -- "Expected: '$expected_doclink'"
    invalid=1
  fi

  actual="$(header_attr_value "$file" "docfilename")"
  if [[ "$actual" != "$file" ]]; then
    print -ru2 -- "ERROR Topic :docfilename: does not match '$file'"
    invalid=1
  fi

  (( invalid == 0 ))
}

validate_deprecated_target() {
  local file="$1"

  if ! awk '
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
  ' "$file"; then
    print -ru2 -- "ERROR cannot determine AsciiDoc header boundary: $file"
    return 1
  fi
}

same_key_topic() {
  local file="$1"
  local expected="$2"

  [[ "$(header_attr_value "$file" "key-topic")" == "$expected" ]]
}

print_reduce_plan() {
  local old_topic="$1"
  local new_fname="$2"
  local mode="$3"
  local key_topic="$4"

  print -r -- "== Reduce plan"
  print -r -- "Mode: $mode"
  print -r -- "Old Topic: $old_topic"
  print -r -- "New Topic: $new_fname"
  print -r -- "Key Topic: $key_topic"
  print -r -- "Deprecated Memo: ${#active_memo_files}"

  for file in "${active_memo_files[@]}"; do
    print -r -- "  deprecated: $file"
  done

  print -r -- "Linked Note: ${#active_note_files}"

  for file in "${active_note_files[@]}"; do
    print -r -- "  linked: $file"
  done
}

confirm_reduce() {
  local answer

  read -r "?Применить Reduce? [y/N]: " answer
  [[ "$answer" == [yY] ]]
}

zk_ensure_notes_dir
zk_cd_notes

selected="$(select_topic_file)"
[[ -n "$selected" ]] || exit 0

selected="${selected%%$'\n'*}"
old_topic="${selected##*$sep}"

key_topic_line="$(header_attr_line "$old_topic" "key-topic")"
key_topic="$(header_attr_value "$old_topic" "key-topic")"

if [[ -z "$key_topic_line" || -z "$key_topic" ]]; then
  print -ru2 -- "ERROR selected Topic has no :key-topic:"
  exit 1
fi

validate_topic_metadata "$old_topic" "$key_topic" || {
  print -ru2 -- "ERROR migrate the Topic metadata before Reduce"
  exit 1
}

mode="$(select_reduce_mode)"
[[ -n "$mode" ]] || exit 0

new_fname="$(zk_new_adoc_filename)" || exit 1
canonical_title="${key_topic} - ключевая тема"

typeset -a active_memo_files
typeset -a active_note_files

active_memo_files=()
active_note_files=()

for file in *.adoc; do
  [[ -f "$file" ]] || continue
  is_header_deprecated "$file" && continue

  case "$(header_attr_value "$file" "type")" in
    memo)
      same_key_topic "$file" "$key_topic" && active_memo_files+=("$file")
      ;;
    note)
      same_key_topic "$file" "$key_topic" && active_note_files+=("$file")
      ;;
  esac
done

validate_deprecated_target "$old_topic" || exit 1

for memo_file in "${active_memo_files[@]}"; do
  validate_deprecated_target "$memo_file" || exit 1
done

print_reduce_plan "$old_topic" "$new_fname" "$mode" "$key_topic"
confirm_reduce || exit 0

zk_ensure_dirs

case "$mode" in
  "Full Copy")
    create_full_copy_topic \
      "$old_topic" \
      "$new_fname" \
      "$new_fname" \
      "$canonical_title" \
      "$key_topic_line" || exit 1
    ;;

  "Clean Successor")
    create_clean_topic \
      "$new_fname" \
      "$new_fname" \
      "$canonical_title" \
      "$key_topic_line" || exit 1
    ;;

  *)
    print -ru2 -- "ERROR unknown Reduce mode: $mode"
    exit 1
    ;;
esac

new_description="$(zk_link_description "$new_fname")"
old_description="$(zk_link_description "$old_topic")"

new_link="$(zk_link "$new_fname" "$new_description")"
old_link="$(zk_link "$old_topic" "$old_description")"

zk_today_entry "$new_fname" "$new_description" >> "$(zk_today_file)"

zk_append_related_link "$old_topic" "== Связанные Topic" "Развитие" "$new_link"
zk_append_related_link "$new_fname" "== Связанные Topic" "Основано на" "$old_link"

# Notes are durable knowledge units.
# Reduce links active Notes to the new Topic, but never deprecates Notes.
for note_file in "${active_note_files[@]}"; do
  note_description="$(zk_link_description "$note_file")"
  note_link="$(zk_link "$note_file" "$note_description")"

  zk_append_related_link "$new_fname" "== Связанные note" "" "$note_link"
  zk_append_related_link "$note_file" "== Связи" "Topic" "$new_link"
done

# Reduce deprecates only the old Topic and active Memo with the same :key-topic:.
mark_deprecated "$old_topic" || exit 1

for memo_file in "${active_memo_files[@]}"; do
  mark_deprecated "$memo_file" || exit 1
done

print -r -- "Reduce complete"
print -r -- "Old Topic: $old_topic"
print -r -- "New Topic: $new_fname"
print -r -- "Deprecated Memo: ${#active_memo_files}"
print -r -- "Linked Note: ${#active_note_files}"

vim "$new_fname"

print -r -- "$new_link"
