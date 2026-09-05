## MODIFIED Requirements

### Requirement: ERL-DOC-005 — Preserve book-title key-topic host semantics

ERL MUST сохранять canonical host semantics атрибута `:key-topic:` и MUST NOT использовать его как скрытый ERL foreign key. Для ERL Book grouping canonical host value MUST быть exact canonical title книги; Book Topic, её Chapters и создаваемые в них Memo используют этот title как человекочитаемую тематическую группу.

#### Scenario: Book Topic uses key-topic

- **GIVEN** canonical Topic используется как ERL Book с title `Friday`
- **WHEN** ERL materializes Topic и её Chapters
- **THEN** применимые документы SHALL иметь `:key-topic: Friday`
- **AND** значение SHALL оставаться host-defined human-readable grouping
- **AND** значение SHALL NOT использоваться как WORK_ID, generation identity, Chapter identity или иной ERL-local foreign key
