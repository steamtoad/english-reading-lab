#!/bin/zsh

#------------------------------------------------------------------------------
# source.zsh
# Тип: ERL library
# Назначение: детерминированно разобрать source book и извлечь структуру и содержимое Chapter
#------------------------------------------------------------------------------

erl_epub_package_path() {
  unzip -p "$1" META-INF/container.xml 2>/dev/null | xmllint --xpath 'string((//*[local-name()="rootfile"])[1]/@full-path)' - 2>/dev/null
}

erl_source_chapters() {
  local source_path="$1" suffix tmp_dir package package_dir opf idref href locator title order=0
  suffix="${source_path:e:l}"
  local -a idrefs rows
  rows=()
  case "$suffix" in
    epub)
      erl_require_command unzip
      erl_require_command xmllint
      tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/erl-epub.XXXXXX")" || return 1
      package="$(erl_epub_package_path "$source_path")"
      [[ -n "$package" ]] || { rm -rf -- "$tmp_dir"; return 1; }
      unzip -p "$source_path" "$package" > "$tmp_dir/package.opf" 2>/dev/null || { rm -rf -- "$tmp_dir"; return 1; }
      package_dir="${package:h}"
      [[ "$package_dir" == . ]] && package_dir=""
      idrefs=("${(@f)$(xmllint --xpath '//*[local-name()="spine"]/*[local-name()="itemref"]/@idref' "$tmp_dir/package.opf" 2>/dev/null | sed -E 's/[[:space:]]*idref="([^"]+)"/\1\n/g' | sed '/^$/d')}")
      for idref in "${idrefs[@]}"; do
        href="$(xmllint --xpath "string((//*[local-name()='manifest']/*[local-name()='item'][@id='$idref'])[1]/@href)" "$tmp_dir/package.opf" 2>/dev/null)"
        [[ -n "$href" ]] || continue
        locator="${package_dir:+$package_dir/}$href"
        (( order++ ))
        unzip -p "$source_path" "$locator" > "$tmp_dir/chapter.xhtml" 2>/dev/null || continue
        title="$(xmllint --html --recover --xpath 'normalize-space(string((//*[local-name()="h1"]|//*[local-name()="title"])[1]))' "$tmp_dir/chapter.xhtml" 2>/dev/null)"
        [[ -n "$title" ]] || title="Chapter $order"
        rows+=("$(jq -cn --arg locator "$locator" --arg title "$title" --argjson order "$order" '{chapter_locator:$locator,title:$title,source_order:$order}')")
      done
      rm -rf -- "$tmp_dir"
      (( ${#rows} > 0 )) || return 1
      printf '%s\n' "${rows[@]}" | jq -s .
      ;;
    txt|md|markdown|html|htm|xhtml)
      jq -cn --arg locator "${source_path:t}" --arg title "Chapter 1" '[{chapter_locator:$locator,title:$title,source_order:1}]'
      ;;
    *) return 1 ;;
  esac
}

erl_source_chapter_content() {
  local source_path="$1" locator="$2" suffix tmp
  suffix="${source_path:e:l}"
  case "$suffix" in
    epub)
      tmp="$(mktemp "${TMPDIR:-/tmp}/erl-chapter.XXXXXX.xhtml")" || return 1
      unzip -p "$source_path" "$locator" > "$tmp" 2>/dev/null || { rm -f -- "$tmp"; return 1; }
      if command -v textutil >/dev/null 2>&1; then
        textutil -convert txt -stdout "$tmp" 2>/dev/null
      else
        sed -E 's/<[^>]+>/ /g; s/&nbsp;/ /g; s/&amp;/\&/g' "$tmp"
      fi
      rm -f -- "$tmp"
      ;;
    html|htm|xhtml)
      if command -v textutil >/dev/null 2>&1; then textutil -convert txt -stdout "$source_path" 2>/dev/null; else sed -E 's/<[^>]+>/ /g' "$source_path"; fi
      ;;
    *) cat -- "$source_path" ;;
  esac
}
