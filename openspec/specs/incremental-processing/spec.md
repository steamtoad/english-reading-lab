# incremental-processing Specification

## Purpose

Определить incremental processing model English Reading Lab: logical work как lifecycle scope, Chapter как основную единицу обработки, generation-aware processing scope, повторную обработку Chapter и допустимую временную segmentation без изменения persistent Chapter identity.

## Requirements

### Requirement: ERL-PROC-001 — Logical work is the lifecycle scope

Logical work MUST быть lifecycle scope для ERL processing.

#### Scenario: ERL processing lifecycle is resolved

- **WHEN** ERL определяет lifecycle scope для processing state или generation
- **THEN** scope SHALL принадлежать logical work
- **AND** SHALL сохранять stable `WORK_ID` независимо от отдельных Book generations

### Requirement: ERL-PROC-002 — Chapter is the default processing unit

Chapter MUST быть default processing unit ERL.

#### Scenario: A book is processed incrementally

- **WHEN** ERL начинает semantic processing source book
- **THEN** processing SHALL выполняться по отдельным Chapters по умолчанию
- **AND** whole-book processing SHALL NOT быть обязательным условием workflow

### Requirement: ERL-PROC-003 — Processing scope combines generation and Chapter

Основной processing scope MUST определяться как:

`active Book Topic UUID × Chapter UUID`.

#### Scenario: Chapter processing scope is resolved

- **GIVEN** logical work имеет active Book generation
- **AND** Chapter имеет durable canonical UUID
- **WHEN** ERL определяет processing scope
- **THEN** scope SHALL включать active Book Topic UUID
- **AND** SHALL включать Chapter UUID

### Requirement: ERL-PROC-004 — Chapters may be processed incrementally over time

ERL MUST поддерживать постепенную обработку Chapters одного logical work в разные моменты времени.

#### Scenario: Processing continues with a later Chapter

- **GIVEN** одна или несколько Chapters уже обработаны в active generation
- **WHEN** пользователь позже начинает обработку следующей Chapter
- **THEN** ERL SHALL продолжить processing той же active generation
- **AND** ранее обработанные Chapters SHALL NOT требовать повторной обработки только из-за разнесения workflow во времени

### Requirement: ERL-PROC-005 — Chapter may be reprocessed in a new generation

ERL MUST поддерживать повторную обработку одной Chapter в новой semantic generation.

#### Scenario: New generation processes an existing Chapter

- **GIVEN** Chapter уже была обработана в предыдущей Book generation
- **WHEN** новая active semantic generation обрабатывает ту же Chapter
- **THEN** ERL SHALL разрешить новую processing operation
- **AND** durable Chapter UUID SHALL сохраняться

### Requirement: ERL-PROC-006 — Deprecated generation does not block new processing

Обработка Chapter в deprecated generation MUST NOT блокировать её обработку в новой active generation.

#### Scenario: Chapter exists in historical processing state

- **GIVEN** Chapter ранее была обработана в generation, которая теперь deprecated
- **WHEN** существует новая active generation того же logical work
- **THEN** Chapter SHALL быть допустима для processing в новой generation

### Requirement: ERL-PROC-007 — Whole-book model context is not required

ERL MUST NOT требовать помещения всей книги в один model context для нормального processing workflow.

#### Scenario: Model interaction processes one Chapter

- **WHEN** semantic processing выполняется для отдельной Chapter
- **THEN** workflow SHALL иметь возможность завершить Chapter-level processing без передачи всей книги в один model context

### Requirement: ERL-PROC-008 — Segmentation is temporary processing state

Если Chapter слишком велика для одной extraction operation, ERL MUST допускать её разделение на temporary processing segments.

Segmentation MUST относиться только к staging/execution и MUST NOT менять persistent Chapter Note или создавать новые persistent Chapter identities.

#### Scenario: Large Chapter is segmented

- **GIVEN** Chapter слишком велика для одной extraction operation
- **WHEN** ERL делит её на processing segments
- **THEN** segments SHALL существовать только как staging/execution units
- **AND** persistent Chapter Note SHALL оставаться неизменной как source entity
- **AND** segmentation SHALL NOT создавать новые Chapter UUID

### Requirement: ERL-SKILL-001 — Book-level orchestration adds no new semantics

Book-level orchestration MUST NOT вводить новую ERL processing semantics.

Оно MUST последовательно использовать chapter-level workflow.

#### Scenario: Book-level processing orchestration is executed

- **WHEN** book-level extraction или ingestion orchestration обрабатывает несколько Chapters
- **THEN** orchestration SHALL последовательно использовать соответствующий chapter-level workflow
- **AND** semantic rules каждой Chapter SHALL оставаться теми же, что и при отдельном Chapter-level invocation
- **AND** book-level orchestration SHALL NOT вводить отдельную альтернативную processing model
