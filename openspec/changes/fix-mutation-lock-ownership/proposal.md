# Владение блокировками и безопасное освобождение

## Why

При отказе acquisition EXIT cleanup снимает существующий чужой lock. Это воспроизведённый дефект независимо от планируемого изменения общей области сериализации.

Источник: [аудит 2026-09-05](../../../audit/2026-09-05/7e56c022-a8fc-11f1-8322-b73dbdeee0d4.adoc), пункты `F02`, `A-LOCK-OWNERSHIP`. Приоритет P1; уровень рекомендаций 1. Текущий normative baseline — `openspec/specs/`; legacy scope для traceability: `ERL-STATE-017`, `ERL-GIT-002`.

## What Changes

- Only an acquired owner may release a lock (ERL-LOCK-001).
- Unknown and stale locks require explicit handling (ERL-LOCK-002).

## Capabilities

### New Capabilities

Нет.

### Modified Capabilities

- `engineering-safety`: расширить observable guarantees требованиями ERL-LOCK-001, ERL-LOCK-002.

## Impact

- Затрагиваемые компоненты: `.scripts/erl/lib/common.zsh`, `.scripts/erl/erl-extraction-stage.zsh`, `все cleanup/trap блокировки в .scripts/erl/`.
- Compatibility/migration: Переход к token-bearing locks additive. Existing ownerless locks блокируют writers до explicit процедуры; автоматически очищать их при запуске нельзя.
- Host boundary: изменения только в ERL; production host core и пользовательский Vault не изменяются в рамках implementation этой delta. Contract gaps оформляются отдельно.
- Польза сейчас: При отказе acquisition EXIT cleanup снимает существующий чужой lock — устранение описанного разрыва.
- Совместимость с workflow: local files, zsh, AsciiDoc, canonical UUID/links и явные dry-run/apply сохраняются.
- Польза для будущей архитектуры: проверяемый contract для этой области без нового хранилища или platform migration.

## Dependencies

- [fix-work-state-path-safety](../fix-work-state-path-safety/proposal.md)

## Completion

Дельта сейчас является планом. Закрытие требует implementation, primary regression `tests/erl-mutation-lock-ownership.zsh`, acceptance scenarios `ERL-LOCK-001`, `ERL-LOCK-002`, полного applicable gate и evidence. Сама validation спецификаций не означает исправление недостатков.
