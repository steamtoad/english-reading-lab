# Полное восстановление и crash-consistency

## Why

Recovery не поддерживает Book Reduce, work rename, state migrate и Classic reconcile. Часть handlers не проверяет current post-hash или фазу каждого заменённого файла; journal обновляется после write, оставляя crash windows.

Источник: [аудит 2026-09-05](../../../audit/2026-09-05/7e56c022-a8fc-11f1-8322-b73dbdeee0d4.adoc), пункты `F07`, `A-RECOVERY`, `A-JOURNAL-PATHS`, `A-MIGRATION`. Приоритет P1; уровень рекомендаций 2. Текущий normative baseline — `openspec/specs/`; legacy scope для traceability: `ERL-STATE-008`, `ERL-STATE-017`, `ERL-REDUCE-018`, `ERL-REDUCE-019`, `ERL-REDUCE-023`, `ERL-ING-008`.

## What Changes

- Every emitted operation journal has a recovery route (ERL-RECOVERY-001).
- Write intent precedes recoverable mutation (ERL-RECOVERY-002).
- Recovery preserves external edits and is repeatable (ERL-RECOVERY-003).
- Rename and layout migrations preserve recovery reachability (ERL-RECOVERY-004).

## Capabilities

### New Capabilities

Нет.

### Modified Capabilities

- `persistent-state`: расширить observable guarantees требованиями ERL-RECOVERY-001, ERL-RECOVERY-002, ERL-RECOVERY-003, ERL-RECOVERY-004.

## Impact

- Затрагиваемые компоненты: `.scripts/erl/erl-transaction-recover.zsh`, `все writers .scripts/erl/`, `.scripts/erl/lib/common.zsh`.
- Compatibility/migration: Legacy journals сохраняются и читаются с version adapters там, где есть достаточные backups/hashes. Неполный старый journal даёт blocked manual recovery plan с inventory; unsupported legacy не может быть помечен recovered. Каждый новый writer обязан зарегистрировать recovery до выпуска.
- Host boundary: изменения только в ERL; production host core и пользовательский Vault не изменяются в рамках implementation этой delta. Contract gaps оформляются отдельно.
- Польза сейчас: Recovery не поддерживает Book Reduce, work rename, state migrate и Classic reconcile — устранение описанного разрыва.
- Совместимость с workflow: local files, zsh, AsciiDoc, canonical UUID/links и явные dry-run/apply сохраняются.
- Польза для будущей архитектуры: проверяемый contract для этой области без нового хранилища или platform migration.

## Dependencies

- [fix-work-state-path-safety](../fix-work-state-path-safety/proposal.md)
- [fix-cross-operation-mutation-serialization](../fix-cross-operation-mutation-serialization/proposal.md)
- [fix-cli-error-propagation](../fix-cli-error-propagation/proposal.md)
- [fix-runtime-schema-conformance](../fix-runtime-schema-conformance/proposal.md)

## Completion

Дельта сейчас является планом. Закрытие требует implementation, primary regression `tests/erl-transaction-recovery-coverage.zsh`, acceptance scenarios `ERL-RECOVERY-001`, `ERL-RECOVERY-002`, `ERL-RECOVERY-003`, `ERL-RECOVERY-004`, полного applicable gate и evidence. Сама validation спецификаций не означает исправление недостатков.
