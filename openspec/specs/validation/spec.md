# validation Specification

## Purpose

Определить read-only validation и recovery-diagnostics contract English Reading Lab: проверку согласованности canonical Vault documents и persistent work state, Vocabulary/Occurrence structure, generation и Chapter relationships, reading sequence, ingestion receipts, Reduce transaction state, Classic Reduce reconciliation и ERL identifier invariants.

## Requirements

### Requirement: ERL-SKILL-002 — erl-check is read-only

`erl-check` MUST оставаться read-only diagnostic operation.

Исправление work state после Classic Reduce MUST выполнять только `erl-classic-reduce-reconcile` с explicit apply.

#### Scenario: Validation detects state requiring Classic Reduce reconciliation

- **GIVEN** ERL обнаруживает work state, требующий исправления после Classic Reduce
- **WHEN** выполняется `erl-check`
- **THEN** `erl-check` SHALL только диагностировать состояние
- **AND** SHALL NOT изменять work state
- **AND** исправление SHALL выполняться только `erl-classic-reduce-reconcile` с explicit apply

### Requirement: ERL-CHECK-001 — Recorded UUIDs resolve to canonical target-home documents

Все UUID из `<ZETTELKASTEN_HOME>/.state/erl/works/` MUST существовать как соответствующие documents в `<ZETTELKASTEN_HOME>/notes/`, если record не помечен как допустимая historical/tombstone relation.

#### Scenario: Recorded UUID is validated

- **GIVEN** UUID записан в `<ZETTELKASTEN_HOME>/.state/erl/works/`
- **WHEN** `erl-check` разрешает соответствующий document
- **THEN** document SHALL существовать в `<ZETTELKASTEN_HOME>/notes/`
- **AND** nested `vault/notes/` SHALL NOT использоваться как fallback

### Requirement: ERL-CHECK-002 — Recorded role matches canonical document contract

Recorded role MUST соответствовать canonical `:type:` и structural body contract.

#### Scenario: Recorded document role is validated

- **GIVEN** ERL document имеет recorded role
- **WHEN** ERL выполняет validation
- **THEN** recorded role SHALL соответствовать canonical `:type:`
- **AND** SHALL соответствовать structural body contract

### Requirement: ERL-CHECK-003 — Vocabulary role requires valid Vocabulary Memo

Vocabulary role MUST допускаться только для Memo с valid lexical identity structure.

#### Scenario: Vocabulary role is validated

- **GIVEN** ERL document имеет Vocabulary role
- **WHEN** ERL выполняет validation
- **THEN** document SHALL быть Memo
- **AND** SHALL иметь valid lexical identity structure

### Requirement: ERL-CHECK-004 — Occurrence role requires canonical Vocabulary link and Context

Occurrence role MUST допускаться только для Memo с ровно одной canonical Vocabulary link в Vocabulary section и valid Context section.

#### Scenario: Occurrence role is validated

- **GIVEN** ERL document имеет Occurrence role
- **WHEN** ERL выполняет validation
- **THEN** document SHALL быть Memo
- **AND** Vocabulary section SHALL содержать ровно одну canonical Vocabulary link
- **AND** Context section SHALL быть valid

### Requirement: ERL-CHECK-005 — Active Occurrence targets active Vocabulary

В нормальном active состоянии Occurrence target MUST быть active Vocabulary.

#### Scenario: Active Occurrence target is validated

- **GIVEN** Occurrence находится в нормальном active состоянии
- **WHEN** ERL проверяет его Vocabulary target
- **THEN** target SHALL быть active Vocabulary

### Requirement: ERL-CHECK-006 — Deprecated Occurrence target requires closure

Если Occurrence target стал deprecated через supported Reduce workflow, validation status MUST быть `CLOSURE_REQUIRED`.

#### Scenario: Occurrence target becomes deprecated through Reduce

- **GIVEN** Occurrence target стал deprecated через supported Reduce workflow
- **WHEN** ERL выполняет validation
- **THEN** status SHALL быть `CLOSURE_REQUIRED`

### Requirement: ERL-CHECK-007 — CLOSURE_REQUIRED report contains closure context

`CLOSURE_REQUIRED` report MUST показывать deprecated target, dependent active documents, owning generations и рекомендуемый dry-run closure.

