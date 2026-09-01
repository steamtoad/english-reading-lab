#!/usr/bin/env zsh

#------------------------------------------------------------------------------
# erl-chapter-vocabulary-quota.zsh
# Тип: ERL OpenSpec regression test
# Назначение: проверить отсутствие Candidate quota в Chapter extraction policy
#------------------------------------------------------------------------------

set -euo pipefail

repo="${0:A:h:h}"
spec="$repo/openspec/changes/remove-chapter-vocabulary-quota/specs/vocabulary-extraction/spec.md"
legacy="$repo/.scripts/erl/docs/requirements.md"

rg -q 'ERL-CAND-010 — Chapter extraction has no Candidate quota' "$spec"
rg -q 'MUST NOT ограничивать число подходящих Vocabulary Candidates' "$spec"
rg -q 'каждый соответствующий policy уникальный lexical identity SHALL быть представлен Candidate' "$spec"
rg -q '^ERL-CAND-010$' "$legacy"

print -r -- 'PASS: Chapter extraction has no Candidate quota'
