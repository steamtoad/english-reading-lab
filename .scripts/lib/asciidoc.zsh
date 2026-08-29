#------------------------------------------------------------------------------
# asciidoc.zsh
# Тип: Library
# Назначение: генерация AsciiDoc-фрагментов
#------------------------------------------------------------------------------

zk_link() {
  local fname="$1"
  local title="$2"

  print -r -- "link:${fname}[$title]"
}

zk_root_note_link() {
  local fname="$1"
  local title="$2"

  zk_link "notes/${fname}" "$title"
}

zk_today_link() {
  local fname="$1"
  local title="$2"

  zk_link "../notes/${fname}" "$title"
}

zk_workspace_link() {
  local fname="$1"
  local title="$2"

  zk_link "../notes/${fname}" "$title"
}

zk_today_entry() {
  local fname="$1"
  local title="$2"

  print -r -- "* $(date +"%H.%M") - $(zk_today_link "$fname" "$title")"
}

zk_attr_line() {
  local file="$1"
  local attr="$2"

  awk -v attr="$attr" '
    function trimmed(line) {
      sub(/^[[:space:]]+/, "", line)
      sub(/[[:space:]]+$/, "", line)
      return line
    }

    in_block {
      line = trimmed($0)

      if (block_delim == "```") {
        if (line ~ /^```/) {
          in_block = 0
        }
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

    index($0, ":" attr ":") == 1 {
      print
      exit
    }
  ' "$file"
}

zk_attr_value() {
  local line

  line="$(zk_attr_line "$1" "$2")"
  [[ -n "$line" ]] || return 1

  line="${line#:$2:}"
  line="${line#"${line%%[![:space:]]*}"}"
  print -r -- "$line"
}

zk_has_attr() {
  [[ -n "$(zk_attr_line "$1" "$2")" ]]
}

zk_is_deprecated() {
  zk_has_attr "$1" "deprecated"
}

zk_type_from_keywords() {
  local keywords="$1"

  if [[ "$keywords" == *note* && "$keywords" == *key-topic* ]]; then
    print -r -- "topic"
  elif [[ "$keywords" == *diary* ]]; then
    print -r -- "diary"
  elif [[ "$keywords" == *note* ]]; then
    print -r -- "note"
  elif [[ "$keywords" == *memo* ]]; then
    print -r -- "memo"
  elif [[ "$keywords" == *todo* ]]; then
    print -r -- "todo"
  else
    print -r -- "note"
  fi
}

zk_metadata() {
  local fname="$1"
  local title="$2"
  local keywords="$3"
  local type="${4:-$(zk_type_from_keywords "$keywords")}"

  print -r -- "= $title"
  print -r -- ":date: $(date +"%Y-%m-%d")"
  print -r -- ":keywords: $keywords"
  print -r -- ":type: $type"
  print -r -- ":author: $(whoami)"
  print -r -- ":description: $title"
  print -r -- ":doclink: $(zk_link "$fname" "$title")"
  print -r -- ":docfilename: $fname"
}

zk_keywords_for_type_from_topic() {
  local keywords="$1"
  local new_type="$2"

  print -r -- "$keywords" |
    awk -v new_type="$new_type" '
      BEGIN {
        FS = ","
      }

      {
        add(new_type)

        for (i = 1; i <= NF; i++) {
          item = $i
          gsub(/^[[:space:]]+/, "", item)
          gsub(/[[:space:]]+$/, "", item)

          if (item == "") continue
          if (item == "topic") continue
          if (item == new_type) continue

          add(item)
        }

        for (i = 1; i <= count; i++) {
          if (i > 1) printf ", "
          printf "%s", order[i]
        }

        printf "\n"
      }

      function add(item) {
        if (!(item in seen)) {
          seen[item] = 1
          order[++count] = item
        }
      }
    '
}

zk_file_title() {
  local file="$1"

  awk '
    /^= / {
      sub(/^= /, "")
      print
      exit
    }
  ' "$file"
}

zk_link_description() {
  local file="$1"
  local description

  description="$(zk_attr_value "$file" "description")"

  if [[ -z "$description" ]]; then
    description="$(zk_file_title "$file")"
  fi

  if [[ -z "$description" ]]; then
    description="${file:t}"
  fi

  print -r -- "$description"
}

zk_has_link_to() {
  local file="$1"
  local target="$2"

  grep -qF -- "link:${target}[" "$file"
}

zk_append_related_link() {
  local file="$1"
  local heading="$2"
  local label="$3"
  local link="$4"
  local entry
  local target
  local tmp

  target="${link#link:}"
  target="${target%%\[*}"

  zk_has_link_to "$file" "$target" && return 0

  if [[ -n "$label" ]]; then
    entry="* $label: $link"
  else
    entry="* $link"
  fi

  if grep -qFx -- "$heading" "$file"; then
    tmp="$(mktemp "${TMPDIR:-/tmp}/zk-related.XXXXXX")" || return 1

    if ! awk -v heading="$heading" -v entry="$entry" '
      !inserted && $0 == heading {
        in_section = 1
        print
        next
      }

      in_section {
        if (/^== /) {
          print entry
          print_pending_blanks()
          inserted = 1
          in_section = 0
          print
          next
        }

        if ($0 == "") {
          pending_blanks++
          next
        }

        print_pending_blanks()
        print
        next
      }

      {
        print
      }

      END {
        if (in_section && !inserted) {
          print entry
          print_pending_blanks()
        }
      }

      function print_pending_blanks() {
        while (pending_blanks > 0) {
          print ""
          pending_blanks--
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
    return 0
  fi

  {
    print -r -- ""
    print -r -- "$heading"
    print -r -- ""
    print -r -- "$entry"
  } >> "$file"
}
