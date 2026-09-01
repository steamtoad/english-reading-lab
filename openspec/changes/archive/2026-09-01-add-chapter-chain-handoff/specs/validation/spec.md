## ADDED Requirements

### Requirement: ERL-CHECK-029 — Chapter chain handoff is reciprocal and follows source order

`erl-check` MUST read-only проверять для каждой completed Chapter Memo Chain:

- outgoing handoff tail Memo→next Chapter Note;
- reciprocal incoming handoff next Chapter Note→tail Memo;
- exact source-order adjacency Chapters внутри одного `SOURCE_ID`;
- uniqueness обеих links;
- отсутствие handoff у последней Chapter и Chapter без Memo Chain;
- отсутствие stale handoff от node, который не является current tail.

#### Scenario: Valid handoff is checked

- **GIVEN** Chapter имеет completed Memo Chain и непосредственно следующую Chapter
- **WHEN** ERL выполняет validation
- **THEN** tail и next Chapter SHALL содержать reciprocal canonical handoff links
- **AND** targets SHALL соответствовать adjacent Chapters в source order

#### Scenario: Handoff is missing, stale, duplicated or points outside adjacency

- **WHEN** одна сторона handoff отсутствует, link дублируется, source/Chapter adjacency не совпадает, outgoing Memo не является tail либо terminal Chapter имеет handoff
- **THEN** `erl-check` SHALL вернуть validation error с конкретной причиной
- **AND** SHALL указать generation UUID, source ID, current Chapter UUID, next Chapter UUID и tail Memo UUID, когда они доступны
- **AND** SHALL NOT изменять Vault documents или persistent state