#### Scenario: CLOSURE_REQUIRED report is produced

- **GIVEN** validation status равен `CLOSURE_REQUIRED`
- **WHEN** ERL формирует diagnostic report
- **THEN** report SHALL показывать deprecated target
- **AND** SHALL показывать dependent active documents
- **AND** SHALL показывать owning generations
- **AND** SHALL показывать рекомендуемый dry-run closure

### Requirement: ERL-CHECK-008 — Classic Reduce alone is not a validation error

Сам факт Classic `zt-reduce` ERL-used Topic MUST NOT являться validation error.

Classic successor MUST NOT считаться ERL Book generation без explicit adoption.

#### Scenario: ERL-used Topic was reduced by Classic workflow

- **GIVEN** ERL-used Topic был обработан Classic `zt-reduce`
- **WHEN** ERL выполняет validation
- **THEN** сам факт Classic Reduce SHALL NOT считаться validation error
- **AND** Classic successor SHALL NOT считаться ERL Book generation без explicit adoption

### Requirement: ERL-CHECK-009 — Active canonical Vocabulary is unique by lexical identity

Active canonical Vocabulary MUST быть уникален по lexical identity.

#### Scenario: Active Vocabulary identities are validated

- **WHEN** ERL проверяет active canonical Vocabulary records
- **THEN** для одной lexical identity SHALL существовать не более одного active canonical Vocabulary

### Requirement: ERL-CHECK-010 — WORK_ID has at most one active Book generation

Для одного `WORK_ID` MUST существовать не более одной active Book generation.

#### Scenario: Active generations are validated for a work

- **GIVEN** ERL проверяет retained Book generations одного `WORK_ID`
- **WHEN** определяется их active state
- **THEN** active Book generation SHALL быть не более одной

### Requirement: ERL-CHECK-011 — Chapter resolution key is unique

Chapter resolution record MUST быть уникален по:

`WORK_ID × SOURCE_ID × CHAPTER_LOCATOR`.

#### Scenario: Chapter resolution records are validated

- **WHEN** ERL проверяет Chapter resolution records
- **THEN** сочетание `WORK_ID × SOURCE_ID × CHAPTER_LOCATOR` SHALL быть уникальным

### Requirement: ERL-CHECK-012 — EPUB fingerprint has canonical format

EPUB source fingerprint MUST соответствовать `^sha256:[0-9a-f]{64}$`.

Unsupported scheme MUST требовать explicit schema extension.

#### Scenario: EPUB source fingerprint is validated

- **WHEN** ERL проверяет EPUB source fingerprint
- **THEN** fingerprint SHALL соответствовать `^sha256:[0-9a-f]{64}$`
- **AND** unsupported scheme SHALL требовать explicit schema extension

### Requirement: ERL-CHECK-013 — Sequence ordinals are unique and ordered

Sequence ordinals MUST быть уникальны и упорядочены внутри generation.

#### Scenario: Generation sequence ordinals are validated

- **GIVEN** generation содержит reading sequence
- **WHEN** ERL проверяет sequence ordinals
- **THEN** ordinals SHALL быть уникальны внутри generation
- **AND** SHALL быть упорядочены внутри generation

### Requirement: ERL-CHECK-014 — Sequence nodes reference existing documents

Каждый sequence node MUST ссылаться на существующий Chapter UUID и существующий Vocabulary/Occurrence UUID.

#### Scenario: Sequence node references are validated

- **GIVEN** generation содержит sequence node
- **WHEN** ERL проверяет его document references
- **THEN** referenced Chapter UUID SHALL существовать
- **AND** referenced Vocabulary/Occurrence UUID SHALL существовать

### Requirement: ERL-CHECK-015 — Active generation sequence excludes deprecated documents

Deprecated documents MUST NOT входить в active generation sequence.

#### Scenario: Active generation sequence is validated

- **GIVEN** generation является active
- **WHEN** ERL проверяет её sequence
- **THEN** sequence SHALL NOT содержать deprecated documents

### Requirement: ERL-CHECK-016 — Ordinary Book Reduce preserves durable Chapter Notes

`erl-book-reduce` MUST NOT deprecated'ить durable Chapter Notes в обычном mutation set.

#### Scenario: Ordinary Book Reduce result is validated

