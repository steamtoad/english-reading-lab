#!/bin/zsh

#------------------------------------------------------------------------------
# erl-book-title-key-topic-integration-fixtures.zsh
# Тип: ERL primary regression test
# Назначение: проверить title-derived key-topic в существующих integration fixtures
#------------------------------------------------------------------------------

emulate -L zsh
setopt errexit pipe_fail no_unset

repo="${0:A:h:h}"

"$repo/tests/erl-human-readable-card-content.zsh"
"$repo/tests/erl-chapter-chain-handoff.zsh"

print -r -- 'PASS: Book title key-topic integration fixtures'
