# vocabulary-ingestion Specification

## Purpose

Определить semantic vocabulary ingestion contract English Reading Lab: ingestion одного Candidate и Chapter-level orchestration, active Vocabulary lookup, создание Vocabulary или Occurrence через canonical constructors, согласованное обновление persistent work state и reading sequence, recoverability и idempotency ingestion.

## Requirements

### Requirement: ERL-ING-001 — Single Candidate ingestion uses erl-vocabulary-ingest

Semantic ingestion одного Candidate MUST выполняться `erl-vocabulary-ingest`.

#### Scenario: Candidate is ingested semantically

- **WHEN** ERL выполняет semantic ingestion одного Candidate
- **THEN** ingestion SHALL выполняться `erl-vocabulary-ingest`

### Requirement: ERL-ING-002 — Chapter-level ingestion uses erl-chapter-vocabulary-ingest

Chapter-level orchestration MUST выполняться `erl-chapter-vocabulary-ingest`.

#### Scenario: Chapter vocabulary ingestion is orchestrated

- **WHEN** ERL выполняет Chapter-level vocabulary ingestion
- **THEN** orchestration SHALL выполняться `erl-chapter-vocabulary-ingest`

### Requirement: ERL-ING-003 — Ingestion looks up only active Vocabulary records

Ingestion MUST нормализовать lexical identity и выполнять lookup только среди active Vocabulary records.

#### Scenario: Candidate lexical identity is resolved

- **WHEN** ERL выполняет ingestion Candidate
- **THEN** lexical identity SHALL быть нормализована
- **AND** lookup SHALL выполняться только среди active Vocabulary records

### Requirement: ERL-ING-004 — Missing active Vocabulary creates Vocabulary Memo

Если active canonical Vocabulary не найден, ERL MUST создать Vocabulary Memo.

#### Scenario: Active canonical Vocabulary does not exist

- **GIVEN** active canonical Vocabulary для нормализованной lexical identity не найден
- **WHEN** ERL выполняет ingestion Candidate
- **THEN** ERL SHALL создать Vocabulary Memo

### Requirement: ERL-ING-005 — Existing active Vocabulary creates Occurrence Memo

Если active canonical Vocabulary найден, ERL MUST создать Occurrence Memo.

#### Scenario: Active canonical Vocabulary exists

- **GIVEN** active canonical Vocabulary для нормализованной lexical identity найден
- **WHEN** ERL выполняет ingestion Candidate
- **THEN** ERL SHALL создать Occurrence Memo

### Requirement: ERL-ING-006 — Vault documents use canonical object constructors

Vault document MUST создаваться только через canonical object constructor.

#### Scenario: Ingestion creates a Vault document

- **WHEN** vocabulary ingestion создаёт Vault document
- **THEN** document SHALL создаваться через canonical object constructor
- **AND** SHALL NOT создаваться обходным механизмом

### Requirement: ERL-ING-007 — Successful document creation updates work state and reading sequence

После успешного создания document ERL MUST обновить persistent work state и reading sequence.

#### Scenario: Ingestion document is created successfully

- **GIVEN** ingestion document успешно создан
- **WHEN** ERL завершает ingestion operation
- **THEN** persistent work state SHALL быть обновлён
- **AND** reading sequence SHALL быть обновлена

### Requirement: ERL-ING-008 — Document creation and work-state update are recoverable

Операция document creation + work-state update MUST быть recoverable.

Состояние «document создан, work state не обновлён» MUST обнаруживаться `erl-check` или recovery mechanism.

#### Scenario: Document exists but work state was not updated

- **GIVEN** ingestion document создан
- **AND** соответствующий work state не обновлён
- **WHEN** ERL выполняет validation или recovery
- **THEN** inconsistent state SHALL быть обнаружен `erl-check` или recovery mechanism
- **AND** ingestion operation SHALL оставаться recoverable

### Requirement: ERL-ING-009 — EXTRACTION_ID ingestion is idempotent by ingestion receipt

Ingestion одного `EXTRACTION_ID` MUST быть идемпотентна относительно ingestion receipt.

Повторный запуск MUST NOT молча создавать второй набор документов.

#### Scenario: Previously ingested EXTRACTION_ID is ingested again