- **GIVEN** `erl-book-reduce` выполнил обычный mutation set
- **WHEN** ERL проверяет durable Chapter Notes
- **THEN** durable Chapter Notes SHALL NOT быть deprecated этим mutation set

### Requirement: ERL-CHECK-017 — Persistent works state is sufficient without cache and staging

`.state/erl/works/` MUST быть достаточен для восстановления ERL semantics без `cache/` и `staging/`.

#### Scenario: Derived and staging state are unavailable

- **GIVEN** `cache/` и `staging/` недоступны
- **WHEN** ERL восстанавливает semantics из persistent state
- **THEN** `.state/erl/works/` SHALL быть достаточен для восстановления ERL semantics

### Requirement: ERL-CHECK-018 — Unfinished transaction blocks new Reduce

Незавершённая transaction journal MUST обнаруживаться и MUST блокировать новую Reduce transaction.

#### Scenario: Unfinished transaction journal exists

- **GIVEN** существует незавершённая transaction journal
- **WHEN** ERL выполняет validation перед новой Reduce transaction
- **THEN** unfinished transaction SHALL быть обнаружена
- **AND** новая Reduce transaction SHALL быть заблокирована

### Requirement: ERL-CHECK-019 — EXTRACTION_ID has at most one completed ingestion receipt

Один `EXTRACTION_ID` MUST NOT иметь более одного completed ingestion receipt.

#### Scenario: Ingestion receipts are validated

- **GIVEN** ERL проверяет completed ingestion receipts
- **WHEN** receipts группируются по `EXTRACTION_ID`
- **THEN** один `EXTRACTION_ID` SHALL иметь не более одного completed ingestion receipt

### Requirement: ERL-CHECK-020 — ERL documents contain no plugin-specific attributes

ERL document MUST NOT содержать plugin-specific AsciiDoc attributes `:erl-*`.

#### Scenario: ERL document attributes are validated

- **WHEN** ERL проверяет attributes ERL document
- **THEN** document SHALL NOT содержать plugin-specific attributes `:erl-*`

### Requirement: ERL-CHECK-021 — Book Topic follows host Topic presentation contract

Каждый retained или active Book generation UUID MUST разрешаться в существующую canonical Topic, чья видимая presentation идентифицирует конкретную книгу из logical work state.

Book Topic MUST содержать host-compatible `:key-topic:`, не используемый как `WORK_ID`, и MUST удовлетворять canonical host Topic presentation contract. Topic, представленная только thematic key вместо title книги, MUST диагностироваться как неверная Book Topic presentation.

#### Scenario: Book Topic presentation is validated

- **GIVEN** ERL document имеет Book Topic role
- **WHEN** ERL выполняет validation
- **THEN** Topic SHALL существовать в canonical Vault namespace
- **AND** Topic SHALL содержать host-compatible `:key-topic:`
- **AND** `:key-topic:` SHALL NOT использоваться как `WORK_ID`
- **AND** видимый title Topic SHALL идентифицировать книгу по canonical title logical work
- **AND** Topic SHALL удовлетворять canonical host Topic presentation contract

#### Scenario: Registered generation has no valid Book Topic

- **GIVEN** work manifest или generation state содержит Book generation UUID
- **WHEN** соответствующий document отсутствует, имеет type не `topic` или его title не представляет книгу
- **THEN** `erl-check` SHALL вернуть validation error для этой generation
- **AND** diagnostic SHALL различать missing Topic, wrong canonical type и wrong Book presentation
- **AND** `erl-check` SHALL NOT создавать или переписывать Topic автоматически

### Requirement: ERL-CHECK-022 — ERL identifiers use valid lowercase UUID format

`WORK_ID` MUST быть глобально уникален.

ERL identifiers MUST соответствовать lowercase UUID format.

#### Scenario: ERL identifiers are validated

- **WHEN** ERL проверяет ERL identifiers
- **THEN** `WORK_ID` SHALL быть глобально уникален
- **AND** ERL identifiers SHALL соответствовать lowercase UUID format

### Requirement: ERL-CHECK-023 — Deprecated Book Topic cannot remain active generation

Deprecated Book Topic MUST NOT оставаться active-generation pointer.

External close MUST отражаться как `GENERATION_CLOSED_EXTERNALLY`.

