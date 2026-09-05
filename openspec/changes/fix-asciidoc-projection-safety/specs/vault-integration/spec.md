## ADDED Requirements

### Requirement: ERL-ASCIIDOC-001 — User text is safely serialized into canonical cards

Titles, descriptions, lexical values и context MUST сохранять читаемый смысл при безопасном AsciiDoc serialization. Brackets, backslashes, Unicode и допустимый multiline input MUST NOT создавать unintended attributes, sections или extra links; unsupported text MUST отклоняться до записи.

#### Scenario: Description contains brackets and backslashes

- **GIVEN** candidate label содержит ] и обратную косую черту вместе с Unicode
- **WHEN** ingest создаёт link и checker читает его
- **THEN** link SHALL разрешаться к единственному ожидаемому UUID с читаемой description

#### Scenario: Input attempts a header or section injection

- **GIVEN** title или lexical field содержит перевод строки и :deprecated: либо == заголовок
- **WHEN** runtime сериализует поле
- **THEN** непреднамеренной structure SHALL не возникнуть либо input SHALL быть отклонён до mutation

### Requirement: ERL-ASCIIDOC-002 — Projection edits preserve user-owned content

Изменение ERL projection MUST сохранять unrelated bytes и user-owned prose в документе. Если existing section неоднозначна или содержит конфликтующие ручные links, mutation MUST выдать conflict/dry-run explanation вместо destructive replacement.

#### Scenario: Book section includes a handwritten paragraph

- **GIVEN** durable Chapter содержит Book link и дополнительный user paragraph
- **WHEN** rebind или repair обновляет projection
- **THEN** paragraph SHALL сохраниться либо operation SHALL остановиться с explicit conflict

#### Scenario: File changes after projection plan

- **GIVEN** пользователь редактирует target между dry-run и apply
- **WHEN** projection mutation проверяет hashes
- **THEN** внешняя правка SHALL не перезаписываться
