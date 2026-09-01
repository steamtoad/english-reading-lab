#!/bin/zsh

#------------------------------------------------------------------------------
# card-content.zsh
# Тип: ERL library
# Назначение: проверить deterministic human-readable content contract ERL-DOC-008
#------------------------------------------------------------------------------

# Deterministic ERL-DOC-008 checks. Each finding is emitted as one line so
# callers can attach their own diagnostic envelope and scope information.

erl_card_body() {
  awk 'NR==1{next} !body && /^[[:space:]]*$/{body=1;next} body{print}' "$1"
}

erl_card_section_value() {
  local file="$1" section="$2" label="$3"
  awk -v section="$section" -v label="$label" '
    $0 == "== " section { inside=1; next }
    inside && /^== / { exit }
    inside && index($0, label "::") == 1 {
      sub("^" label "::[[:space:]]*", "")
      print
      exit
    }
  ' "$file"
}

erl_card_section_body() {
  local file="$1" section="$2"
  awk -v section="$section" '
    $0 == "== " section { inside=1; next }
    inside && /^== / { exit }
    inside && $0 !~ /^[[:space:]]*$/ { print }
  ' "$file"
}

erl_card_content_findings() {
  local file="$1" role="$2" title body value label

  if ! iconv -f UTF-8 -t UTF-8 "$file" >/dev/null 2>&1; then
    print -r -- "invalid UTF-8"
    return 0
  fi

  title="$(awk 'NR==1 && /^= [^[:space:]]/{sub(/^= /,"");print}' "$file")"
  [[ -n "$title" ]] || print -r -- "missing or empty AsciiDoc document title"
  awk 'NR>1 && /^=+[^=[:space:]]/{bad=1} END{exit(bad?0:1)}' "$file" && \
    print -r -- "malformed AsciiDoc heading"

  body="$(erl_card_body "$file")"
  [[ -n "${body//[[:space:]]/}" ]] || print -r -- "empty document body"

  LC_ALL=C grep -q $'[\001-\010\013\014\016-\037\177]' "$file" 2>/dev/null && \
    print -r -- "control character in document content"
  grep -Eq '\{\{[^}]+\}\}|\$\{[^}]+\}|@@[A-Z0-9_]+@@|<[A-Z][A-Z0-9_ -]*>' "$file" && \
    print -r -- "unresolved template placeholder"

  if print -r -- "$body" | awk 'NF{print;exit}' | grep -Eq '^[][{}][[:space:]]*$|^[{[]'; then
    print -r -- "raw JSON serialization replaces readable content"
  fi
  if print -r -- "$body" | awk 'NF{print;exit}' | grep -Eq '^---[[:space:]]*$'; then
    print -r -- "raw YAML serialization replaces readable content"
  fi
  if print -r -- "$body" | awk 'NF{print;exit}' | grep -Eiq '^<(html|body|div|section|article|p|[?]xml)([[:space:]>]|$)'; then
    print -r -- "raw HTML/XML markup replaces readable content"
  fi

  while IFS= read -r label; do
    [[ -n "${label//[[:space:]]/}" && "$label" != Description && ! "$label" =~ '^[0-9a-f-]{36}$' ]] || \
      print -r -- "canonical link has an unreadable label"
  done < <(grep -Eo 'link:[0-9a-f-]{36}\.adoc\[[^]]*\]' "$file" 2>/dev/null | sed -E 's/^.*\[//;s/\]$//')

  case "$role" in
    book)
      print -r -- "$body" | grep -Eq '^== (Book|About this book|Reading)[[:space:]]*$|^Book::[[:space:]]*[^[:space:]]' || \
        print -r -- "Book body lacks readable book identity or navigation"
      ;;
    chapter)
      value="$(erl_card_section_value "$file" Source Book)"
      [[ -n "${value//[[:space:]]/}" ]] || print -r -- "Chapter body lacks labelled Book context"
      ;;
    vocabulary)
      for label in Lemma POS 'Lexical type'; do
        value="$(erl_card_section_value "$file" 'Lexical identity' "$label")"
        [[ -n "${value//[[:space:]]/}" ]] || print -r -- "Vocabulary has empty required value: $label"
      done
      value="$(erl_card_section_value "$file" Meaning Definition)$(erl_card_section_value "$file" Meaning Translation)"
      [[ -n "${value//[[:space:]]/}" ]] || print -r -- "Vocabulary body lacks a readable meaning"
      ;;
    occurrence)
      value="$(erl_card_section_body "$file" Context)"
      [[ -n "${value//[[:space:]]/}" ]] || print -r -- "Occurrence has empty Context"
      ;;
  esac
  return 0
}
