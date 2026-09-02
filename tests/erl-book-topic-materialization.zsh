#!/bin/zsh

#------------------------------------------------------------------------------
# erl-book-topic-materialization.zsh
# Тип: ERL regression test
# Назначение: проверить canonical Book Topic materialization и rollback
#------------------------------------------------------------------------------

emulate -L zsh
setopt errexit pipe_fail no_unset

repo="${0:A:h:h}"
ingest="$repo/.scripts/erl/erl-book-ingest.zsh"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/erl-book-topic-materialization.XXXXXX")"
trap 'rm -rf -- "$fixture"' EXIT HUP INT TERM
vault="$fixture/vault"
mkdir -p "$vault/notes"
print -r -- 'A short chapter.' > "$fixture/book.txt"
policy_base='{"schema_version":1,"threshold":["C1"],"lexical_types":["word"]}'
policy_identity="$(print -r -- "$policy_base" | jq -cS . | shasum -a 256 | awk '{print "sha256:" $1}')"
print -r -- "$policy_base" | jq --arg identity "$policy_identity" '.+{identity:$identity}' > "$fixture/policy.json"

export ERL_HOST_HOME="$repo/fixtures/host-contract"
"$ingest" --vault "$vault" --source "$fixture/book.txt" --title 'The Left Hand of Darkness' \
  --key-topic 'English Reading' --policy-file "$fixture/policy.json" --apply --json > "$fixture/result.json"
generation="$(jq -r '.data.generation_uuid' "$fixture/result.json")"
topic="$vault/notes/$generation.adoc"
jq -e '.status=="ok" and .changed==true and .data.created.topics==1' "$fixture/result.json" >/dev/null
[[ "$(awk 'NR==1{sub(/^= /,"");print}' "$topic")" == 'The Left Hand of Darkness' ]]
[[ "$(awk '/^:description:/{sub(/^:description:[[:space:]]*/,"");print;exit}' "$topic")" == 'The Left Hand of Darkness' ]]
[[ "$(awk '/^:doclink:/{sub(/^:doclink:[[:space:]]*/,"");print;exit}' "$topic")" == "link:$generation.adoc[The Left Hand of Darkness]" ]]
[[ "$(awk '/^:key-topic:/{sub(/^:key-topic:[[:space:]]*/,"");print;exit}' "$topic")" == 'English Reading' ]]

# A host constructor that returns a type-compatible but wrongly presented Topic
# must not publish generation state and its provisional document is rolled back.
fault_host="$fixture/fault-host"
mkdir -p "$fault_host/.scripts/objects"
cp "$repo/fixtures/host-contract/.scripts/objects/_test-object-create.zsh" "$fault_host/.scripts/objects/"
cp "$repo/fixtures/host-contract/.scripts/objects/note-create.zsh" "$fault_host/.scripts/objects/"
cp "$repo/fixtures/host-contract/.scripts/objects/topic-create.zsh" "$fault_host/.scripts/objects/"
sed -i.bak 's/title="$1"/title="Wrong presentation"/' "$fault_host/.scripts/objects/_test-object-create.zsh"
rm -f -- "$fault_host/.scripts/objects/_test-object-create.zsh.bak"
chmod +x "$fault_host/.scripts/objects/"*.zsh
fault_vault="$fixture/fault-vault"
mkdir -p "$fault_vault/notes"
set +e
ERL_HOST_HOME="$fault_host" "$ingest" --vault "$fault_vault" --source "$fixture/book.txt" --title 'Expected Book' \
  --key-topic 'English Reading' --policy-file "$fixture/policy.json" --apply --json > "$fixture/fault.json"
fault_rc=$?
set -e
[[ "$fault_rc" == 60 ]]
jq -e '.status=="error" and .code=="TRANSACTION_FAILED" and .changed==false and (.data.generation_uuid? == null)' "$fixture/fault.json" >/dev/null
[[ "$(find "$fault_vault/notes" -type f | wc -l | tr -d ' ')" == 0 ]]
[[ "$(find "$fault_vault/.state/erl/works" -type f 2>/dev/null | wc -l | tr -d ' ')" == 0 ]]

print -r -- 'PASS: Book Topic materialization'
