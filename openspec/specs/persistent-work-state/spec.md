# persistent-work-state Specification

## Purpose

Определить persistent work state contract English Reading Lab: хранение ERL relationships вне canonical Vault attributes, минимальные структуры work, source, chapter, generation и sequence state, membership semantics, consistency с Vault documents и требования к эволюции schema.

## Requirements

### Requirement: ERL-WORKSTATE-001 — Persistent work state stores ERL relationships

`.state/erl/works/<work-slug>/` MUST хранить все ERL relationships, которые нельзя надёжно вывести только из canonical Vault document attributes.

#### Scenario: ERL relationship cannot be derived from Vault attributes

- **GIVEN** ERL relationship нельзя надёжно восстановить только из canonical Vault document attributes
- **WHEN** relationship сохраняется как persistent domain state
- **THEN** relationship SHALL храниться в `.state/erl/works/<work-slug>/`

### Requirement: ERL-WORKSTATE-002 — Work manifest has required fields

Work manifest MUST хранить как минимум:

- `WORK_ID`;
- logical work metadata;
- known `SOURCE_ID` records;
- retained Book generation UUIDs;
- active generation pointer/status.

#### Scenario: Work manifest is persisted

- **WHEN** ERL сохраняет Work manifest
- **THEN** manifest SHALL содержать `WORK_ID`
- **AND** SHALL содержать logical work metadata
- **AND** SHALL содержать known `SOURCE_ID` records
- **AND** SHALL содержать retained Book generation UUIDs
- **AND** SHALL содержать active generation pointer/status

### Requirement: ERL-WORKSTATE-003 — Source state has required fields

Source state MUST хранить как минимум:

- `SOURCE_ID`;
- `WORK_ID`;
- source fingerprint;
- Chapter resolution records.

#### Scenario: Source state is persisted

- **WHEN** ERL сохраняет Source state
- **THEN** state SHALL содержать `SOURCE_ID`
- **AND** SHALL содержать `WORK_ID`
- **AND** SHALL содержать source fingerprint
- **AND** SHALL содержать Chapter resolution records

### Requirement: ERL-WORKSTATE-004 — Chapter resolution record has required fields

Chapter resolution record MUST хранить как минимум:

- Chapter UUID;
- `SOURCE_ID`;
- `CHAPTER_LOCATOR`;
- source order.

#### Scenario: Chapter resolution record is persisted

- **WHEN** ERL сохраняет Chapter resolution record
- **THEN** record SHALL содержать Chapter UUID
- **AND** SHALL содержать `SOURCE_ID`
- **AND** SHALL содержать `CHAPTER_LOCATOR`
- **AND** SHALL содержать source order

### Requirement: ERL-WORKSTATE-005 — Generation state has required fields

Generation state MUST хранить как минимум:

- Book Topic UUID;
- `WORK_ID`;
- processing policy identity;
- ordered sequence entries;
- ingestion receipts;
- reducible membership/dependency metadata.

#### Scenario: Generation state is persisted

- **WHEN** ERL сохраняет Generation state
- **THEN** state SHALL содержать Book Topic UUID
- **AND** SHALL содержать `WORK_ID`
- **AND** SHALL содержать processing policy identity
- **AND** SHALL содержать ordered sequence entries
- **AND** SHALL содержать ingestion receipts
- **AND** SHALL содержать reducible membership/dependency metadata

### Requirement: ERL-WORKSTATE-006 — Sequence entry has required fields

Sequence entry MUST хранить как минимум:

- ordinal;
- Chapter UUID;
- role: `vocabulary | occurrence`;
- Vault document UUID.

#### Scenario: Sequence entry is persisted

- **WHEN** ERL сохраняет Sequence entry
- **THEN** entry SHALL содержать ordinal
- **AND** SHALL содержать Chapter UUID
- **AND** role SHALL быть `vocabulary` или `occurrence`
- **AND** entry SHALL содержать Vault document UUID

### Requirement: ERL-WORKSTATE-007 — Membership is defined by persistent work state

Generation membership и Chapter membership Vocabulary/Occurrence MUST определяться persistent work state, а не AsciiDoc attributes.

#### Scenario: Vocabulary or Occurrence membership is resolved

- **WHEN** ERL определяет generation membership или Chapter membership Vocabulary/Occurrence
- **THEN** membership SHALL определяться persistent work state
- **AND** SHALL NOT определяться AsciiDoc attributes

### Requirement: ERL-WORKSTATE-008 — Retained state and active documents are mutually consistent

Для retained generation state и active ERL documents consistency MUST проверяться двусторонне:

- state record MUST NOT ссылаться на отсутствующий UUID;
- structural role документа MUST соответствовать recorded role.

Deprecated documents generation, успешно закрытой через `erl-book-reduce`, MAY не иметь recorded role в `works/` после удаления metadata согласно `ERL-REDUCE-025`.

#### Scenario: Retained generation state is validated against Vault documents

- **WHEN** ERL проверяет retained generation state и active ERL documents
- **THEN** state record SHALL NOT ссылаться на отсутствующий UUID
- **AND** structural role документа SHALL соответствовать recorded role
- **AND** deprecated documents generation, успешно закрытой через `erl-book-reduce`, MAY не иметь recorded role в `works/` после удаления metadata согласно `ERL-REDUCE-025`

### Requirement: ERL-WORKSTATE-009 — Persistent work-state schema changes require migration planning

Изменение schema `.state/erl/works/` MUST требовать versioning/migration plan, поскольку `works/` является persistent domain data.

#### Scenario: Persistent work-state schema changes

- **WHEN** изменяется schema `.state/erl/works/`
- **THEN** изменение SHALL иметь versioning/migration plan
