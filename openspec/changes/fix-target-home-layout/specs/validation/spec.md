## MODIFIED Requirements

### Requirement: ERL-CHECK-001 — Recorded UUIDs resolve to canonical target-home documents

Все UUID из `<ZETTELKASTEN_HOME>/.state/erl/works/` MUST существовать как соответствующие documents в `<ZETTELKASTEN_HOME>/notes/`, если record не помечен как допустимая historical/tombstone relation.

#### Scenario: Recorded UUID is validated

- **GIVEN** UUID записан в `<ZETTELKASTEN_HOME>/.state/erl/works/`
- **WHEN** `erl-check` разрешает соответствующий document
- **THEN** document SHALL существовать в `<ZETTELKASTEN_HOME>/notes/`
- **AND** nested `vault/notes/` SHALL NOT использоваться как fallback

## ADDED Requirements

### Requirement: ERL-CHECK-026 — Target home layout is validated

`erl-check` MUST проверять canonical target-home layout и MUST обнаруживать legacy nested `vault/` layout без изменения данных.

#### Scenario: Canonical layout is valid

- **GIVEN** documents находятся в `<ZETTELKASTEN_HOME>/notes/`, а state — в `<ZETTELKASTEN_HOME>/.state/erl/`
- **WHEN** выполняется `erl-check`
- **THEN** layout SHALL считаться canonical

#### Scenario: Legacy nested layout exists

- **GIVEN** documents или ERL state обнаружены под `<ZETTELKASTEN_HOME>/vault/`
- **WHEN** выполняется `erl-check`
- **THEN** checker SHALL вывести `HOME_LAYOUT_MIGRATION_REQUIRED`
- **AND** SHALL указать обнаруженные legacy paths
- **AND** SHALL NOT изменять данные
