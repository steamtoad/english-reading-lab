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

### Requirement: ERL-SEQ-012 — Chapter chain tail links to the next Chapter

После completed Chapter-level ingestion tail Memo текущей Chapter MUST содержать ровно одну canonical link на непосредственно следующую Chapter Note того же source в source order.

Link MUST находиться в структурной секции `Reading handoff` и иметь label `Следующая глава`. Reciprocal link на следующей Chapter Note MUST соответствовать `ERL-CHAPTER-016`.

Handoff MUST соединять tail Memo с Chapter Note и MUST NOT соединять две Chapter-local Memo Chains напрямую.

#### Scenario: Chapter with a Memo tail has a next Chapter

- **GIVEN** текущая Chapter имеет completed Memo Chain
- **AND** source state содержит непосредственно следующую Chapter
- **WHEN** Chapter-level ingestion завершается успешно
- **THEN** tail Memo SHALL содержать `Следующая глава` link на следующую Chapter Note
- **AND** следующая Chapter SHALL содержать reciprocal link на tail Memo
- **AND** первая Memo следующей Chapter SHALL оставаться head отдельной chain без predecessor из предыдущей Chapter

#### Scenario: Current Chapter is the last source Chapter

- **GIVEN** current Chapter является последней Chapter данного source
- **WHEN** Chapter-level ingestion завершается успешно
- **THEN** tail Memo SHALL NOT получать `Следующая глава` handoff link
- **AND** отсутствие handoff SHALL считаться valid terminal state

### Requirement: ERL-SEQ-013 — Chapter handoff is committed with batch completion

Chapter→next-Chapter handoff MUST вычисляться только после завершения всех Candidates текущего extraction batch, когда tail Memo окончательно определён.

Tail Memo update, next Chapter Note update и completed Chapter-level ingestion result MUST быть одной recoverable semantic operation. Partial или stale handoff MUST приводить к rollback или `RECOVERY_REQUIRED` и MUST NOT считаться completed handoff.

#### Scenario: Handoff mutation fails after tail update

- **GIVEN** tail Memo получила outgoing handoff link
- **WHEN** reciprocal next Chapter update или batch commit завершается ошибкой
- **THEN** outgoing link SHALL быть rolled back или transaction SHALL остаться recoverable
- **AND** one-sided handoff SHALL NOT считаться committed

#### Scenario: Completed batch is retried

- **GIVEN** reciprocal handoff уже committed для completed Chapter batch
- **WHEN** тот же batch запускается повторно
- **THEN** additional handoff links SHALL NOT создаваться
- **AND** existing reciprocal pair SHALL оставаться неизменной

### Requirement: ERL-SEQ-009 — Each Chapter materializes its own Memo Chain

Persistent generation reading sequence MUST иметь canonical Vault projection как отдельная линейная Memo Chain внутри каждой Chapter.

Chapter-local chain MUST включать Vocabulary и Occurrence nodes этой Chapter в Candidate/source order. Она MUST начинаться заново для первой Memo каждой следующей Chapter и MUST NOT соединять последнюю Memo предыдущей Chapter с первой Memo следующей Chapter.

#### Scenario: Chapter contains multiple sequence nodes

- **GIVEN** Chapter ingestion создаёт несколько Vocabulary/Occurrence nodes
- **WHEN** ERL materializes Chapter Memo Chain
- **THEN** chain SHALL содержать все nodes этой Chapter в Candidate/source order
- **AND** SHALL быть линейной без branches или cycles

#### Scenario: Next Chapter starts its own chain

- **GIVEN** предыдущая Chapter уже имеет Memo Chain
- **WHEN** создаётся первая Memo следующей Chapter
- **THEN** новая Memo SHALL стать head отдельной Chapter-local chain
- **AND** SHALL NOT получать predecessor из предыдущей Chapter
- **AND** generation reading sequence SHALL продолжаться согласно `ERL-SEQ-005`

### Requirement: ERL-SEQ-010 — First Memo is the Chapter chain head

Первый Vocabulary или Occurrence Memo в Candidate/source order текущей Chapter MUST начинать Memo Chain.

Chain head MUST NOT содержать link с label `Предыдущее memo`. Если Chapter содержит только один node, он MUST быть одновременно head и tail и MUST NOT содержать `Следующее memo`.

#### Scenario: First Memo is created for a Chapter

- **WHEN** ERL создаёт первый sequence node Chapter
- **THEN** node SHALL стать chain head
- **AND** SHALL NOT содержать `Предыдущее memo`

#### Scenario: Chapter has exactly one Memo

- **WHEN** Chapter ingestion завершается с одним sequence node
- **THEN** единственный Memo SHALL не содержать ни `Предыдущее memo`, ни `Следующее memo`

### Requirement: ERL-SEQ-011 — Subsequent Memos use reciprocal Continue-style links

Каждый последующий Vocabulary или Occurrence Memo текущей Chapter MUST быть связан с непосредственно предыдущим node reciprocal canonical links по линейной семантике `zt-continue`.

Новый Memo MUST содержать ровно одну link на predecessor с label `Предыдущее memo`. Predecessor MUST содержать ровно одну reciprocal link на новый Memo с label `Следующее memo`. Один node MUST иметь не более одного predecessor и не более одного successor внутри Chapter chain.

#### Scenario: Another Memo is appended to Chapter chain

- **GIVEN** Chapter имеет committed tail Memo
- **WHEN** ERL добавляет следующий Vocabulary или Occurrence node
- **THEN** новый Memo SHALL содержать `Предыдущее memo` link на прежний tail
- **AND** прежний tail SHALL содержать `Следующее memo` link на новый Memo
- **AND** новый Memo SHALL стать новым tail

#### Scenario: Candidate ingestion is retried

- **GIVEN** reciprocal predecessor/successor pair уже committed
- **WHEN** тот же Candidate ingestion повторяется
- **THEN** дополнительные chain links SHALL NOT создаваться
- **AND** chain topology SHALL оставаться неизменной
