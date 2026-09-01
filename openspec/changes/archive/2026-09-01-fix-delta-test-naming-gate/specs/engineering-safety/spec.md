## ADDED Requirements

### Requirement: ERL-TEST-002 — Primary regression gate учитывает lifecycle change

ERL validation MUST различать незавершённый planning/implementation change и change, у которого все implementation tasks отмечены выполненными. Отсутствие `tests/erl-<behavior-slug>.zsh` MUST приводить к validation failure для завершённого change, но MUST NOT блокировать repository suite только из-за активного change с невыполненными tasks.

Deterministic naming rule `ERL-TEST-001` MUST сохраняться. Planning-only исключение MUST NOT считаться освобождением от primary regression: до отметки всех tasks выполненными change MUST получить свой полноценный primary test.

#### Scenario: Planning-only change ещё не имеет primary test

- **GIVEN** active OpenSpec change содержит хотя бы одну невыполненную implementation task
- **AND** derived primary regression test ещё отсутствует
- **WHEN** выполняется repository regression-test naming validation
- **THEN** отсутствие test SHALL NOT завершать repository suite ошибкой
- **AND** change SHALL оставаться незавершённым

#### Scenario: Completed change не имеет primary test

- **GIVEN** все implementation tasks active OpenSpec change отмечены выполненными
- **AND** derived primary regression test отсутствует
- **WHEN** выполняется repository regression-test naming validation
- **THEN** validation SHALL завершиться ошибкой
- **AND** diagnostic SHALL содержать change name и ожидаемый test path

#### Scenario: Completed change имеет правильно названный primary test

- **GIVEN** все implementation tasks change отмечены выполненными
- **AND** существует executable или source-controlled test `tests/erl-<behavior-slug>.zsh`
- **WHEN** выполняется repository regression-test naming validation
- **THEN** naming gate SHALL принять этот change

#### Scenario: Additional test не заменяет primary regression

- **GIVEN** completed change имеет дополнительные focused tests, но не имеет derived primary test
- **WHEN** выполняется repository regression-test naming validation
- **THEN** validation SHALL завершиться ошибкой отсутствующего primary test
