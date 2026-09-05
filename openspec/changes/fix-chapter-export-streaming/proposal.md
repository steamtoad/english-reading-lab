# Полный экспорт длинной главы

## Why

Аудит импортировал TXT 2 210 000 bytes, но export превысил argv limit jq и вернул OK без данных. Глава не должна ограничиваться размером аргументов процесса.

Источник: [аудит 2026-09-05](../../../audit/2026-09-05/7e56c022-a8fc-11f1-8322-b73dbdeee0d4.adoc), пункты `F04`, `A-LARGE-CHAPTER`. Приоритет P1; уровень рекомендаций 1. Текущий normative baseline — `openspec/specs/`; legacy scope для traceability: `ERL-PROC-007`, `ERL-PROC-008`, `ERL-CAND-010`.

## What Changes

- Chapter export is independent of process argument limits (ERL-EXPORT-001).
- Export failures and temporary artifacts are bounded (ERL-EXPORT-002).

## Capabilities

### New Capabilities

Нет.

### Modified Capabilities

- `source-chapters`: расширить observable guarantees требованиями ERL-EXPORT-001.
- `source-content-safety`: расширить observable guarantees требованиями ERL-EXPORT-002.

## Impact

- Затрагиваемые компоненты: `.scripts/erl/erl-chapter-export.zsh`, `.scripts/erl/lib/source.zsh`, `.scripts/erl/docs/cli-contract-v1.md`.
- Compatibility/migration: Поле content и envelope сохраняются; менять UUID и persistent source records не требуется.
- Host boundary: изменения только в ERL; production host core и пользовательский Vault не изменяются в рамках implementation этой delta. Contract gaps оформляются отдельно.
- Польза сейчас: Аудит импортировал TXT 2 210 000 bytes, но export превысил argv limit jq и вернул OK без данных — устранение описанного разрыва.
- Совместимость с workflow: local files, zsh, AsciiDoc, canonical UUID/links и явные dry-run/apply сохраняются.
- Польза для будущей архитектуры: проверяемый contract для этой области без нового хранилища или platform migration.

## Dependencies

- [fix-cli-error-propagation](../fix-cli-error-propagation/proposal.md)

## Completion

Дельта сейчас является планом. Закрытие требует implementation, primary regression `tests/erl-chapter-export-streaming.zsh`, acceptance scenarios `ERL-EXPORT-001`, `ERL-EXPORT-002`, полного applicable gate и evidence. Сама validation спецификаций не означает исправление недостатков.
