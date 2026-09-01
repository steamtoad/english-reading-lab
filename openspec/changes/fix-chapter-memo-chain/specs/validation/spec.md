## ADDED Requirements

### Requirement: ERL-CHECK-028 — Chapter Memo attachment and chain are complete and reciprocal

`erl-check` MUST read-only проверять для каждого Vocabulary/Occurrence sequence node active generation:

- точное совпадение Memo и Chapter Note `:key-topic:`;
- ровно одну Memo→Chapter link и одну reciprocal Chapter→Memo link;
- соответствие Chapter UUID persistent sequence entry;
- ровно один Chapter-local chain head;
- predecessor/successor reciprocity с labels `Предыдущее memo` и `Следующее memo`;
- соответствие chain order Candidate/source order;
- отсутствие duplicates, branches, cycles и cross-Chapter chain edges.

#### Scenario: Valid Chapter Memo Chain is checked

- **GIVEN** Chapter содержит committed Vocabulary/Occurrence sequence nodes
- **WHEN** ERL выполняет validation
- **THEN** attachment links и `:key-topic:` SHALL соответствовать Chapter Note
- **AND** Memo Chain SHALL быть полной линейной reciprocal projection sequence nodes этой Chapter

#### Scenario: Attachment or chain is inconsistent

- **WHEN** key values различаются, attachment односторонняя, state Chapter UUID не совпадает, chain link односторонняя, head неоднозначен, существует branch/cycle/duplicate или edge пересекает Chapter boundary
- **THEN** `erl-check` SHALL вернуть validation error с конкретной причиной
- **AND** SHALL указать generation UUID, Chapter UUID и затронутые Memo UUID
- **AND** SHALL NOT изменять Vault documents или persistent state

