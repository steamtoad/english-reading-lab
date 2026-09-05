# Измерение производительности и границ масштаба

## Why

Повторные scans и jq invocations выполняются в lookup и post-check каждого Candidate. Аудит не измерял реальную сложность/масштаб, поэтому индекс или rewrite пока не обоснованы.

Источник: [аудит 2026-09-05](../../../audit/2026-09-05/7e56c022-a8fc-11f1-8322-b73dbdeee0d4.adoc), пункты `A-PERFORMANCE`, `A-INDEX`, `A-SUPPORTED-SCALE`. Приоритет P2; уровень рекомендаций 3. Текущий normative baseline — `openspec/specs/`; legacy scope для traceability: `ERL-STATE-007`, `ERL-CHECK-017`, `ERL-SHELL-003`.

## What Changes

- Performance results describe reproducible workloads (ERL-PERF-001).
- Optimization preserves correctness and rebuildability (ERL-PERF-002).

## Capabilities

### New Capabilities

- `performance-baseline`: Зафиксировать воспроизводимые workloads, измерения и границы доказанной производительности локального ERL без подмены source of truth производными индексами.

### Modified Capabilities

Нет.

## Impact

- Затрагиваемые компоненты: `.scripts/erl/dev/erl-benchmark.zsh`, `fixtures/benchmark/`, `docs/performance.md`, `.scripts/erl/erl-check.zsh`, `.scripts/erl/erl-vocabulary-ingest.zsh`.
- Compatibility/migration: Benchmark использует disposable data и не меняет production state/schema. Индекс не создаётся этой delta автоматически; follow-up должен показать measured bottleneck и separate migration-free plan.
- Host boundary: изменения только в ERL; production host core и пользовательский Vault не изменяются в рамках implementation этой delta. Contract gaps оформляются отдельно.
- Польза сейчас: Повторные scans и jq invocations выполняются в lookup и post-check каждого Candidate — устранение описанного разрыва.
- Совместимость с workflow: local files, zsh, AsciiDoc, canonical UUID/links и явные dry-run/apply сохраняются.
- Польза для будущей архитектуры: проверяемый contract для этой области без нового хранилища или platform migration.

## Dependencies

- [fix-complete-test-suite-gate](../fix-complete-test-suite-gate/proposal.md)
- [fix-chapter-export-streaming](../fix-chapter-export-streaming/proposal.md)
- [fix-cross-operation-mutation-serialization](../fix-cross-operation-mutation-serialization/proposal.md)

## Completion

Дельта сейчас является планом. Закрытие требует implementation, primary regression `tests/erl-erl-performance-baseline.zsh`, acceptance scenarios `ERL-PERF-001`, `ERL-PERF-002`, полного applicable gate и evidence. Сама validation спецификаций не означает исправление недостатков.