- **GIVEN** ingestion receipt уже существует для `EXTRACTION_ID`
- **WHEN** ingestion того же `EXTRACTION_ID` запускается повторно
- **THEN** ERL SHALL соблюдать idempotency относительно ingestion receipt
- **AND** SHALL NOT молча создавать второй набор документов

### Requirement: ERL-ING-010 — Created Vocabulary and Occurrence inherit Chapter key-topic

Каждый Vocabulary или Occurrence Memo, созданный для lexical encounter текущей Chapter, MUST содержать host-defined header attribute `:key-topic:` с точным значением `:key-topic:` этой Chapter Note.

Vocabulary Memo MUST наследовать key при первом приобретении lexical identity. При последующей встрече существующей global Vocabulary ERL MUST создать новый Occurrence Memo с key текущей Chapter и MUST NOT менять acquisition attachment исходной Vocabulary.

#### Scenario: New Vocabulary is acquired in a Chapter

- **GIVEN** Candidate не соответствует существующей active Vocabulary
- **WHEN** ERL создаёт Vocabulary Memo для Chapter
- **THEN** Memo `:key-topic:` SHALL точно совпадать с Chapter Note `:key-topic:`
- **AND** Vocabulary SHALL считаться прикреплённой к Chapter первого приобретения

#### Scenario: Existing Vocabulary occurs in another Chapter

- **GIVEN** Candidate соответствует существующей active Vocabulary, приобретённой ранее
- **WHEN** ERL создаёт Occurrence Memo в текущей Chapter
- **THEN** Occurrence `:key-topic:` SHALL точно совпадать с текущей Chapter Note
- **AND** `:key-topic:` существующей Vocabulary SHALL NOT изменяться
- **AND** attachment существующей Vocabulary к Chapter первого приобретения SHALL сохраняться

### Requirement: ERL-ING-011 — Created Memo and Chapter Note have reciprocal canonical links

Каждый созданный Vocabulary или Occurrence Memo MUST иметь reciprocal canonical relation с Chapter Note, где возник lexical encounter.

Memo MUST содержать ровно одну canonical link на Chapter Note в структурной секции `Chapter`. Chapter Note MUST содержать ровно одну canonical link на Memo в структурной секции `Vocabulary`, упорядоченную по Candidate/source order текущей Chapter.

#### Scenario: Vocabulary or Occurrence is created

- **WHEN** ERL создаёт Vocabulary или Occurrence Memo для Chapter
- **THEN** Memo section `Chapter` SHALL содержать canonical link на Chapter UUID
- **AND** Chapter section `Vocabulary` SHALL содержать reciprocal canonical link на Memo UUID
- **AND** обе links SHALL существовать после committed Candidate ingestion
- **AND** duplicate links SHALL NOT создаваться при retry

### Requirement: ERL-ING-012 — Memo attachment and chain mutation are recoverable with ingestion state

Для каждого Candidate создание Vocabulary/Occurrence Memo, наследование `:key-topic:`, Chapter reciprocal link, изменение predecessor chain link, generation membership, reading-sequence entry и ingestion receipt MUST быть одной recoverable semantic operation.

Operation MUST либо зафиксировать согласованный новый node, либо восстановить bytes всех изменённых documents и persistent state. Chapter batch retry MUST безопасно продолжать с первого Candidate без completed receipt.

#### Scenario: Failure occurs after predecessor or Chapter update

- **GIVEN** ingestion начала изменять predecessor Memo или Chapter Note
- **WHEN** последующая document или state mutation завершается ошибкой
- **THEN** current Candidate SHALL NOT получить completed receipt
- **AND** созданный Memo SHALL быть удалён или помечен recoverable transaction state
- **AND** predecessor Memo, Chapter Note и generation state SHALL быть восстановлены до pre-operation bytes

#### Scenario: Interrupted Chapter batch is retried

- **GIVEN** предыдущие Candidates имеют completed receipts, а следующий Candidate не committed
- **WHEN** Chapter ingestion запускается повторно
- **THEN** completed nodes SHALL NOT создаваться или связываться повторно
- **AND** chain SHALL продолжиться с последнего committed Memo этой Chapter
