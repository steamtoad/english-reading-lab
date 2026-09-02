## MODIFIED Requirements

### Requirement: ERL-TEST-002 — Primary regression gate учитывает lifecycle change

ERL validation MUST различать незавершённый planning/implementation change и change, у которого все implementation tasks отмечены выполненными. Отсутствие `tests/erl-<behavior-slug>.zsh` MUST приводить к validation failure для завершённого change, но MUST NOT блокировать repository suite только из-за active planning change с невыполненными tasks.

Deterministic naming rule `ERL-TEST-001` MUST применяться ко всем ERL OpenSpec changes. Planning-only исключение MUST NOT считаться освобождением от primary regression: до отметки всех implementation tasks выполненными и до archive change MUST получить свой canonical primary test.

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
- **AND** diagnostic SHALL содержать change name и exact expected test path

#### Scenario: Completed change имеет правильно названный primary test

- **GIVEN** все implementation tasks change отмечены выполненными
- **AND** существует executable или source-controlled test `tests/erl-<behavior-slug>.zsh`
- **WHEN** выполняется repository regression-test naming validation
- **THEN** naming gate SHALL принять этот change

#### Scenario: Additional test не заменяет primary regression

- **GIVEN** completed change имеет дополнительные focused tests, но не имеет derived primary test
- **WHEN** выполняется repository regression-test naming validation
- **THEN** validation SHALL завершиться ошибкой отсутствующего primary test

#### Scenario: Change архивируется без primary test

- **GIVEN** ERL OpenSpec change готовится к archive
- **AND** canonical derived primary regression test отсутствует
- **WHEN** выполняется archive validation
- **THEN** archive SHALL быть заблокирован
- **AND** diagnostic SHALL указать exact expected test path

### Requirement: ERL-TEST-001 — Delta-spec has a deterministically named primary regression test

Каждый ERL OpenSpec change MUST иметь primary regression test с именем, детерминированно производным от имени change directory.

Для ERL filename MUST иметь форму `erl-<behavior-slug>.zsh`. `behavior-slug` MUST вычисляться удалением ровно одного leading change-kind prefix `fix-`, `add-`, `change-`, `update-`, `migrate-`, `refactor-`, `implement-` или `remove-`, после чего MUST добавляться project prefix `erl-`. Если известный change-kind prefix отсутствует, project prefix MUST добавляться к полному change name.

Дополнительные regression tests MAY существовать, но MUST NOT заменять обязательный primary test.

#### Scenario: Fix change creates its primary regression test

- **GIVEN** OpenSpec change directory называется `fix-target-home-layout`
- **WHEN** вычисляется обязательное имя primary regression test
- **THEN** primary regression test SHALL называться `erl-target-home-layout.zsh`
- **AND** test SHALL находиться в canonical ERL tests directory

#### Scenario: Remove change creates its primary regression test

- **GIVEN** OpenSpec change directory называется `remove-chapter-vocabulary-quota`
- **WHEN** вычисляется обязательное имя primary regression test
- **THEN** filename SHALL быть `erl-chapter-vocabulary-quota.zsh`
- **AND** filename SHALL NOT быть `erl-remove-chapter-vocabulary-quota.zsh`

#### Scenario: Change has no recognized change-kind prefix

- **GIVEN** OpenSpec change directory называется `target-home-layout`
- **WHEN** вычисляется имя primary regression test
- **THEN** filename SHALL быть `erl-target-home-layout.zsh`

#### Scenario: Additional focused tests are added

- **GIVEN** primary regression test существует с canonical derived name
- **WHEN** implementation требует дополнительные focused tests
- **THEN** дополнительные test files MAY иметь более узкие имена
- **AND** canonical primary regression test SHALL сохраняться

#### Scenario: Every delta declares its primary test task

- **GIVEN** создаётся ERL OpenSpec change с implementation tasks
- **WHEN** формируется `tasks.md`
- **THEN** tasks SHALL содержать создание или обновление canonical derived primary regression test
- **AND** verification SHALL включать запуск этого test
