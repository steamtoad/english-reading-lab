# occurrence Specification

## Purpose

Определить canonical Occurrence model English Reading Lab: представление Occurrence как Memo, условие создания при встрече существующего active Vocabulary, structural role, связь с target Vocabulary, context текущей встречи, sequence semantics и запрет создания на deprecated target.

## Requirements

### Requirement: ERL-OCC-001 — Occurrence is a canonical Memo

Occurrence MUST быть представлен canonical Memo.

#### Scenario: Occurrence is persisted

- **WHEN** ERL создаёт persistent Occurrence
- **THEN** Occurrence SHALL быть canonical Memo

### Requirement: ERL-OCC-002 — Occurrence Memo has no ERL-specific attributes

Occurrence Memo MUST NOT получать ERL-specific attributes.

#### Scenario: Occurrence Memo is persisted

- **WHEN** ERL создаёт или обновляет Occurrence Memo
- **THEN** Memo SHALL NOT получать ERL-specific attributes

### Requirement: ERL-OCC-003 — Existing active Vocabulary produces an Occurrence

Occurrence MUST создаваться, если Candidate соответствует существующему active Vocabulary.

#### Scenario: Candidate matches active Vocabulary

- **GIVEN** Candidate соответствует существующему active Vocabulary
- **WHEN** ERL ingests Candidate
- **THEN** ERL SHALL создать Occurrence

### Requirement: ERL-OCC-004 — Occurrence role is determined by persistent state and structural schema

Occurrence role MUST определяться persistent work state и обязательной structural schema.

Минимальная schema MUST иметь структуру:

    == Vocabulary

    link:VOCABULARY-UUID.adoc[Description]

    == Context

    ...

#### Scenario: Memo is resolved as Occurrence

- **GIVEN** persistent work state определяет canonical Memo как Occurrence
- **WHEN** ERL проверяет structural schema документа
- **THEN** Memo SHALL содержать `Vocabulary` section
- **AND** Memo SHALL содержать `Context` section

### Requirement: ERL-OCC-005 — Vocabulary section contains exactly one canonical internal link

`Vocabulary` section MUST содержать ровно одну canonical internal link на target Vocabulary.

#### Scenario: Vocabulary target is recorded

- **WHEN** ERL создаёт или проверяет Occurrence
- **THEN** `Vocabulary` section SHALL содержать ровно одну canonical internal link
- **AND** link SHALL указывать на target Vocabulary

### Requirement: ERL-OCC-006 — Context section stores the current lexical encounter

`Context` section MUST хранить context текущей встречи lexical item.

#### Scenario: Occurrence context is persisted

- **WHEN** ERL создаёт Occurrence для текущей встречи lexical item
- **THEN** `Context` section SHALL содержать context этой встречи

### Requirement: ERL-OCC-007 — Occurrence is a sequence node but not a canonical lexical object

Occurrence MUST быть самостоятельным sequence node.

Occurrence MUST NOT являться новым canonical lexical object.

#### Scenario: Occurrence participates in reading sequence

- **WHEN** Occurrence включается в persistent reading sequence
- **THEN** Occurrence SHALL быть самостоятельным sequence node
- **AND** SHALL NOT рассматриваться как новый canonical lexical object

### Requirement: ERL-OCC-008 — Occurrence is not created for deprecated Vocabulary

Новый Occurrence MUST NOT создаваться на deprecated Vocabulary target.

#### Scenario: Candidate resolves to deprecated Vocabulary

- **GIVEN** target Vocabulary является deprecated
- **WHEN** ERL рассматривает создание нового Occurrence
- **THEN** новый Occurrence SHALL NOT создаваться на этот Vocabulary target
