## MODIFIED Requirements

### Requirement: ERL-BOOK-012 — Book Topic key-topic equals canonical book title

При создании Book Topic ERL MUST установить host-compatible `:key-topic:` в точное значение canonical title logical work.

Этот key MUST NOT быть `WORK_ID`, generation identity или иным ERL foreign key. ERL relationships MUST восстанавливаться по persistent state и canonical links, а не по совпадению title key.

#### Scenario: Book Topic is created

- **GIVEN** canonical title logical work равен `Friday`
- **WHEN** ERL создаёт canonical Book Topic
- **THEN** Topic SHALL получить `:key-topic: Friday`
- **AND** значение SHALL точно совпадать с visible canonical title книги
- **AND** значение SHALL NOT быть `WORK_ID` или generation identity

#### Scenario: Explicit key-topic conflicts with title

- **GIVEN** canonical title равен `Friday`
- **WHEN** caller передаёт explicit `--key-topic "English Reading"`
- **THEN** ingest SHALL завершиться deterministic error до первой mutation
- **AND** error SHALL содержать expected `Friday` и actual `English Reading`
- **AND** Book Topic, Chapters и persistent work state SHALL NOT создаваться или изменяться

### Requirement: ERL-BOOK-013 — Book Topic follows canonical presentation contract

Book Topic MUST создаваться canonical Topic constructor и MUST соблюдать host Topic presentation contract для title, `:description:`, `:doclink:` и `:key-topic:`.

Visible title Book Topic и `:key-topic:` MUST точно идентифицировать книгу по одному canonical title logical work. Logical-work identity MUST храниться в persistent work state и MUST NOT кодироваться в `:key-topic:`.

#### Scenario: Book Topic is constructed

- **WHEN** ERL создаёт Book Topic для canonical title `Friday`
- **THEN** SHALL использоваться canonical Topic constructor
- **AND** visible title SHALL быть `Friday`
- **AND** `:key-topic:` SHALL быть `Friday`
- **AND** `:description:` и `:doclink:` SHALL соответствовать host Topic presentation contract
- **AND** ERL foreign keys SHALL NOT кодироваться в `:key-topic:`

#### Scenario: Thematic key differs from book title

- **GIVEN** canonical title книги и explicit `:key-topic:` имеют разные значения
- **WHEN** caller пытается materialize Book Topic
- **THEN** ERL SHALL отклонить conflict до mutation
- **AND** Book Topic SHALL NOT создаваться с отдельным thematic key
