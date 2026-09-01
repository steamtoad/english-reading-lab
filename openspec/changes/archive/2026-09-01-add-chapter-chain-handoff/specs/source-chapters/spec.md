## ADDED Requirements

### Requirement: ERL-CHAPTER-016 — Next Chapter reciprocally links the previous Chapter chain tail

Если Chapter имеет completed Memo Chain и существует следующая Chapter того же `SOURCE_ID` в source order, следующая Chapter Note MUST содержать ровно одну reciprocal canonical link на tail Memo предыдущей Chapter.

Link MUST находиться в структурной секции `Reading handoff` и иметь label `Последнее memo предыдущей главы`. Она MUST указывать на tail непосредственно предыдущей Chapter, а не на произвольный Memo generation sequence.

#### Scenario: Previous Chapter chain is completed

- **GIVEN** Chapter имеет completed Memo Chain с определённым tail
- **AND** source state содержит непосредственно следующую Chapter
- **WHEN** Chapter-level ingestion commits handoff
- **THEN** следующая Chapter Note SHALL содержать canonical link на tail Memo
- **AND** link SHALL иметь label `Последнее memo предыдущей главы`
- **AND** duplicate handoff links SHALL NOT создаваться

#### Scenario: Previous Chapter has no Memo Chain

- **GIVEN** предыдущая Chapter не содержит committed Vocabulary/Occurrence nodes
- **WHEN** ERL рассматривает incoming handoff следующей Chapter
- **THEN** следующая Chapter SHALL NOT получать synthetic link на отсутствующий tail

