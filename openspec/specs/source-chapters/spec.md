# source-chapters Specification

## Purpose

Определить модель source edition и Chapter identity в English Reading Lab: canonical Chapter Note, durable Chapter UUID, SOURCE_ID, source fingerprint, CHAPTER_LOCATOR и правила разрешения Chapter между processing generations.

## Requirements

### Requirement: ERL-CHAPTER-001 — Chapter is a canonical Note

ERL Chapter MUST быть представлен canonical Vault Note.

#### Scenario: Chapter representation is created

- **WHEN** ERL создаёт persistent representation Chapter
- **THEN** representation SHALL быть canonical Note
- **AND** ERL SHALL NOT вводить отдельный Vault document type для Chapter

### Requirement: ERL-CHAPTER-002 — Chapter UUID is durable across generations

Chapter MUST быть durable source entity.

Один Chapter UUID MUST иметь возможность использоваться последовательными Book generations одного logical work.

#### Scenario: New Book generation reuses an existing Chapter

- **GIVEN** source Chapter уже имеет canonical Chapter UUID
- **WHEN** для logical work создаётся новая Book generation
- **THEN** ERL SHALL сохранять существующий Chapter UUID для той же resolved source Chapter
- **AND** новая generation MAY ссылаться на этот же Chapter UUID

### Requirement: ERL-CHAPTER-003 — Chapter Note has no ERL-specific identity attributes

Chapter Note MUST NOT хранить ERL-specific identity attributes.

#### Scenario: Chapter Note is persisted

- **WHEN** ERL создаёт или обновляет Chapter Note
- **THEN** Chapter identity SHALL NOT кодироваться через `:erl-*:` attributes
- **AND** ERL-specific source identity SHALL храниться вне canonical Vault metadata

### Requirement: ERL-CHAPTER-004 — Full Chapter source identity lives in persistent work state

Полная source identity Chapter MUST храниться в `.state/erl/works/<work-slug>/sources/`.

Source/chapter record MUST содержать достаточные данные для связи как минимум `WORK_ID`, `SOURCE_ID`, source fingerprint, `CHAPTER_LOCATOR`, source order и Chapter UUID.

#### Scenario: Chapter mapping is persisted

- **WHEN** ERL регистрирует Chapter source mapping
- **THEN** mapping SHALL храниться в persistent source state
- **AND** SHALL содержать `WORK_ID`, `SOURCE_ID`, source fingerprint, `CHAPTER_LOCATOR`, source order и Chapter UUID

### Requirement: ERL-CHAPTER-005 — SOURCE_ID identifies a source edition

`SOURCE_ID` MUST быть stable identity конкретного source/edition внутри `WORK_ID`.

#### Scenario: Existing source edition is processed again

- **GIVEN** source edition уже имеет `SOURCE_ID`
- **WHEN** ERL повторно обрабатывает этот же зарегистрированный source
- **THEN** `SOURCE_ID` SHALL оставаться неизменным

### Requirement: ERL-CHAPTER-006 — EPUB source fingerprint uses SHA-256

Для EPUB source fingerprint v1 MUST быть SHA-256 fingerprint исходного EPUB artifact.

#### Scenario: EPUB source is registered

- **WHEN** ERL регистрирует EPUB source
- **THEN** source fingerprint SHALL вычисляться из исходного EPUB artifact с использованием SHA-256
- **AND** fingerprint SHALL идентифицировать содержимое конкретного source artifact

### Requirement: ERL-CHAPTER-007 — CHAPTER_LOCATOR is stable inside SOURCE_ID

`CHAPTER_LOCATOR` MUST быть stable внутри конкретного `SOURCE_ID`.

Для EPUB ERL SHOULD использовать canonical package-relative content href с fragment при необходимости; spine index MAY использоваться как fallback.

#### Scenario: EPUB Chapter receives a locator

- **WHEN** ERL регистрирует Chapter EPUB source
- **THEN** locator SHALL быть стабильным внутри данного `SOURCE_ID`
- **AND** ERL SHOULD предпочитать canonical package-relative content href
- **AND** spine index MAY использоваться только как fallback strategy

