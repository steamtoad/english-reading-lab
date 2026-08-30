# deprecation Specification

## Purpose

Определить использование canonical Vault deprecation semantics в English Reading Lab: поведение deprecated documents, их участие в active workflows и сохранение historical/audit information.

## Requirements

### Requirement: ERL-DEP-001 — Canonical deprecation semantics

ERL MUST использовать canonical host `:deprecated:` semantics и MUST NOT вводить отдельный ERL-specific archive или deprecation flag.

#### Scenario: ERL marks a document as deprecated

- **WHEN** ERL lifecycle operation переводит canonical Vault document в deprecated state
- **THEN** состояние SHALL выражаться через canonical host `:deprecated:` semantics
- **AND** ERL SHALL NOT создавать параллельный ERL-specific archive или deprecation flag

### Requirement: ERL-DEP-002 — Deprecated documents are immutable to new ERL workflows

Deprecated documents MUST NOT изменяться новыми ERL workflows и MUST NOT получать новые ERL links.

#### Scenario: Workflow encounters a deprecated document

- **GIVEN** canonical Vault document является deprecated
- **WHEN** новый ERL workflow обрабатывает связанный work или generation
- **THEN** workflow SHALL NOT изменять deprecated document
- **AND** workflow SHALL NOT добавлять в него новые ERL links

### Requirement: ERL-DEP-003 — Deprecated Vocabulary excluded from active lookup

Deprecated Vocabulary MUST NOT участвовать в active Vocabulary lookup или deduplication.

#### Scenario: Deprecated Vocabulary matches lexical identity

- **GIVEN** deprecated Vocabulary имеет ту же lexical identity, что и новый Candidate
- **WHEN** ERL выполняет active Vocabulary lookup или deduplication
- **THEN** deprecated Vocabulary SHALL быть исключён из набора active lookup candidates

### Requirement: ERL-DEP-004 — Deprecated documents excluded from active sequences

Deprecated documents MUST NOT входить в новые active reading sequences.

#### Scenario: Active sequence is constructed

- **WHEN** ERL создаёт или продолжает active reading sequence
- **THEN** ни один deprecated Vault document SHALL NOT быть добавлен как active sequence node

### Requirement: ERL-DEP-005 — Historical documents and committed audit record are retained

Deprecated Vault documents MUST сохраняться как historical artifacts.

Для generation, успешно закрытой через `erl-book-reduce`, ERL MUST сохранять compact committed transaction manifest/result для audit и MUST удалить generation-specific operational metadata из `.state/erl/works/` согласно `ERL-REDUCE-025`.

#### Scenario: Book generation is successfully closed

- **GIVEN** Book generation успешно закрыта через `erl-book-reduce`
- **WHEN** transaction достигает committed state
- **THEN** deprecated Vault documents SHALL сохраняться как historical artifacts
- **AND** compact committed transaction manifest/result SHALL сохраняться для audit
- **AND** generation-specific operational metadata SHALL быть удалена из `.state/erl/works/` согласно `ERL-REDUCE-025`
