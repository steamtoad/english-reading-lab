#!/bin/zsh

#------------------------------------------------------------------------------
# ZT-Processed
# Тип: inbox utility
# Назначение: переместить обработанный элемент из inbox/raw в inbox/processed
#------------------------------------------------------------------------------

emulate -L zsh
setopt nounset

SCRIPT_DIR="${0:A:h}"
ZK_ROOT="${ZK_HOME:-${ZETTELKASTEN_ROOT:-${SCRIPT_DIR:h}}}"

INBOX_DIR="${ZK_ROOT}/inbox"
RAW_DIR="${INBOX_DIR}/raw"
PROCESSED_DIR="${INBOX_DIR}/processed"

usage() {
    print -u2 "Usage: ${0:t} FILE"
}

die() {
    print -u2 "Error: $*"
    exit 1
}

[[ $# -eq 1 ]] || {
    usage
    exit 1
}

input="$1"

mkdir -p "$RAW_DIR" "$PROCESSED_DIR" ||
    die "cannot create inbox directories"

# Можно передать как basename:
#
#   ZT-Processed 2026-08-25-230100.adoc
#
# либо полный путь.
if [[ "$input" == */* ]]; then
    source_file="${input:A}"
else
    source_file="${RAW_DIR}/${input}"
    source_file="${source_file:A}"
fi

raw_dir="${RAW_DIR:A}"
processed_dir="${PROCESSED_DIR:A}"

[[ -f "$source_file" ]] ||
    die "file does not exist: $source_file"

# Обрабатываются только непосредственные файлы inbox/raw. Разрешение :A также
# не позволяет провести symlink наружу через эту проверку.
[[ "${source_file:h}" == "$raw_dir" ]] ||
    die "file is outside inbox/raw: $source_file"

filename="${source_file:t}"
destination="${processed_dir}/${filename}"

# hard link создаётся атомарно и не перезаписывает существующее назначение.
# raw и processed находятся внутри одного Inbox и должны быть на одном FS.
if ! ln "$source_file" "$destination"; then
    [[ -e "$destination" ]] &&
        die "destination already exists: $destination"
    die "cannot create processed file: $destination"
fi

if ! rm "$source_file"; then
    rm -f "$destination"
    die "cannot remove source after processing: $source_file"
fi

print -r -- "$destination"
