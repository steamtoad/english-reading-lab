# vault-integration Specification

## Purpose

Определить контракт интеграции English Reading Lab с canonical Zettelkasten Vault: используемые типы документов, metadata, identity, роли документов и формат внутренних ссылок без введения ERL-specific Vault semantics.

## Requirements

### Requirement: ERL-DOC-001 — Canonical Vault document types

ERL MUST использовать только существующие canonical document types Zettelkasten Vault для persistent ERL documents.

#### Scenario: ERL role maps to canonical document type

- **GIVEN** ERL создаёт persistent document для одной из своих domain roles
- **WHEN** роль документа определяется как Book, Chapter, Vocabulary или Occurrence
- **THEN** Book SHALL быть представлен canonical Topic
- **AND** Chapter SHALL быть представлен canonical Note
- **AND** Vocabulary SHALL быть представлен canonical Memo
- **AND** Occurrence SHALL быть представлен canonical Memo

### Requirement: ERL-DOC-002 — Canonical Vault identity and filename

Persistent ERL documents MUST храниться как обычные canonical Vault documents с UUID identity и filename `UUID.adoc` в canonical Vault namespace.

#### Scenario: Persistent ERL document is stored in Vault

- **WHEN** ERL сохраняет новый persistent document в Vault
- **THEN** документ SHALL иметь canonical Vault UUID
- **AND** filename SHALL соответствовать этому UUID в форме `UUID.adoc`
- **AND** документ SHALL находиться в canonical Vault document namespace

### Requirement: ERL-DOC-003 — Host-defined AsciiDoc attributes only

Persistent ERL documents MUST использовать только AsciiDoc attributes, определённые canonical host contract.

#### Scenario: ERL creates document metadata

- **WHEN** ERL создаёт или обновляет persistent Vault document
- **THEN** metadata SHALL использовать только attributes, разрешённые canonical host contract
- **AND** ERL SHALL NOT вводить собственные metadata fields вне host contract

### Requirement: ERL-DOC-004 — No ERL-specific AsciiDoc attributes

ERL MUST NOT создавать plugin-specific AsciiDoc attributes для хранения ERL identity, relationships, lifecycle или sequence semantics.

#### Scenario: Persistent document is written by ERL

- **WHEN** ERL записывает persistent Vault document
- **THEN** документ SHALL NOT содержать ERL-specific attributes вида `:erl-*:`
- **AND** ERL SHALL NOT создавать `:erl-kind:`, `:erl-work-id:`, `:erl-book:`, `:erl-chapter:` или `:erl-sequence:`

### Requirement: ERL-DOC-005 — Preserve key-topic host semantics

ERL MUST сохранять canonical host semantics атрибута `:key-topic:` и MUST NOT использовать его как скрытый ERL foreign key.

#### Scenario: Book Topic uses key-topic

- **GIVEN** canonical Topic используется как ERL Book
- **WHEN** Topic содержит `:key-topic:`
- **THEN** значение SHALL сохранять host-defined thematic semantics
- **AND** значение SHALL NOT использоваться как WORK_ID, generation identity, Chapter identity, sequence identity или другой ERL-local foreign key

### Requirement: ERL-DOC-006 — ERL role resolution

ERL MUST определять domain role persistent Vault document по сочетанию canonical `:type:`, persistent ERL work state и structural contract тела документа.

#### Scenario: Memo role is resolved

- **GIVEN** canonical Memo может представлять Vocabulary или Occurrence
- **WHEN** ERL определяет domain role этого Memo
- **THEN** одного canonical `:type:` SHALL быть недостаточно для различения этих ролей
- **AND** ERL SHALL использовать persistent work state и соответствующий structural body contract

### Requirement: ERL-DOC-007 — Canonical internal links

ERL MUST использовать canonical Vault internal link format `link:UUID.adoc[Description]`.

#### Scenario: ERL emits an internal document link

- **WHEN** ERL создаёт внутреннюю ссылку на persistent Vault document
- **THEN** ссылка SHALL иметь формат `link:UUID.adoc[Description]`
- **AND** UUID SHALL быть canonical identity target document