### Requirement: ERL-CHAPTER-008 — Chapter resolution key is composite

ERL MUST разрешать persistent Chapter mapping по composite key:

`WORK_ID × SOURCE_ID × CHAPTER_LOCATOR`.

#### Scenario: Existing Chapter mapping is resolved

- **WHEN** ERL ищет persistent Chapter для зарегистрированного source location
- **THEN** lookup SHALL учитывать `WORK_ID`, `SOURCE_ID` и `CHAPTER_LOCATOR`
- **AND** совпадения только по одному из этих компонентов SHALL быть недостаточно

### Requirement: ERL-CHAPTER-009 — Source order is not identity

Source order MUST рассматриваться только как ordering metadata и MUST NOT использоваться как Chapter identity.

#### Scenario: Chapter order changes without identity change

- **GIVEN** Chapter уже имеет persistent source mapping
- **WHEN** source order metadata изменяется без изменения source identity и locator
- **THEN** Chapter identity SHALL оставаться прежней
- **AND** новый Chapter UUID SHALL NOT создаваться только из-за изменения order

### Requirement: ERL-CHAPTER-010 — Different edition receives a new SOURCE_ID

Другой edition/source MUST получать новый `SOURCE_ID`, если не выполнена explicit mapping или migration procedure.

#### Scenario: Another edition of the same logical work is added

- **GIVEN** logical work уже содержит зарегистрированный source edition
- **WHEN** добавляется другой edition/source
- **THEN** новый source SHALL получить отдельный `SOURCE_ID`
- **UNLESS** explicit mapping/migration procedure нормативно устанавливает сохранение существующей source identity

### Requirement: ERL-CHAPTER-011 — Normal Book Reduce preserves Chapter Notes

Обычный `erl-book-reduce` MUST NOT deprecate durable Chapter Notes.

#### Scenario: Book generation is reduced

- **GIVEN** active generation содержит durable Chapter Notes
- **WHEN** выполняется обычный `erl-book-reduce`
- **THEN** Chapter Notes SHALL оставаться active
- **AND** Chapter UUID SHALL сохраняться для последующего использования другими generations

### Requirement: ERL-CHAPTER-016 — Next Chapter reciprocally links the previous Chapter chain tail

Если Chapter имеет completed Memo Chain и существует следующая Chapter того же `SOURCE_ID` в source order, следующая Chapter Note MUST содержать ровно одну reciprocal canonical link на tail Memo предыдущей Chapter.

Link MUST находиться в структурной секции `Reading handoff` и иметь label `Последнее memo предыдущей главы`. Она MUST указывать на tail непосредственно предыдущей Chapter, а не на произвольный Memo generation sequence.

#### Scenario: Previous Chapter chain is completed

- **GIVEN** Chapter имеет completed Memo Chain с определённым tail
- **AND** source state содержит непосредственно следующую Chapter
- **WHEN** Chapter-level ingestion commits handoff
- **THEN** следующая Chapter Note SHALL содержать canonical link на tail Memo
- **AND** link SHALL иметь label `Последнее memo предыдущей главы`
- **AND** duplicate handoff links SHALL NOT создаваться

#### Scenario: Previous Chapter has no Memo Chain

- **GIVEN** предыдущая Chapter не содержит committed Vocabulary/Occurrence nodes
- **WHEN** ERL рассматривает incoming handoff следующей Chapter
- **THEN** следующая Chapter SHALL NOT получать synthetic link на отсутствующий tail

### Requirement: ERL-CHAPTER-012 — Chapter Note inherits Book Topic key-topic

Каждая Chapter Note, прикреплённая к active Book Topic generation, MUST содержать host-defined header attribute `:key-topic:` с точным значением `:key-topic:` этой Book Topic.

Значение MUST сохранять canonical host semantics тематической группировки и MUST NOT быть `WORK_ID`, Book Topic UUID, Chapter UUID или иным ERL-local foreign key.

#### Scenario: Chapter Note is attached during Book ingest

