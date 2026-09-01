## ADDED Requirements

### Requirement: ERL-DOC-008 — All ERL cards contain human-readable AsciiDoc

Каждый persistent ERL document роли Book, Chapter, Vocabulary или Occurrence MUST быть валидным UTF-8 AsciiDoc document, пригодным для непосредственного чтения человеком как самостоятельная карточка.

Карточка MUST иметь понятный document title и непустое body с role-relevant information. Body MUST представлять данные с помощью AsciiDoc sections, paragraphs, description lists и canonical links с осмысленными labels там, где эти элементы применимы. Читателю MUST быть возможно понять назначение карточки и её основное содержимое без чтения persistent ERL state или raw source artifact.

Карточка MUST сохранять применимый canonical и role-specific structural contract. Machine state, raw JSON/YAML serialization, необработанный HTML/XML source, control characters и unresolved template placeholders MUST NOT подменять человекочитаемое body или значения его обязательных полей.

#### Scenario: Book card is created

- **WHEN** ERL создаёт Book Topic
- **THEN** Topic SHALL быть valid UTF-8 AsciiDoc
- **AND** SHALL иметь понятный title и непустое body, идентифицирующее книгу для читателя
- **AND** SHALL представлять navigation или descriptive information как читаемый AsciiDoc, а не raw machine state

#### Scenario: Chapter card is created

- **WHEN** ERL создаёт Chapter Note
- **THEN** Note SHALL быть valid UTF-8 AsciiDoc
- **AND** SHALL иметь понятный chapter title и непустое body с readable book/chapter context
- **AND** source locator или другие технические значения SHALL быть снабжены человекочитаемыми labels, если они показаны в карточке

#### Scenario: Vocabulary card is created

- **WHEN** ERL создаёт Vocabulary Memo
- **THEN** Memo SHALL быть valid UTF-8 AsciiDoc
- **AND** SHALL сохранять lexical card structure согласно `ERL-VOC-003`
- **AND** lexical identity, meaning и доступный context SHALL быть представлены как читаемые labelled fields или prose

#### Scenario: Occurrence card is created

- **WHEN** ERL создаёт Occurrence Memo
- **THEN** Memo SHALL быть valid UTF-8 AsciiDoc
- **AND** SHALL сохранять structural schema согласно `ERL-OCC-004`
- **AND** Vocabulary link SHALL иметь осмысленный label
- **AND** Context section SHALL содержать непустой читаемый context встречи

#### Scenario: Generated content contains machine-oriented artifacts

- **WHEN** обязательное содержимое ERL card состоит из raw serialization, необработанного source markup, control characters или unresolved placeholder
- **THEN** card SHALL NOT считаться соответствующей human-readable AsciiDoc contract

