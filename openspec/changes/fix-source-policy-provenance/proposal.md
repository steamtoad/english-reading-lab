# Проверяемая identity источника и policy

## Why

Export выдаёт новые bytes заменённого source с прежним SOURCE_ID, принимает stale policy hash и не возвращает source_fingerprint, который обязателен для staging. Локальный source_path также должен переноситься без подмены edition.

Источник: [аудит 2026-09-05](../../../audit/2026-09-05/7e56c022-a8fc-11f1-8322-b73dbdeee0d4.adoc), пункты `F05`, `A-SOURCE-RELOCATION`. Приоритет P1; уровень рекомендаций 1. Текущий normative baseline — `openspec/specs/`; legacy scope для traceability: `ERL-CHAPTER-005`, `ERL-CHAPTER-006`, `ERL-CHAPTER-010`, `ERL-EXT-004`, `ERL-CAND-002`.

## What Changes

- Export binds exact source content and policy (ERL-PROVENANCE-001).
- Export supplies the complete staging source identity (ERL-PROVENANCE-002).
- Relocation preserves edition identity only for identical bytes (ERL-PROVENANCE-003).

## Capabilities

### New Capabilities

Нет.

### Modified Capabilities

- `source-chapters`: расширить observable guarantees требованиями ERL-PROVENANCE-001, ERL-PROVENANCE-003.
- `vocabulary-extraction`: расширить observable guarantees требованиями ERL-PROVENANCE-002.

## Impact

- Затрагиваемые компоненты: `.scripts/erl/erl-chapter-export.zsh`, `.scripts/erl/erl-extraction-stage.zsh`, `.scripts/erl/lib/source.zsh`, `skills/erl-chapter-vocabulary-extract/`, `.scripts/erl/docs/cli-contract-v1.md`.
- Compatibility/migration: Дополнительное response поле backward-compatible. Rebind сохраняет WORK_ID/SOURCE_ID/Chapter UUID. Отсутствующий старый source допустим для rebind только если новый файл совпал с retained fingerprint; legacy записи без достаточной identity получают migration diagnostic.
- Host boundary: изменения только в ERL; production host core и пользовательский Vault не изменяются в рамках implementation этой delta. Contract gaps оформляются отдельно.
- Польза сейчас: Export выдаёт новые bytes заменённого source с прежним SOURCE_ID, принимает stale policy hash и не возвращает source_fingerprint, который обязателен для staging — устранение описанного разрыва.
- Совместимость с workflow: local files, zsh, AsciiDoc, canonical UUID/links и явные dry-run/apply сохраняются.
- Польза для будущей архитектуры: проверяемый contract для этой области без нового хранилища или platform migration.

## Dependencies

- [fix-cli-error-propagation](../fix-cli-error-propagation/proposal.md)
- [fix-chapter-export-streaming](../fix-chapter-export-streaming/proposal.md)
- [fix-runtime-schema-conformance](../fix-runtime-schema-conformance/proposal.md)
- [fix-cross-operation-mutation-serialization](../fix-cross-operation-mutation-serialization/proposal.md)
- [fix-transaction-recovery-coverage](../fix-transaction-recovery-coverage/proposal.md)

## Completion

Дельта сейчас является планом. Закрытие требует implementation, primary regression `tests/erl-source-policy-provenance.zsh`, acceptance scenarios `ERL-PROVENANCE-001`, `ERL-PROVENANCE-002`, `ERL-PROVENANCE-003`, полного applicable gate и evidence. Сама validation спецификаций не означает исправление недостатков.
