#!/bin/zsh

#------------------------------------------------------------------------------
# ZT-Inbox
# Тип: inbox utility
# Назначение: создать новый элемент в inbox/raw
#------------------------------------------------------------------------------

emulate -L zsh
setopt nounset

zmodload zsh/system || {
    print -u2 "Error: zsh/system is required"
    exit 1
}

SCRIPT_DIR="${0:A:h}"
ZK_ROOT="${ZK_HOME:-${ZETTELKASTEN_ROOT:-${SCRIPT_DIR:h}}}"

INBOX_DIR="${ZK_ROOT}/inbox"
RAW_DIR="${INBOX_DIR}/raw"

EDITOR_CMD="${EDITOR:-vim}"

usage() {
    print -u2 "Usage: ${0:t} \"Title\""
}

die() {
    print -u2 "Error: $*"
    exit 1
}

[[ $# -ge 1 ]] || {
    usage
    exit 1
}

title="$*"

[[ -n "${title//[[:space:]]/}" ]] || die "title must not be empty"
[[ "$title" != *$'\n'* && "$title" != *$'\r'* ]] ||
    die "title must be a single line"

mkdir -p "$RAW_DIR" || die "cannot create directory: $RAW_DIR"

timestamp="$(date '+%Y-%m-%d-%H%M%S')"
captured_at="$(date '+%Y-%m-%dT%H:%M:%S%z')"

sequence=0

# sysopen с O_EXCL защищает от гонки и не печатает ложную ошибку при обычной
# коллизии timestamp.
while true; do
    if (( sequence == 0 )); then
        filename="${timestamp}.adoc"
    else
        filename="${timestamp}-${sequence}.adoc"
    fi

    filepath="${RAW_DIR}/${filename}"

    if sysopen -w -o creat,excl -u capture_fd "$filepath" 2>/dev/null; then
        if ! {
            print -u "$capture_fd" -r -- "= ${title}"
            print -u "$capture_fd" -r -- ":captured-at: ${captured_at}"
            print -u "$capture_fd" -r -- ":source: manual"
            print -u "$capture_fd" -r -- ""
        }; then
            exec {capture_fd}>&-
            rm -f "$filepath"
            die "cannot write file: $filepath"
        fi

        exec {capture_fd}>&-
        break
    fi

    [[ -e "$filepath" ]] || die "cannot create file: $filepath"
    (( sequence++ ))
done

[[ -f "$filepath" ]] || die "cannot create file: $filepath"

editor_words=(${(z)EDITOR_CMD})
(( ${#editor_words[@]} > 0 )) || die "EDITOR must not be empty"
command -v "${editor_words[1]}" >/dev/null 2>&1 ||
    die "editor not found: ${editor_words[1]}"

print -r -- "$filepath"

exec "${editor_words[@]}" "$filepath"
