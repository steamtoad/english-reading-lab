# work-generation Specification

## Purpose

Определить модель logical work и Book generation в English Reading Lab: стабильную identity произведения, связь WORK_ID с canonical Vault Topic generations, lifecycle active generation и использование host-compatible `:key-topic:` без превращения Vault metadata в ERL foreign keys.

## Requirements

### Requirement: ERL-BOOK-001 — Logical work has stable ERL identity

Logical work MUST представлять стабильную ERL identity произведения независимо от конкретной source edition или Book generation.

#### Scenario: Work receives another processing generation

- **GIVEN** logical work уже существует
- **WHEN** для него создаётся новая semantic processing generation
- **THEN** logical work identity SHALL оставаться неизменной
- **AND** новая generation SHALL относиться к тому же logical work

### Requirement: ERL-BOOK-002 — WORK_ID is stable and ERL-local

При первом ingest logical work MUST получить stable opaque `WORK_ID`.

`WORK_ID` MUST храниться только в persistent ERL work state и MUST NOT записываться в Vault document attributes.

#### Scenario: New logical work is ingested

- **WHEN** ERL впервые создаёт persistent state для нового logical work
- **THEN** work SHALL получить stable opaque `WORK_ID`
- **AND** `WORK_ID` SHALL быть сохранён в `.state/erl/works/`
- **AND** `WORK_ID` SHALL NOT записываться в attributes canonical Vault documents

### Requirement: ERL-BOOK-003 — WORK_ID is not derived from mutable metadata

`WORK_ID` MUST NOT выводиться из title, work slug, ISBN, source filename или Book Topic UUID.

#### Scenario: Logical work metadata changes

- **GIVEN** logical work уже имеет `WORK_ID`
- **WHEN** изменяется title, slug, source filename или другая human-readable metadata
- **THEN** `WORK_ID` SHALL оставаться неизменным
- **AND** новое значение SHALL NOT вычисляться из изменённой metadata

### Requirement: ERL-BOOK-004 — Work slug is a locator, not identity

`<work-slug>` в `.state/erl/works/<work-slug>/` MUST рассматриваться как human-readable path locator и MUST NOT быть canonical identity logical work.

#### Scenario: Work is resolved from persistent state

- **WHEN** ERL работает с `.state/erl/works/<work-slug>/`
- **THEN** `<work-slug>` MAY использоваться для human-readable filesystem location
- **BUT** semantic identity work SHALL определяться `WORK_ID`, а не slug

### Requirement: ERL-BOOK-005 — Renaming work slug preserves identity

Переименование `<work-slug>` MUST NOT менять `WORK_ID`, Vault UUID или semantic identity logical work.

#### Scenario: Work slug is renamed

- **GIVEN** logical work существует под `.state/erl/works/<old-slug>/`
- **WHEN** выполняется поддерживаемое переименование в `<new-slug>`
- **THEN** `WORK_ID` SHALL оставаться прежним
- **AND** связанные Vault document UUID SHALL оставаться прежними
- **AND** semantic identity произведения SHALL оставаться прежней

### Requirement: ERL-BOOK-006 — Book is a canonical Topic

ERL Book MUST быть представлен canonical Vault Topic.

#### Scenario: Book representation is created

- **WHEN** ERL создаёт Vault representation Book generation
- **THEN** representation SHALL быть canonical Topic
- **AND** ERL SHALL NOT вводить отдельный Vault document type для Book

### Requirement: ERL-BOOK-007 — Book Topic UUID identifies a generation

Book Topic MUST представлять одну semantic processing generation logical work.

Book Topic UUID MUST быть identity этой generation.

#### Scenario: Semantic generation is created

- **WHEN** ERL создаёт новую semantic processing generation logical work
- **THEN** SHALL быть создана соответствующая Book Topic
- **AND** UUID этой Topic SHALL идентифицировать generation
- **AND** Book Topic UUID SHALL NOT заменять stable `WORK_ID`

### Requirement: ERL-BOOK-008 — Work manifest tracks retained generations

Work manifest MUST связывать `WORK_ID` со всеми retained Book Topic generation UUID.

