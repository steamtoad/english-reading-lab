## Purpose

Зафиксировать воспроизводимые workloads, измерения и границы доказанной производительности локального ERL без подмены source of truth производными индексами.

## ADDED Requirements

### Requirement: ERL-PERF-001 — Performance results describe reproducible workloads

ERL MUST иметь воспроизводимые benchmark inputs и report с размерами, settings, repetitions, median/p95 duration, failures и environment metadata. Заявленный поддерживаемый scale MUST опираться на successful correctness+performance runs, а не размер synthetic fixture в коде.

#### Scenario: A library scale is advertised

- **GIVEN** harness содержит несколько configurable размеров library
- **WHEN** публикуется performance report
- **THEN** для каждого claimed scale SHALL быть измеренный run с correctness check
- **AND** неисполненный размер SHALL быть NOT VERIFIED

### Requirement: ERL-PERF-002 — Optimization preserves correctness and rebuildability

Performance comparison MUST использовать заранее заданные budgets и одинаковую correctness gate. Любая последующая cache/index optimization MUST сохранять source-of-truth semantics и обеспечивать rebuild/stale detection; benchmark PASS MUST NOT достигаться отключением safety checks.

#### Scenario: An index proposal is considered

- **GIVEN** baseline обнаружил повторные scans как bottleneck
- **WHEN** готовится отдельная optimization delta
- **THEN** она SHALL ссылаться на measurement и включать cache-deletion/staleness equivalence tests

#### Scenario: Safety checks are disabled in a fast run

- **GIVEN** измерение выполнено без обязательного post-check/recovery safeguards
- **WHEN** результат сравнивается с baseline
- **THEN** такой run SHALL не засчитываться как сопоставимый acceptance result
