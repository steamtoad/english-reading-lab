## ADDED Requirements

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

