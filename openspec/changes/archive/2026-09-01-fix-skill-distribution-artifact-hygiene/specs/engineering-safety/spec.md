## ADDED Requirements

### Requirement: ERL-GIT-004 — Repository distributions exclude platform metadata artifacts

ERL source repository и публикуемые skill distributions MUST NOT содержать platform- или editor-generated metadata artifacts, не являющиеся частью ERL source contract, включая `.DS_Store`.

Repository ignore policy и validation workflow MUST предотвращать незаметное включение таких artifacts. Уже существующая проверка запрещённых skill installation artifacts MUST сохраняться.

#### Scenario: ERL repository distribution is validated

- **GIVEN** ERL repository или skill distribution подготовлены к validation
- **WHEN** выполняется repository/distribution hygiene check
- **THEN** platform/editor metadata artifacts SHALL отсутствовать
- **AND** обнаруженный `.DS_Store` SHALL приводить к validation failure с указанием path

#### Scenario: macOS creates ignored metadata locally

- **WHEN** поддерживаемая platform создаёт `.DS_Store` в ERL working tree
- **THEN** repository ignore policy SHALL исключать artifact из source distribution
- **AND** canonical ERL source files SHALL оставаться неизменными

#### Scenario: Other forbidden skill artifacts are checked

- **WHEN** hygiene fix для `.DS_Store` применяется
- **THEN** validation SHALL продолжать запрещать ранее распознаваемые skill installation artifacts
- **AND** fix SHALL NOT ослаблять существующий distribution boundary