Generation, успешно закрытая через `erl-book-reduce`, MUST быть удалена из manifest согласно `ERL-REDUCE-025`, при этом её deprecated Vault Topic MUST оставаться historical artifact.

#### Scenario: Generation is retained

- **GIVEN** Book generation относится к logical work и ещё сохраняется в persistent work state
- **WHEN** work manifest читается
- **THEN** manifest SHALL содержать соответствующий Book Topic generation UUID

#### Scenario: Generation is closed by erl-book-reduce

- **GIVEN** generation успешно закрывается через `erl-book-reduce`
- **WHEN** Reduce transaction commits
- **THEN** generation reference SHALL быть удалена из work manifest согласно `ERL-REDUCE-025`
- **AND** deprecated Book Topic SHALL оставаться historical Vault artifact

### Requirement: ERL-BOOK-009 — At most one active generation per work

Для одного `WORK_ID` MUST существовать не более одной active Book generation.

Active/deprecated state MUST определяться canonical `:deprecated:` semantics Book Topic и MUST согласовываться с persistent work state.

#### Scenario: Another generation is already active

- **GIVEN** logical work уже имеет active Book generation
- **WHEN** операция пытается установить другую generation active без закрытия предыдущей
- **THEN** операция SHALL быть отклонена или заблокирована
- **AND** две active generations одного `WORK_ID` SHALL NOT существовать одновременно

#### Scenario: Active state is validated

- **WHEN** ERL проверяет active Book generation
- **THEN** canonical `:deprecated:` state соответствующей Book Topic SHALL согласовываться с persistent work state
- **AND** deprecated Book Topic SHALL NOT оставаться active generation

### Requirement: ERL-BOOK-010 — New semantic generation gets a new Book Topic UUID

Каждая новая semantic generation MUST получать новый Book Topic UUID.

#### Scenario: Processing semantics change

- **WHEN** ERL создаёт новую semantic generation logical work
- **THEN** SHALL быть создан новый canonical Book Topic
- **AND** его UUID SHALL отличаться от UUID предыдущей generation

### Requirement: ERL-BOOK-011 — Processing policy may vary between generations

ERL MUST допускать использование разных CEFR threshold, extraction policy, lexical policy, card format, source processing order и ingestion policy в разных Book generations одного logical work.

#### Scenario: New generation changes processing policy

- **GIVEN** предыдущая generation использовала определённую processing policy
- **WHEN** новая semantic generation создаётся с изменённой policy
- **THEN** новая generation MAY использовать отличающиеся CEFR, extraction, lexical, card, ordering или ingestion rules
- **AND** предыдущая generation SHALL NOT переписываться молча новой policy

### Requirement: ERL-BOOK-012 — Book Topic uses explicit thematic key-topic

При создании Book Topic пользователь или ERL workflow MUST явно задать непустой host-compatible thematic key для `:key-topic:`.

Этот key MUST NOT быть `WORK_ID`, generation identity или другим ERL foreign key и MUST NOT использоваться для восстановления ERL relationships.

#### Scenario: Book Topic is created

- **WHEN** ERL создаёт canonical Book Topic
- **THEN** Topic SHALL получить непустой host-compatible `:key-topic:`
- **AND** значение SHALL иметь thematic host semantics
- **AND** значение SHALL NOT быть `WORK_ID` или generation identity
- **AND** ERL SHALL NOT использовать его для восстановления persistent ERL relationships

### Requirement: ERL-BOOK-013 — Book Topic follows canonical presentation contract

Book Topic MUST создаваться canonical Topic constructor и MUST соблюдать host Topic presentation contract для title, `:description:` и `:doclink:`.

Logical-work metadata и название произведения MUST храниться в persistent work state и MAY дополнительно присутствовать в body, но MUST NOT подменять semantics `:key-topic:`.

#### Scenario: Book Topic is constructed

- **WHEN** ERL создаёт Book Topic
- **THEN** SHALL использоваться canonical Topic constructor
- **AND** title, `:description:` и `:doclink:` SHALL соответствовать host Topic presentation contract
- **AND** logical-work metadata SHALL NOT кодироваться путём переопределения `:key-topic:` semantics
