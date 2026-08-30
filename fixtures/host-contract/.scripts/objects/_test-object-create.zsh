#!/bin/zsh

# Test-scoped host contract double. Never use as a production fallback.

emulate -L zsh
setopt errexit no_unset pipe_fail

object_type="$1"; shift
title="$1"; shift
key_topic=""
if [[ "$object_type" == topic ]]; then key_topic="$1"; shift; fi
keywords="${1:-$object_type}"
description="${2:-$title}"
vault="${ZK_HOME:?ZK_HOME is required by the test host contract}"
mkdir -p -- "$vault/notes"
if command -v uuid >/dev/null 2>&1; then
  document_uuid="$(uuid | tr '[:upper:]' '[:lower:]')"
elif command -v uuidgen >/dev/null 2>&1; then
  document_uuid="$(uuidgen -t 2>/dev/null || uuidgen)"; document_uuid="${document_uuid:l}"
else
  print -ru2 -- 'ERROR test host contract requires uuid or uuidgen'
  exit 1
fi
filename="$document_uuid.adoc"; target="$vault/notes/$filename"
[[ ! -e "$target" ]] || { print -ru2 -- "ERROR target already exists: $target"; exit 1; }
{
  print -r -- "= $title"
  print -r -- ":date: ${ERL_TEST_DATE:-2026-08-30}"
  print -r -- ":keywords: $keywords"
  print -r -- ":type: $object_type"
  print -r -- ":author: ${USER:-test}"
  print -r -- ":description: $description"
  print -r -- ":doclink: link:${filename}[$description]"
  print -r -- ":docfilename: $filename"
  [[ "$object_type" == topic ]] && print -r -- ":key-topic: $key_topic"
  print -r -- ""
  print -r -- ""
} > "$target"
print -r -- "$filename"
