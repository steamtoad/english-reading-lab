# reading-sequence Specification

## Purpose

Определить reading sequence contract English Reading Lab: membership Vocabulary и Occurrence nodes, принадлежность sequence конкретной Book generation, persistent representation, source ordering, continuation между Chapters, ordinal semantics, reconstructability и lifecycle active/closed sequence.

## Requirements

### Requirement: ERL-SEQ-001 — Vocabulary and Occurrence are equal sequence nodes

Vocabulary и Occurrence MUST являться равноправными nodes reading sequence.

#### Scenario: Reading sequence contains Vocabulary and Occurrence

- **WHEN** ERL формирует reading sequence
- **THEN** Vocabulary SHALL участвовать в sequence как самостоятельный node
- **AND** Occurrence SHALL участвовать в sequence как самостоятельный node
- **AND** оба типа nodes SHALL быть равноправны в reading sequence

### Requirement: ERL-SEQ-002 — Reading sequence belongs to a Book generation

Reading sequence MUST принадлежать конкретной Book generation.

#### Scenario: Reading sequence ownership is determined

- **WHEN** ERL определяет ownership reading sequence
- **THEN** sequence SHALL принадлежать конкретной Book generation

### Requirement: ERL-SEQ-003 — Sequence is stored in persistent generation state

Reading sequence MUST храниться в persistent generation state и MUST NOT храниться в AsciiDoc attributes.

#### Scenario: Reading sequence is persisted

- **WHEN** ERL сохраняет reading sequence
- **THEN** sequence SHALL храниться в persistent generation state
- **AND** SHALL NOT храниться в AsciiDoc attributes

### Requirement: ERL-SEQ-004 — Sequence follows source order

Reading sequence MUST строиться в source order.

#### Scenario: Sequence entries are ordered

- **WHEN** ERL формирует reading sequence
- **THEN** sequence entries SHALL быть расположены в source order

### Requirement: ERL-SEQ-005 — Next Chapter continues the active generation sequence

Обработка следующей Chapter MUST продолжать reading sequence текущей active generation.

#### Scenario: Next Chapter is processed in the active generation

- **GIVEN** текущая active Book generation уже содержит reading sequence
- **WHEN** ERL обрабатывает следующую Chapter этой generation
- **THEN** новые sequence entries SHALL продолжать существующую reading sequence
- **AND** sequence SHALL NOT начинаться заново на границе Chapter

### Requirement: ERL-SEQ-006 — Sequence ordinal and Candidate ordinal are distinct

Sequence ordinal и Candidate ordinal MUST считаться разными понятиями.

#### Scenario: Candidate becomes a persistent sequence node

- **WHEN** Candidate приводит к созданию persistent reading-sequence node
- **THEN** Candidate ordinal SHALL NOT считаться sequence ordinal
- **AND** sequence ordinal SHALL иметь самостоятельную семантику

### Requirement: ERL-SEQ-007 — Sequence is reconstructable from persistent state

Reading sequence MUST быть полностью восстанавливаема из `.state/erl/works/` и существующих Vault UUID, без `cache/` и `staging/`.

#### Scenario: Reading sequence is reconstructed

- **WHEN** ERL восстанавливает reading sequence
- **THEN** sequence SHALL быть полностью восстанавливаема из `.state/erl/works/` и существующих Vault UUID
- **AND** reconstruction SHALL NOT требовать `cache/`
- **AND** reconstruction SHALL NOT требовать `staging/`

### Requirement: ERL-SEQ-008 — Deprecated documents are excluded from active sequence

Deprecated documents MUST NOT входить в active reading sequence.

После успешного `erl-book-reduce` historical membership/ordinal MUST NOT сохраняться в `.state/erl/works/`.

Audit закрытой sequence MUST обеспечиваться deprecated Vault documents и обязательным compact committed transaction manifest/result, который MUST NOT удаляться обычной очисткой transaction backups.

#### Scenario: Deprecated document is considered for active sequence membership

- **GIVEN** Vault document является deprecated
- **WHEN** ERL определяет active reading sequence
- **THEN** document SHALL NOT входить в active reading sequence

#### Scenario: Successful Reduce closes historical sequence state

- **GIVEN** `erl-book-reduce` успешно завершён для Book generation
- **WHEN** ERL рассматривает historical reading-sequence state этой generation
- **THEN** historical membership/ordinal SHALL NOT сохраняться в `.state/erl/works/`
- **AND** audit закрытой sequence SHALL обеспечиваться deprecated Vault documents и compact committed transaction manifest/result
- **AND** compact committed transaction manifest/result SHALL NOT удаляться обычной очисткой transaction backups