#### Scenario: Book Topic was closed externally

- **GIVEN** Book Topic был deprecated внешним workflow
- **WHEN** ERL выполняет validation
- **THEN** deprecated Book Topic SHALL NOT оставаться active-generation pointer
- **AND** external close SHALL отражаться как `GENERATION_CLOSED_EXTERNALLY`

### Requirement: ERL-CHECK-024 — Unregistered Classic successor requires reconciliation diagnostics

Незарегистрированный Classic successor MUST NOT считаться ERL Book generation и MUST показываться в reconciliation diagnostics.

#### Scenario: Unregistered Classic successor exists

- **GIVEN** Classic Reduce создал successor, не зарегистрированный в ERL
- **WHEN** ERL выполняет validation
- **THEN** successor SHALL NOT считаться ERL Book generation
- **AND** SHALL показываться в reconciliation diagnostics

### Requirement: ERL-CHECK-025 — Committed Book Reduce removes closed generation metadata

После committed `erl-book-reduce` в `.state/erl/works/` MUST отсутствовать generation file, manifest reference и active pointer каждой закрытой generation.

Compact committed transaction manifest/result MUST существовать и быть достаточен для заявленного audit.

#### Scenario: Committed Book Reduce state is validated

- **GIVEN** `erl-book-reduce` успешно committed закрытие generation
- **WHEN** ERL проверяет post-commit state
- **THEN** generation file закрытой generation SHALL отсутствовать в `.state/erl/works/`
- **AND** manifest reference закрытой generation SHALL отсутствовать
- **AND** active pointer на закрытую generation SHALL отсутствовать
- **AND** compact committed transaction manifest/result SHALL существовать
- **AND** SHALL быть достаточен для заявленного audit

### Requirement: ERL-CHECK-030 — ERL card content is valid and human-readable

`erl-check` MUST read-only проверять каждую зарегистрированную Book, Chapter, Vocabulary и Occurrence card на соответствие `ERL-DOC-008`.

Validation MUST проверять UTF-8 и AsciiDoc validity, непустые title/body, применимый role-specific structural contract, непустые обязательные значения, осмысленные labels canonical links и отсутствие machine-oriented artifacts, подменяющих читаемое content.

#### Scenario: All card roles have readable content

- **GIVEN** зарегистрированные Book, Chapter, Vocabulary и Occurrence cards содержат valid human-readable AsciiDoc
- **WHEN** ERL выполняет validation
- **THEN** cards SHALL пройти `ERL-CHECK-030`
- **AND** validation SHALL NOT изменять Vault documents или persistent state

#### Scenario: Card content is empty, malformed or machine-oriented

- **WHEN** ERL card имеет invalid UTF-8/AsciiDoc, пустые title/body или обязательное значение, нечитабельный link label, raw serialization/source markup вместо body либо unresolved placeholder
- **THEN** `erl-check` SHALL вернуть validation error `ERL-CHECK-030`
- **AND** diagnostic SHALL указать document UUID, recorded role и конкретную нарушенную readability condition
- **AND** SHALL NOT автоматически переписывать card content

### Requirement: ERL-CHECK-029 — Chapter chain handoff is reciprocal and follows source order

`erl-check` MUST read-only проверять для каждой completed Chapter Memo Chain:

- outgoing handoff tail Memo→next Chapter Note;
- reciprocal incoming handoff next Chapter Note→tail Memo;
- exact source-order adjacency Chapters внутри одного `SOURCE_ID`;
- uniqueness обеих links;
- отсутствие handoff у последней Chapter и Chapter без Memo Chain;
- отсутствие stale handoff от node, который не является current tail.

#### Scenario: Valid handoff is checked

- **GIVEN** Chapter имеет completed Memo Chain и непосредственно следующую Chapter
- **WHEN** ERL выполняет validation
- **THEN** tail и next Chapter SHALL содержать reciprocal canonical handoff links
- **AND** targets SHALL соответствовать adjacent Chapters в source order

#### Scenario: Handoff is missing, stale, duplicated or points outside adjacency

