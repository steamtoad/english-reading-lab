#!/bin/zsh

#------------------------------------------------------------------------------
# erl-agent-routing.zsh
# Тип: ERL live agent smoke test
# Назначение: проверить выбор всех семи skills самой Lexi без выполнения ERL operations
#------------------------------------------------------------------------------

emulate -L zsh
setopt errexit pipe_fail no_unset

if [[ "${ERL_RUN_LIVE_ROUTING:-}" != 1 ]]; then
  print -r -- 'SKIP: set ERL_RUN_LIVE_ROUTING=1 to run the live Lexi routing smoke test'
  exit 0
fi

command -v openclaw >/dev/null || { print -ru2 -- 'FAIL: openclaw CLI is required'; exit 1; }
command -v jq >/dev/null || { print -ru2 -- 'FAIL: jq is required'; exit 1; }

prompt='Routing smoke test only. Do not call tools and do not modify anything. Return exactly one compact JSON object mapping keys book_ingest, chapter_extract, single_ingest, chapter_ingest, book_reduce, classic_reconcile, check to the exact Lexi skill name you would select for: import a local book; extract vocabulary from one chapter; ingest one staged candidate; ingest a full staged chapter; close a generation with dependencies; reconcile after Classic zt-reduce; validate ERL state. No markdown and no explanation.'
output="$(openclaw agent \
  --agent lexi \
  --session-key agent:lexi:erl-routing-smoke \
  --thinking minimal \
  --timeout 180 \
  --json \
  --message "$prompt")"

expected='{
  "book_ingest":"erl-book-ingest",
  "chapter_extract":"erl-chapter-vocabulary-extract",
  "single_ingest":"erl-vocabulary-ingest",
  "chapter_ingest":"erl-chapter-vocabulary-ingest",
  "book_reduce":"erl-book-reduce",
  "classic_reconcile":"erl-classic-reduce-reconcile",
  "check":"erl-check"
}'

jq -e --argjson expected "$expected" '
  .status == "ok" and
  .result.meta.aborted == false and
  (.result.payloads | length) == 1 and
  ((.result.payloads[0].text | fromjson) == $expected)
' <<< "$output" >/dev/null || {
  print -ru2 -- 'FAIL: Lexi did not route all seven intents to the expected skills'
  print -ru2 -- "$output"
  exit 1
}

print -r -- 'PASS: Lexi live routing for all seven ERL skills'
