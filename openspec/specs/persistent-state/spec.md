# persistent-state Specification

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

### Requirement: ERL-STATE-001 — ERL uses a single local state namespace

ERL MUST использовать единый local namespace:

```text
.state/erl/
```

#### Scenario: ERL local state is stored

- **WHEN** ERL сохраняет local state
- **THEN** state SHALL находиться внутри `.state/erl/`

### Requirement: ERL-STATE-002 — Works directory is persistent domain state

`.state/erl/works/` MUST являться persistent ERL domain state и частью source of truth ERL.

#### Scenario: Work state is classified

- **WHEN** ERL классифицирует данные внутри `.state/erl/works/`
- **THEN** они SHALL считаться persistent ERL domain state
- **AND** SHALL считаться частью source of truth ERL

### Requirement: ERL-STATE-003 — ERL source of truth has two canonical parts

Источник истины ERL MUST состоять из:

- canonical Vault documents;
- `.state/erl/works/`.

#### Scenario: ERL source of truth is determined

- **WHEN** определяется source of truth ERL
- **THEN** он SHALL включать canonical Vault documents
- **AND** SHALL включать `.state/erl/works/`

### Requirement: ERL-STATE-004 — Works state is not disposable cache

`.state/erl/works/` MUST NOT считаться disposable cache.

Обычная очистка runtime state MUST NOT удалять `works/`.

#### Scenario: Runtime state is cleaned

- **WHEN** выполняется обычная очистка runtime state
- **THEN** `.state/erl/works/` SHALL NOT удаляться как disposable cache

### Requirement: ERL-STATE-005 — Removing state with work manifests is destructive

Удаление `.state/` целиком MUST считаться destructive operation, если в `.state/erl/works/` существуют work manifests.

#### Scenario: State directory contains work manifests

- **GIVEN** в `.state/erl/works/` существуют work manifests
- **WHEN** запрашивается удаление `.state/` целиком
- **THEN** операция SHALL считаться destructive

### Requirement: ERL-STATE-006 — Runtime state classes have separate lifecycles

`staging/`, `transactions/`, `cache/` и `locks/` MUST иметь собственные lifecycle rules и MUST NOT смешиваться с persistent work state.

#### Scenario: ERL state class lifecycle is applied

- **WHEN** ERL работает со `staging/`, `transactions/`, `cache/` или `locks/`
- **THEN** соответствующий state SHALL использовать собственные lifecycle rules
- **AND** SHALL NOT смешиваться с persistent work state

### Requirement: ERL-STATE-007 — Cache and derived indexes are rebuildable

`cache/` и derived indexes MUST быть полностью rebuildable.

#### Scenario: Derived state is removed

- **WHEN** `cache/` или derived index удалён
- **THEN** ERL SHALL иметь возможность полностью восстановить его из source of truth

### Requirement: ERL-STATE-008 — Transaction recovery artifacts follow retention rules

Незавершённые transaction artifacts MUST NOT очищаться.

После commit или rollback backup payload MAY очищаться согласно recovery policy, но compact committed manifest/result закрытой generation MUST сохраняться как persistent audit record.

#### Scenario: Transaction artifacts are cleaned after completion

- **GIVEN** transaction завершена через commit или rollback
- **WHEN** ERL выполняет cleanup transaction artifacts
- **THEN** backup payload MAY быть удалён согласно recovery policy
- **AND** compact committed manifest/result закрытой generation SHALL сохраняться как persistent audit record

#### Scenario: Unfinished transaction artifacts are considered for cleanup

- **GIVEN** transaction не завершена
- **WHEN** ERL рассматривает её artifacts для cleanup
- **THEN** transaction artifacts SHALL NOT удаляться

### Requirement: ERL-STATE-009 — Persistent work state is deterministic and inspectable

Persistent work state MUST быть text-based, deterministic и inspectable из Unix CLI.

Canonical Persistent Work State v1 MUST использовать JSON согласно `ERL-STATE-011` и `ERL-STATE-012`.

TSV, JSONL и YAML MAY использоваться только для noncanonical staging, reports или cache, если конкретный contract явно не устанавливает иное.

#### Scenario: Canonical persistent work state is stored

- **WHEN** ERL сохраняет Canonical Persistent Work State v1
- **THEN** state SHALL быть text-based
- **AND** SHALL быть deterministic
- **AND** SHALL быть inspectable из Unix CLI
- **AND** SHALL использовать JSON согласно `ERL-STATE-011` и `ERL-STATE-012`

### Requirement: ERL-STATE-010 — Works durability is independent of Git policy

Git tracking/back-up policy для пользовательского `works/` MAY определяться deployment policy.

Независимо от этой policy, `works/` MUST переживать обычную очистку cache/staging и MUST NOT считаться временными данными.

#### Scenario: Deployment does not track works in Git

- **GIVEN** deployment policy не требует Git tracking пользовательского `works/`
- **WHEN** выполняется обычная очистка cache или staging
- **THEN** `works/` SHALL сохраняться
- **AND** SHALL NOT считаться временными данными

