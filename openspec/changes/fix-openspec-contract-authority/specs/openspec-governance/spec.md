## ADDED Requirements

### Requirement: ERL-GOVERNANCE-001 — All consumers resolve the same current baseline

Project configuration, AGENTS, developer tooling и legacy docs MUST согласованно указывать openspec/specs как текущий normative source. Active/archived changes MUST оставаться planning/history; legacy requirements MUST не переопределять baseline при расхождении.

#### Scenario: Config still declares legacy requirements normative

- **GIVEN** canonical OS-ARCHIVE-005 назначает openspec/specs source of truth
- **WHEN** authority gate проверяет config/AGENTS/legacy wording
- **THEN** gate SHALL выявить конфликт и блокировать readiness до исправления

#### Scenario: An old archived delta contradicts current behavior

- **GIVEN** archive содержит прежний contract
- **WHEN** consumer разрешает требование
- **THEN** он SHALL использовать current canonical spec, сохраняя archive только как history

### Requirement: ERL-GOVERNANCE-002 — Requirement completion is backed by behavioral evidence

Traceability MUST связывать audit findings и применимые requirement IDs с named behavioral tests и execution evidence. Написанный proposal, правильное имя теста или наличие literal phrase MUST NOT считаться реализацией; SKIP/unknown MUST отражаться отдельно.

#### Scenario: A finding has a valid delta but no implementation

- **GIVEN** proposal/specs/tasks прошли validation, tasks открыты
- **WHEN** строится remediation status
- **THEN** finding SHALL быть planned, не fixed

#### Scenario: Required evidence is missing at archive

- **GIVEN** implementation tasks отмечены завершёнными, но acceptance run отсутствует
- **WHEN** archive readiness проверяется
- **THEN** archive SHALL блокироваться с указанием missing evidence
