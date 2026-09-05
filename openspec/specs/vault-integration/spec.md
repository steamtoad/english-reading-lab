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

### Requirement: ERL-DOC-002 — Canonical Vault identity, filename and location

Persistent ERL documents MUST храниться как обычные canonical Vault documents с UUID identity и filename `UUID.adoc` в `<ZETTELKASTEN_HOME>/notes/`.

#### Scenario: Persistent ERL document is stored in Vault

- **WHEN** ERL сохраняет новый persistent document в Vault
- **THEN** документ SHALL иметь canonical Vault UUID
- **AND** filename SHALL соответствовать этому UUID в форме `UUID.adoc`
- **AND** документ SHALL находиться в canonical Vault document namespace

#### Scenario: Persistent ERL document is stored in target home

- **WHEN** ERL сохраняет новый persistent document
- **THEN** документ SHALL иметь canonical Vault UUID
- **AND** filename SHALL соответствовать этому UUID в форме `UUID.adoc`
- **AND** документ SHALL находиться непосредственно в `<ZETTELKASTEN_HOME>/notes/`
- **AND** дополнительный промежуточный `vault/` SHALL NOT использоваться

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

### Requirement: ERL-DOC-005 — Preserve book-title key-topic host semantics

ERL MUST сохранять canonical host semantics атрибута `:key-topic:` и MUST NOT использовать его как скрытый ERL foreign key. Для ERL Book grouping canonical host value MUST быть exact canonical title книги; Book Topic, её Chapters и создаваемые в них Memo используют этот title как человекочитаемую тематическую группу.

#### Scenario: Book Topic uses key-topic

- **GIVEN** canonical Topic используется как ERL Book с title `Friday`
- **WHEN** ERL materializes Topic и её Chapters
- **THEN** применимые документы SHALL иметь `:key-topic: Friday`
- **AND** значение SHALL оставаться host-defined human-readable grouping
- **AND** значение SHALL NOT использоваться как WORK_ID, generation identity, Chapter identity или иной ERL-local foreign key

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

### Requirement: ERL-DOC-008 — All ERL cards contain human-readable AsciiDoc

Каждый persistent ERL document роли Book, Chapter, Vocabulary или Occurrence MUST быть валидным UTF-8 AsciiDoc document, пригодным для непосредственного чтения человеком как самостоятельная карточка.

Карточка MUST иметь понятный document title и непустое body с role-relevant information. Body MUST представлять данные с помощью AsciiDoc sections, paragraphs, description lists и canonical links с осмысленными labels там, где эти элементы применимы. Читателю MUST быть возможно понять назначение карточки и её основное содержимое без чтения persistent ERL state или raw source artifact.

Карточка MUST сохранять применимый canonical и role-specific structural contract. Machine state, raw JSON/YAML serialization, необработанный HTML/XML source, control characters и unresolved template placeholders MUST NOT подменять человекочитаемое body или значения его обязательных полей.

#### Scenario: Book card is created

- **WHEN** ERL создаёт Book Topic
- **THEN** Topic SHALL быть valid UTF-8 AsciiDoc
- **AND** SHALL иметь понятный title и непустое body, идентифицирующее книгу для читателя
- **AND** SHALL представлять navigation или descriptive information как читаемый AsciiDoc, а не raw machine state

#### Scenario: Chapter card is created

- **WHEN** ERL создаёт Chapter Note
- **THEN** Note SHALL быть valid UTF-8 AsciiDoc
- **AND** SHALL иметь понятный chapter title и непустое body с readable book/chapter context
- **AND** source locator или другие технические значения SHALL быть снабжены человекочитаемыми labels, если они показаны в карточке

#### Scenario: Vocabulary card is created

- **WHEN** ERL создаёт Vocabulary Memo
- **THEN** Memo SHALL быть valid UTF-8 AsciiDoc
- **AND** SHALL сохранять lexical card structure согласно `ERL-VOC-003`
- **AND** lexical identity, meaning и доступный context SHALL быть представлены как читаемые labelled fields или prose

#### Scenario: Occurrence card is created

- **WHEN** ERL создаёт Occurrence Memo
- **THEN** Memo SHALL быть valid UTF-8 AsciiDoc
- **AND** SHALL сохранять structural schema согласно `ERL-OCC-004`
- **AND** Vocabulary link SHALL иметь осмысленный label
- **AND** Context section SHALL содержать непустой читаемый context встречи

#### Scenario: Generated content contains machine-oriented artifacts

- **WHEN** обязательное содержимое ERL card состоит из raw serialization, необработанного source markup, control characters или unresolved placeholder
- **THEN** card SHALL NOT считаться соответствующей human-readable AsciiDoc contract

### Requirement: ERL-HOME-001 — Persistent ERL data uses target Zettelkasten home

ERL MUST использовать единый target Zettelkasten home как корень canonical documents и persistent ERL state.

Внутри target Zettelkasten home canonical Topic, Note и Memo MUST храниться в `notes/`, а ERL state MUST храниться в `.state/erl/`. ERL MUST NOT добавлять промежуточный каталог `vault/`.

#### Scenario: ERL creates a canonical document

- **GIVEN** target Zettelkasten home разрешён как `<ZETTELKASTEN_HOME>`
- **WHEN** ERL создаёт Book Topic, Chapter Note, Vocabulary Memo или Occurrence Memo
- **THEN** ERL SHALL использовать canonical host object constructor
- **AND** документ SHALL находиться в `<ZETTELKASTEN_HOME>/notes/`
- **AND** ERL SHALL NOT создавать или использовать `<ZETTELKASTEN_HOME>/vault/notes/`

#### Scenario: ERL writes local state

- **GIVEN** target Zettelkasten home разрешён как `<ZETTELKASTEN_HOME>`
- **WHEN** ERL сохраняет persistent или runtime state
- **THEN** state SHALL находиться в `<ZETTELKASTEN_HOME>/.state/erl/`
- **AND** ERL SHALL NOT создавать или использовать `<ZETTELKASTEN_HOME>/vault/.state/erl/`
