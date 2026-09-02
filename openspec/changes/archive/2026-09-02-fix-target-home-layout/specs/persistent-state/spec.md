## MODIFIED Requirements

### Requirement: ERL-STATE-001 — ERL uses a single state namespace under target home

ERL MUST использовать единый local state namespace `<ZETTELKASTEN_HOME>/.state/erl/`.

#### Scenario: ERL local state is stored

- **WHEN** ERL сохраняет local state
- **THEN** state SHALL находиться внутри `<ZETTELKASTEN_HOME>/.state/erl/`
- **AND** state SHALL NOT находиться внутри дополнительного `<ZETTELKASTEN_HOME>/vault/`

### Requirement: ERL-STATE-003 — ERL source of truth has two canonical parts

Источник истины ERL MUST состоять из:

- canonical documents в `<ZETTELKASTEN_HOME>/notes/`;
- persistent work state в `<ZETTELKASTEN_HOME>/.state/erl/works/`.

#### Scenario: ERL source of truth is determined

- **WHEN** определяется source of truth ERL
- **THEN** он SHALL включать canonical documents из `<ZETTELKASTEN_HOME>/notes/`
- **AND** SHALL включать `<ZETTELKASTEN_HOME>/.state/erl/works/`
- **AND** SHALL NOT зависеть от nested `vault/` layout

## ADDED Requirements

### Requirement: ERL-STATE-018 — Legacy nested layout requires explicit migration

Обнаружение ERL data в `<ZETTELKASTEN_HOME>/vault/notes/` или `<ZETTELKASTEN_HOME>/vault/.state/erl/` MUST NOT приводить к silent adoption или implicit move.

Migration MUST поддерживать dry-run, collision detection, explicit apply, transaction journal, rollback и recovery. До подтверждённой migration mutation operations MUST завершаться явной diagnostic error.

#### Scenario: Legacy nested layout is detected

- **GIVEN** ERL data существует в legacy nested `vault/` layout
- **WHEN** mutation operation разрешает target Zettelkasten home
- **THEN** operation SHALL завершиться diagnostic `HOME_LAYOUT_MIGRATION_REQUIRED`
- **AND** SHALL NOT перемещать или изменять данные автоматически
- **AND** diagnostic SHALL указать canonical target paths

#### Scenario: Migration dry-run finds a collision

- **GIVEN** legacy source artifact и canonical target path существуют одновременно
- **WHEN** migration выполняет dry-run
- **THEN** collision SHALL быть показана до mutation
- **AND** apply SHALL быть запрещён до явного разрешения конфликта

#### Scenario: Applied migration fails

- **GIVEN** migration была явно подтверждена
- **WHEN** failure происходит после начала mutation
- **THEN** migration SHALL быть recoverable через transaction journal
- **AND** rollback SHALL NOT silently overwrite unexpected user changes
