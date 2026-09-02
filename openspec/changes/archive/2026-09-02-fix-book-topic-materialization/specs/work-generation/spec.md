## MODIFIED Requirements

### Requirement: ERL-BOOK-006 — Book is a canonical Topic

Каждая retained или active ERL Book generation MUST быть представлена существующей canonical Vault Topic конкретной книги.

State-only generation, type-compatible substitute или Topic, чья видимая presentation представляет только тематическую категорию вместо книги, MUST NOT считаться допустимым Book representation.

#### Scenario: Book representation is created

- **WHEN** ERL создаёт Vault representation Book generation
- **THEN** representation SHALL быть существующей canonical Topic
- **AND** Topic SHALL представлять конкретную книгу, связанную с logical work
- **AND** ERL SHALL NOT вводить отдельный Vault document type для Book

#### Scenario: Generation state exists without its Book Topic

- **GIVEN** persistent work state содержит retained или active generation UUID
- **WHEN** canonical Topic с этим UUID отсутствует или представляет только thematic category вместо книги
- **THEN** generation SHALL считаться невалидной
- **AND** state-only representation SHALL NOT считаться выполнением `Book = Topic`

### Requirement: ERL-BOOK-007 — Book Topic UUID identifies a generation

Book Topic MUST представлять одну semantic processing generation logical work.

Book Topic UUID MUST быть identity этой generation. Generation state MUST NOT публиковаться как успешно созданный до materialization и validation соответствующей Book Topic.

#### Scenario: Semantic generation is created

- **WHEN** ERL создаёт новую semantic processing generation logical work
- **THEN** SHALL быть создана соответствующая Book Topic
- **AND** UUID этой Topic SHALL идентифицировать generation
- **AND** Book Topic UUID SHALL NOT заменять stable `WORK_ID`
- **AND** successful generation state SHALL ссылаться на существующую validated Book Topic с тем же UUID

#### Scenario: Book Topic construction or validation fails

- **WHEN** соответствующая Book Topic не может быть создана или не проходит post-creation validation
- **THEN** операция SHALL завершиться ошибкой
- **AND** generation SHALL NOT публиковаться как active или retained
- **AND** response SHALL NOT сообщать успешное создание `generation_uuid`

### Requirement: ERL-BOOK-013 — Book Topic follows canonical presentation contract

Book Topic MUST создаваться canonical Topic constructor и MUST соблюдать host Topic presentation contract для title, `:description:` и `:doclink:`.

Видимый title Book Topic MUST идентифицировать книгу по canonical title logical work. Тематический `:key-topic:` MUST оставаться отдельной host-compatible классификацией и MUST NOT подменять title книги.

Logical-work metadata и название произведения MUST храниться в persistent work state и MAY дополнительно присутствовать в body, но MUST NOT подменять semantics `:key-topic:`.

#### Scenario: Book Topic is constructed

- **WHEN** ERL создаёт Book Topic
- **THEN** SHALL использоваться canonical Topic constructor
- **AND** title SHALL идентифицировать книгу по canonical title logical work
- **AND** `:description:` и `:doclink:` SHALL соответствовать host Topic presentation contract
- **AND** `:key-topic:` SHALL сохранять отдельную thematic host semantics
- **AND** logical-work metadata SHALL NOT кодироваться путём переопределения `:key-topic:` semantics

#### Scenario: Thematic key differs from book title

- **GIVEN** canonical title книги и thematic `:key-topic:` имеют разные значения
- **WHEN** ERL materializes Book Topic
- **THEN** видимый title SHALL быть основан на canonical title книги
- **AND** `:key-topic:` SHALL содержать thematic key

## ADDED Requirements

### Requirement: ERL-BOOK-014 — Book Topic and generation state are committed atomically

Создание Book Topic, generation state и active-generation pointer MUST быть одной recoverable semantic operation: либо все artifacts становятся согласованно доступными, либо операция MUST выполнить rollback до предыдущего валидного состояния.

#### Scenario: State update fails after Book Topic creation

- **GIVEN** canonical Book Topic создана в рамках нового ingest
- **WHEN** запись generation state или active-generation pointer завершается ошибкой
- **THEN** новый Book Topic и частично созданный state SHALL быть удалены или восстановлены через transaction rollback
- **AND** logical work SHALL вернуться к предыдущему валидному состоянию

#### Scenario: Book Topic validation fails before commit

- **WHEN** созданная Book Topic не соответствует canonical Book Topic contract
- **THEN** transaction SHALL NOT commit generation state
- **AND** операция SHALL оставить recoverable diagnostic или завершённый rollback record