- **GIVEN** Book Topic содержит непустой canonical `:key-topic:`
- **WHEN** ERL создаёт Chapter Note для active Book generation
- **THEN** Chapter Note SHALL получить `:key-topic:` с точным значением из Book Topic
- **AND** значение SHALL храниться как header attribute
- **AND** ERL SHALL NOT выводить его из UUID или ERL persistent state identifier

#### Scenario: Chapter Note key-topic differs from active Book Topic

- **GIVEN** Chapter Note зарегистрирована для active Book generation
- **WHEN** её `:key-topic:` отсутствует или отличается от `:key-topic:` Book Topic
- **THEN** Chapter Note SHALL считаться неприкреплённой или неверно прикреплённой
- **AND** ingest SHALL NOT считать Book–Chapter materialization успешно завершённой

### Requirement: ERL-CHAPTER-013 — Book Topic and Chapter Note have reciprocal canonical links

Active Book Topic и каждая соответствующая Chapter Note MUST содержать взаимные canonical links формата `link:UUID.adoc[Description]`.

Chapter Note MUST содержать ровно одну active Book Topic link в структурной секции `Book`. Book Topic MUST содержать ровно одну link на каждую Chapter Note текущего source в структурной секции `Chapters`, упорядоченную по source order.

#### Scenario: Chapter Note is linked to Book Topic

- **WHEN** ERL materializes Chapter Note для active Book generation
- **THEN** секция `Book` Chapter Note SHALL содержать canonical link на UUID active Book Topic
- **AND** секция `Chapters` Book Topic SHALL содержать canonical link на UUID этой Chapter Note
- **AND** обе стороны SHALL существовать после committed ingest

#### Scenario: Book contains multiple Chapters

- **GIVEN** source содержит несколько Chapters
- **WHEN** ERL формирует секцию `Chapters` Book Topic
- **THEN** Topic SHALL содержать ровно одну canonical link на каждую зарегистрированную Chapter Note текущего source
- **AND** links SHALL следовать source order
- **AND** duplicate links на один Chapter UUID SHALL NOT создаваться

### Requirement: ERL-CHAPTER-014 — Durable Chapter is rebound to the active Book Topic generation

Поскольку Chapter UUID сохраняется между generations, Chapter Note MUST иметь одну current attachment к active Book Topic generation соответствующего logical work.

При создании новой active generation ERL MUST transactionally заменить прежнюю active Book Topic link в Chapter Note новой link и MUST установить `:key-topic:`, равный новой active Book Topic. Historical generation membership MUST оставаться в persistent audit/state semantics, а не представляться второй active attachment Chapter Note.

#### Scenario: Existing source Chapter enters a new generation

- **GIVEN** durable Chapter Note была прикреплена к предыдущей Book Topic generation
- **WHEN** ERL создаёт новую active generation для того же logical work и source Chapter
- **THEN** Chapter UUID SHALL остаться прежним
- **AND** current Book link SHALL указывать на новую active Book Topic
- **AND** Chapter `:key-topic:` SHALL точно совпадать с новой Book Topic
- **AND** Chapter Note SHALL NOT сохранять вторую active Book Topic attachment

### Requirement: ERL-CHAPTER-015 — Chapter–Topic binding is transactionally materialized

Создание или rebind Chapter `:key-topic:`, Chapter→Topic links и Topic→Chapter links MUST входить в ту же recoverable semantic transaction, что и Book generation ingest.

Operation MUST завершаться только при согласованности всех Chapter Notes текущего source и Book Topic; partial binding MUST приводить к rollback до предыдущего валидного состояния.

#### Scenario: Reciprocal link update fails

- **GIVEN** Book ingest создал или изменил часть Chapter–Topic bindings
- **WHEN** запись одной из reciprocal links или `:key-topic:` завершается ошибкой
- **THEN** transaction SHALL NOT commit generation
- **AND** все созданные documents и изменения существующих Chapter Notes SHALL быть удалены или восстановлены из journal backups
- **AND** previous valid Chapter attachment SHALL быть сохранена