- **WHEN** одна сторона handoff отсутствует, link дублируется, source/Chapter adjacency не совпадает, outgoing Memo не является tail либо terminal Chapter имеет handoff
- **THEN** `erl-check` SHALL вернуть validation error с конкретной причиной
- **AND** SHALL указать generation UUID, source ID, current Chapter UUID, next Chapter UUID и tail Memo UUID, когда они доступны
- **AND** SHALL NOT изменять Vault documents или persistent state

### Requirement: ERL-CHECK-026 — Target home layout is validated

`erl-check` MUST проверять canonical target-home layout и MUST обнаруживать legacy nested `vault/` layout без изменения данных.

#### Scenario: Canonical layout is valid

- **GIVEN** documents находятся в `<ZETTELKASTEN_HOME>/notes/`, а state — в `<ZETTELKASTEN_HOME>/.state/erl/`
- **WHEN** выполняется `erl-check`
- **THEN** layout SHALL считаться canonical

#### Scenario: Legacy nested layout exists

- **GIVEN** documents или ERL state обнаружены под `<ZETTELKASTEN_HOME>/vault/`
- **WHEN** выполняется `erl-check`
- **THEN** checker SHALL вывести `HOME_LAYOUT_MIGRATION_REQUIRED`
- **AND** SHALL указать обнаруженные legacy paths
- **AND** SHALL NOT изменять данные

### Requirement: ERL-CHECK-028 — Chapter Memo attachment and chain are complete and reciprocal

`erl-check` MUST read-only проверять для каждого Vocabulary/Occurrence sequence node active generation:

- точное совпадение Memo и Chapter Note `:key-topic:`;
- ровно одну Memo→Chapter link и одну reciprocal Chapter→Memo link;
- соответствие Chapter UUID persistent sequence entry;
- ровно один Chapter-local chain head;
- predecessor/successor reciprocity с labels `Предыдущее memo` и `Следующее memo`;
- соответствие chain order Candidate/source order;
- отсутствие duplicates, branches, cycles и cross-Chapter chain edges.

#### Scenario: Valid Chapter Memo Chain is checked

- **GIVEN** Chapter содержит committed Vocabulary/Occurrence sequence nodes
- **WHEN** ERL выполняет validation
- **THEN** attachment links и `:key-topic:` SHALL соответствовать Chapter Note
- **AND** Memo Chain SHALL быть полной линейной reciprocal projection sequence nodes этой Chapter

#### Scenario: Attachment or chain is inconsistent

- **WHEN** key values различаются, attachment односторонняя, state Chapter UUID не совпадает, chain link односторонняя, head неоднозначен, существует branch/cycle/duplicate или edge пересекает Chapter boundary
- **THEN** `erl-check` SHALL вернуть validation error с конкретной причиной
- **AND** SHALL указать generation UUID, Chapter UUID и затронутые Memo UUID
- **AND** SHALL NOT изменять Vault documents или persistent state

### Requirement: ERL-CHECK-027 — Chapter–Book Topic binding is complete and reciprocal

`erl-check` MUST read-only проверять для каждой Chapter Note active generation:

- точное совпадение Chapter `:key-topic:` и Book Topic `:key-topic:`;
- ровно одну canonical Chapter→active Book Topic link;
- ровно одну reciprocal Book Topic→Chapter link;
- отсутствие duplicate links;
- source-order Topic→Chapter links;
- отсутствие второй active Book Topic attachment Chapter Note.

#### Scenario: Complete Chapter–Topic binding is validated

- **GIVEN** Chapter зарегистрирована для active Book generation
- **WHEN** ERL выполняет validation
- **THEN** Chapter `:key-topic:` SHALL совпадать с Book Topic `:key-topic:`
- **AND** Chapter→Topic и Topic→Chapter links SHALL существовать и быть взаимными
- **AND** каждая сторона SHALL содержать ровно одну applicable link

#### Scenario: Chapter–Topic binding is incomplete or conflicting

- **GIVEN** Chapter относится к active Book generation
- **WHEN** отсутствует `:key-topic:`, key values различаются, одна сторона link отсутствует, link дублируется, Topic links нарушают source order или Chapter указывает на две active Book Topics
- **THEN** `erl-check` SHALL вернуть validation error с причиной нарушения
- **AND** SHALL указать Book Topic UUID и Chapter UUID
- **AND** SHALL NOT изменять Topic, Chapter Note или persistent work state
