## ADDED Requirements

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

## MODIFIED Requirements

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
