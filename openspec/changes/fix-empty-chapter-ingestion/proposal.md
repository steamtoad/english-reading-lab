# Пустая глава и точный resume batch

## Why

Пустой Candidates array принимается staging и dry-run, но apply не создаёт completed receipt. При partial retry расчёт counts/ordinals должен отражать уже выполненные Candidates, а не представлять их как новые.

Источник: [аудит 2026-09-05](../../../audit/2026-09-05/7e56c022-a8fc-11f1-8322-b73dbdeee0d4.adoc), пункты `F08`, `A-BATCH-RESUME`. Приоритет P2; уровень рекомендаций 1. Текущий normative baseline — `openspec/specs/`; legacy scope для traceability: `ERL-ING-009`, `ERL-SEQ-006`, `ERL-SEQ-012`, `ERL-SEQ-013`, `ERL-CAND-010`.

## What Changes

- Empty extraction completes without synthetic documents (ERL-BATCH-001).
- Empty chapters have explicit handoff semantics (ERL-BATCH-002).
- Retry plans count only remaining work (ERL-BATCH-003).

## Capabilities

### New Capabilities

Нет.

### Modified Capabilities

- `reading-sequence`: расширить observable guarantees требованиями ERL-BATCH-002.
- `vocabulary-ingestion`: расширить observable guarantees требованиями ERL-BATCH-001, ERL-BATCH-003.

## Impact

- Затрагиваемые компоненты: `.scripts/erl/erl-chapter-vocabulary-ingest.zsh`, `.scripts/erl/erl-vocabulary-ingest.zsh`, `.scripts/erl/erl-chapter-chain-handoff.zsh`.
- Compatibility/migration: Receipt schema_version сохраняется, если пустой массив допускается текущей схемой; иначе additive version adapter. Existing completed receipts не переписываются и ordinals не переиндексируются.
- Host boundary: изменения только в ERL; production host core и пользовательский Vault не изменяются в рамках implementation этой delta. Contract gaps оформляются отдельно.
- Польза сейчас: Пустой Candidates array принимается staging и dry-run, но apply не создаёт completed receipt — устранение описанного разрыва.
- Совместимость с workflow: local files, zsh, AsciiDoc, canonical UUID/links и явные dry-run/apply сохраняются.
- Польза для будущей архитектуры: проверяемый contract для этой области без нового хранилища или platform migration.

## Dependencies

- [fix-cross-operation-mutation-serialization](../fix-cross-operation-mutation-serialization/proposal.md)
- [fix-cli-error-propagation](../fix-cli-error-propagation/proposal.md)
- [fix-transaction-recovery-coverage](../fix-transaction-recovery-coverage/proposal.md)

## Completion

Дельта сейчас является планом. Закрытие требует implementation, primary regression `tests/erl-empty-chapter-ingestion.zsh`, acceptance scenarios `ERL-BATCH-001`, `ERL-BATCH-002`, `ERL-BATCH-003`, полного applicable gate и evidence. Сама validation спецификаций не означает исправление недостатков.
