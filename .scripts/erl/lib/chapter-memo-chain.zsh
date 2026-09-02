#!/bin/zsh

#------------------------------------------------------------------------------
# chapter-memo-chain.zsh
# Тип: ERL library
# Назначение: материализовать canonical Chapter attachment и Memo Chain links
#------------------------------------------------------------------------------

emulate -L zsh

erl_section_links() {
  local file="$1" section="$2" label="${3:-}"
  awk -v section="$section" -v label="$label" '
    $0=="== " section {inside=1;next}
    inside && /^== / {exit}
    inside && match($0,/^link:([0-9a-f-]{36})\.adoc\[([^]]+)\]$/) {
      uuid=$0; sub(/^link:/,"",uuid); sub(/\.adoc\[.*$/,"",uuid)
      text=$0; sub(/^.*\[/,"",text); sub(/\]$/,"",text)
      if(label=="" || text==label) print uuid
    }
  ' "$file"
}

erl_set_missing_key_topic() {
  local file="$1" key="$2" existing tmp
  existing="$(erl_doc_attr "$file" key-topic)"
  [[ -z "$existing" || "$existing" == "$key" ]] || return 2
  [[ -n "$existing" ]] && return 0
  tmp="$(mktemp "${file}.tmp.XXXXXX")" || return 1
  awk -v key="$key" 'NR==1{print;next} !done && /^[[:space:]]*$/{print ":key-topic: " key;done=1} {print} END{if(!done)print ":key-topic: " key}' "$file" > "$tmp" && mv -- "$tmp" "$file"
}

erl_replace_key_topic() {
  local file="$1" key="$2" tmp
  tmp="$(mktemp "${file}.tmp.XXXXXX")" || return 1
  awk -v key="$key" '
    NR==1 {print;next}
    /^:key-topic:/ {if(!done){print ":key-topic: " key;done=1};next}
    !done && /^[[:space:]]*$/ {print ":key-topic: " key;done=1}
    {print}
    END {if(!done) print ":key-topic: " key}
  ' "$file" > "$tmp" && mv -- "$tmp" "$file"
}

erl_replace_section_links() {
  local file="$1" section="$2" links_file="$3" tmp
  tmp="$(mktemp "${file}.tmp.XXXXXX")" || return 1
  awk -v section="$section" -v links_file="$links_file" '
    function emit( line) {
      print "== " section; print ""
      while((getline line < links_file)>0) print line
      close(links_file); emitted=1
    }
    $0=="== " section {if(!emitted) emit(); skip=1; next}
    skip && /^== / {skip=0}
    !skip {print}
    END {if(!emitted){print ""; emit()}}
  ' "$file" > "$tmp" && mv -- "$tmp" "$file"
}

erl_append_section_link() {
  local file="$1" section="$2" uuid="$3" label="$4"
  grep -qF -- "link:$uuid.adoc[$label]" "$file" && return 0
  {
    print -r -- ""
    print -r -- "== $section"
    print -r -- ""
    print -r -- "link:$uuid.adoc[$label]"
  } >> "$file"
}

erl_append_link_to_section() {
  local file="$1" section="$2" uuid="$3" label="$4" tmp
  grep -qF -- "link:$uuid.adoc[$label]" "$file" && return 0
  tmp="$(mktemp "${file}.tmp.XXXXXX")" || return 1
  awk -v section="$section" -v link="link:$uuid.adoc[$label]" '
    $0=="== " section {inside=1; found=1; print; next}
    inside && /^== / && !added {print ""; print link; print ""; added=1; inside=0}
    {print}
    END {if(!found){print ""; print "== " section; print ""; print link}else if(inside&&!added){print ""; print link}}
  ' "$file" > "$tmp" && mv -- "$tmp" "$file"
}

erl_memo_chain_add_predecessor() {
  erl_append_link_to_section "$1" "Memo Chain" "$2" "Предыдущее memo"
}

erl_memo_chain_add_successor() {
  erl_append_link_to_section "$1" "Memo Chain" "$2" "Следующее memo"
}
