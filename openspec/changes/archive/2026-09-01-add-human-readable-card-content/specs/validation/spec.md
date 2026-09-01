## ADDED Requirements

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