### Requirement: ERL-STATE-011 — Persistent Work State Contract v1 uses deterministic JSON

Persistent Work State Contract v1 MUST использовать UTF-8 JSON и обязательное поле:

```json
"schema_version": 1
```

Generated files MUST использовать stable field ordering, LF line endings и завершающий LF.

#### Scenario: Persistent state JSON is generated

- **WHEN** ERL создаёт файл Persistent Work State Contract v1
- **THEN** файл SHALL быть UTF-8 JSON
- **AND** SHALL содержать `"schema_version": 1`
- **AND** SHALL использовать stable field ordering
- **AND** SHALL использовать LF line endings
- **AND** SHALL завершаться LF

### Requirement: ERL-STATE-012 — Persistent state uses canonical filenames

Canonical filenames v1 MUST быть:

```text
.state/erl/works/<work-slug>/work.json
.state/erl/works/<work-slug>/sources/<SOURCE_ID>.json
.state/erl/works/<work-slug>/generations/<BOOK_TOPIC_UUID>.json
```

#### Scenario: Persistent state files are resolved

- **WHEN** ERL определяет canonical filename для work, source или generation state
- **THEN** work state SHALL использовать `.state/erl/works/<work-slug>/work.json`
- **AND** source state SHALL использовать `.state/erl/works/<work-slug>/sources/<SOURCE_ID>.json`
- **AND** generation state SHALL использовать `.state/erl/works/<work-slug>/generations/<BOOK_TOPIC_UUID>.json`

### Requirement: ERL-STATE-013 — Work slug rename is an explicit atomic migration

Переименование `<work-slug>` MUST выполняться как explicit migration под ERL lock.

Операция MUST NOT менять `WORK_ID` или Vault UUID и MUST атомарно обновлять ERL-local path references либо выполнять rollback.

#### Scenario: Work slug is renamed

- **WHEN** ERL переименовывает `<work-slug>`
- **THEN** операция SHALL выполняться как explicit migration под ERL lock
- **AND** SHALL NOT менять `WORK_ID`
- **AND** SHALL NOT менять Vault UUID
- **AND** SHALL атомарно обновить ERL-local path references либо выполнить rollback

### Requirement: ERL-STATE-014 — ERL-local identifiers are independent UUID v4 values

`WORK_ID`, `SOURCE_ID`, `EXTRACTION_ID` и `TXID` MUST быть independently generated UUID v4 в lowercase canonical `8-4-4-4-12` representation.

Эти identifiers MUST NOT выводиться из пользовательского текста или filesystem paths.

Они MUST считаться ERL-local identifiers, а не Vault document UUID.

Vault documents MUST продолжать использовать host UUID v1.

#### Scenario: ERL-local identifier is generated

- **WHEN** ERL создаёт `WORK_ID`, `SOURCE_ID`, `EXTRACTION_ID` или `TXID`
- **THEN** identifier SHALL быть независимо сгенерированным UUID v4
- **AND** SHALL использовать lowercase canonical `8-4-4-4-12` representation
- **AND** SHALL NOT выводиться из пользовательского текста или filesystem paths
- **AND** SHALL NOT использоваться как Vault document UUID
- **AND** Vault documents SHALL продолжать использовать host UUID v1

### Requirement: ERL-STATE-015 — Work and source identifiers satisfy uniqueness constraints

`WORK_ID` MUST быть глобально уникален среди work manifests.

`SOURCE_ID` MUST быть уникален как минимум внутри соответствующего `WORK_ID`.

#### Scenario: Work and source identifiers are assigned

- **WHEN** ERL назначает `WORK_ID`
- **THEN** `WORK_ID` SHALL быть глобально уникален среди work manifests
- **AND** при назначении `SOURCE_ID` он SHALL быть уникален как минимум внутри соответствующего `WORK_ID`

### Requirement: ERL-STATE-016 — EPUB fingerprint has canonical SHA-256 format

Fingerprint EPUB v1 MUST иметь формат:

```text
sha256:<64 lowercase hexadecimal digits>
```

и MUST соответствовать выражению:

```text
^sha256:[0-9a-f]{64}$
```

#### Scenario: EPUB fingerprint is validated

- **WHEN** ERL проверяет Fingerprint EPUB v1
- **THEN** fingerprint SHALL соответствовать `^sha256:[0-9a-f]{64}$`

### Requirement: ERL-STATE-017 — Persistent state updates are atomic and recoverable

Persistent state update MUST использовать temporary file, validation и atomic rename.

Multi-file semantic operation MUST использовать journal/recovery protocol.

#### Scenario: Single persistent state file is updated

- **WHEN** ERL обновляет persistent state file
- **THEN** update SHALL использовать temporary file
- **AND** SHALL выполнить validation
- **AND** SHALL завершаться atomic rename

#### Scenario: Multi-file persistent state operation is performed

- **WHEN** ERL выполняет multi-file semantic operation
- **THEN** операция SHALL использовать journal/recovery protocol
