## ADDED Requirements

### Requirement: ERL-BOOT-001 — Installation is reproducible from declared prerequisites

Документация MUST задавать полный путь от clean checkout/source archive до первого проверенного Book/Chapter workflow с declared dependencies, roots и host contract. Portable example MUST работать с другими explicit local paths; Lexi MUST сохранять exact Vault binding.

#### Scenario: New user installs in a path containing spaces

- **GIVEN** доступны только documented dependencies и supported host
- **WHEN** пользователь выполняет published installation/example steps в изолированной среде
- **THEN** Book import, export, deterministic staged input, ingestion и check SHALL пройти
- **AND** личные каталоги автора SHALL не требоваться

### Requirement: ERL-BOOT-002 — Doctor reports readiness without mutation

erl-doctor MUST быть read-only и в --json выдавать root/dependency/host/layout readiness и actionable diagnostics. Отсутствующий prerequisite MUST давать ненулевой result class и конкретный следующий шаг; doctor MUST NOT исправлять bindings, устанавливать tools или создавать документы.

#### Scenario: Host or required converter is missing

- **GIVEN** конфигурация неполна
- **WHEN** запускается doctor --json
- **THEN** результат SHALL перечислить missing capabilities и effective roots
- **AND** hash inventory target SHALL не измениться

#### Scenario: Unsupported flat Vault is selected

- **GIVEN** target содержит исторические root-level UUID.adoc вместо declared notes layout
- **WHEN** doctor проверяет layout
- **THEN** он SHALL указать unsupported layout и explicit migration/contract gap
- **AND** silent move SHALL не выполняться

### Requirement: ERL-BOOT-003 — Embedded payload is reproducibly built from reviewed sources

Skill payload build MUST иметь документированные source inputs, version/hash manifest и воспроизводимую проверку byte parity с reference skills. Изменение contract MUST NOT выпускаться с stale embedded payload; credentials/local install metadata MUST исключаться.

#### Scenario: Reference skill changes before release

- **GIVEN** reference contract обновлён, embedded payload старый
- **WHEN** запускается payload gate
- **THEN** gate SHALL вернуть drift failure до release

#### Scenario: Two clean builds use the same source inputs

- **GIVEN** reference skill tree и payload settings идентичны
- **WHEN** выполняются два documented builds
- **THEN** их normalized payload manifest и content hashes SHALL совпасть
