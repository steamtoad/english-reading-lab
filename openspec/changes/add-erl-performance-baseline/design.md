## Context

Повторные scans и jq invocations выполняются в lookup и post-check каждого Candidate. Аудит не измерял реальную сложность/масштаб, поэтому индекс или rewrite пока не обоснованы.

Аудит: `A-PERFORMANCE`, `A-INDEX`, `A-SUPPORTED-SCALE`; исходный baseline: `ERL-STATE-007`, `ERL-CHECK-017`, `ERL-SHELL-003`. Новые requirement IDs принадлежат только этой delta; другие deltas этого набора не заменяют эти же requirements.

## Goals / Non-Goals

**Goals:** выполнить observable acceptance в `specs/` и убрать перечисленные audit gaps.

**Non-Goals:** переписывать ERL на другой язык, добавлять БД/веб-платформу, менять canonical UUID или ссылки массово, изменять host core, запускать production migrations при подготовке спецификации.

## Decisions

### 1. Решение

Создать reproducible synthetic workload generator с фиксированным seed и corpus sizes; отдельно измерять initial ingest, existing Vocabulary encounter, scoped/global check, Reduce closure и backup/export.

### 2. Решение

Report фиксирует machine/OS/tool versions, notes/works/Candidates counts, repetitions, median/p95 wall time, peak RSS где доступно и failure rate. Начальные suggested scales определяются harness config, не трактуются как доказанная поддержка до run.

### 3. Решение

Performance acceptance budget публикуется до regression comparison; без baseline нельзя считать отсутствие regression доказанным.

### 4. Решение

Оптимизация сначала уменьшает repeated reads/processes с сохранением correctness. Индекс вводится только если измерения показывают необходимость; cache rebuild и stale-index fallback обязательны. Добавление БД/нового языка не входит в эту delta.

## Dependencies and sequencing

- [fix-complete-test-suite-gate](../fix-complete-test-suite-gate/proposal.md)
- [fix-chapter-export-streaming](../fix-chapter-export-streaming/proposal.md)
- [fix-cross-operation-mutation-serialization](../fix-cross-operation-mutation-serialization/proposal.md)

Implementation начинается после обязательных prerequisites; независимые changes допускают отдельную реализацию. Перед apply/archive перечитать current canonical specs, проверить отсутствие concurrent contract drift и обновить delta при необходимости. Возможный перенос общего кода в `.scripts/erl/lib/` выполняется в owner delta соответствующего поведения, с сохранением public CLI и regression parity.

## Risks / Trade-offs

- Environment noise и общий mutation lock влияют на измерение; использовать одинаковые workloads и повторения.
- Ускорение за счёт выключения validation/recovery не допускается.

## Migration and rollback

Benchmark использует disposable data и не меняет production state/schema. Индекс не создаётся этой delta автоматически; follow-up должен показать measured bottleneck и separate migration-free plan.

Новые state/journal representations требуют явной version policy и прочтения supported legacy. Backup, pre/post hashes, dirty-target policy и recovery должны соответствовать applied prerequisite contracts. До migration работающее состояние сохраняется; unspecified legacy не переинтерпретируется. Откат code-only изменения не должен молча читать новый state старой версией.

## Verification

Primary regression: `tests/erl-erl-performance-baseline.zsh`. Tests используют disposable target и explicit test host; пользовательский Vault не является fixture. Негативные scenarios проверяют exit/envelope и pre/post inventories; structural text tests дополняют behavioral evidence. Для external/live/platform cases сохраняется NOT VERIFIED/SKIP до реального run; это не successful acceptance.

Implementation evidence хранит source/config versions, команды, результаты и применимые limitations. До completion выполнить strict delta validation, applicable complete suite и diff hygiene; перед архивированием выполнить штатные pre/post archive checks. Все tasks в этом planning change остаются открытыми до фактического исполнения.
