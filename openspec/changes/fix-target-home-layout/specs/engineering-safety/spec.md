## ADDED Requirements

### Requirement: ERL-TEST-001 — Delta-spec has a deterministically named primary regression test

Каждый ERL OpenSpec change, для которого создаётся regression coverage, MUST иметь primary regression test с именем, детерминированно производным от имени change directory.

Для ERL filename MUST иметь форму `erl-<behavior-slug>.zsh`. `behavior-slug` MUST вычисляться заменой одного leading change-kind prefix `fix-`, `add-`, `change-`, `update-`, `migrate-`, `refactor-` или `implement-` на project prefix `erl-`. Если известный change-kind prefix отсутствует, project prefix MUST добавляться к полному change name.

Дополнительные regression tests MAY существовать, но MUST NOT заменять обязательный primary test.

#### Scenario: Fix change creates its primary regression test

- **GIVEN** OpenSpec change directory называется `fix-target-home-layout`
- **WHEN** для change добавляется regression coverage
- **THEN** primary regression test SHALL называться `erl-target-home-layout.zsh`
- **AND** test SHALL находиться в canonical ERL tests directory

#### Scenario: Change has no recognized change-kind prefix

- **GIVEN** OpenSpec change directory называется `target-home-layout`
- **WHEN** вычисляется имя primary regression test
- **THEN** filename SHALL быть `erl-target-home-layout.zsh`

#### Scenario: Additional focused tests are added

- **GIVEN** primary regression test существует с canonical derived name
- **WHEN** implementation требует дополнительные focused tests
- **THEN** дополнительные test files MAY иметь более узкие имена
- **AND** canonical primary regression test SHALL сохраняться
