# Безопасные AsciiDoc sections и сохранение ручных правок

## Why

Line-based helpers могут неоднозначно обрабатывать links/sections; escape helper заменяет только CR/LF. В отчёте отмечены brackets, backslashes, header parsing, false positives литературного текста и риск перезаписи user-owned содержимого.

Источник: [аудит 2026-09-05](../../../audit/2026-09-05/7e56c022-a8fc-11f1-8322-b73dbdeee0d4.adoc), пункты `A-ASCIIDOC`, `A-CARD-VALIDATION`. Приоритет P2; уровень рекомендаций 2. Текущий normative baseline — `openspec/specs/`; legacy scope для traceability: `ERL-DOC-003`, `ERL-DOC-007`, `ERL-DOC-008`, `ERL-CHECK-030`, `ERL-ING-012`.

## What Changes

- User text is safely serialized into canonical cards (ERL-ASCIIDOC-001).
- Projection edits preserve user-owned content (ERL-ASCIIDOC-002).
- Header and content validation honor the supported host grammar (ERL-ASCIIDOC-003).

## Capabilities

### New Capabilities

Нет.

### Modified Capabilities

- `validation`: расширить observable guarantees требованиями ERL-ASCIIDOC-003.
- `vault-integration`: расширить observable guarantees требованиями ERL-ASCIIDOC-001, ERL-ASCIIDOC-002.

## Impact

- Затрагиваемые компоненты: `.scripts/erl/lib/chapter-memo-chain.zsh`, `.scripts/erl/lib/card-content.zsh`, `.scripts/erl/lib/common.zsh`, `.scripts/erl/erl-card-content-repair.zsh`, `.scripts/erl/erl-check.zsh`.
- Compatibility/migration: Canonical filename/UUID/link meaning сохраняется. Форматирование existing cards не меняется bulk cleanup; только explicit scoped repair с pre/post hashes. Добавление :erl-* запрещено.
- Host boundary: изменения только в ERL; production host core и пользовательский Vault не изменяются в рамках implementation этой delta. Contract gaps оформляются отдельно.
- Польза сейчас: Line-based helpers могут неоднозначно обрабатывать links/sections; escape helper заменяет только CR/LF — устранение описанного разрыва.
- Совместимость с workflow: local files, zsh, AsciiDoc, canonical UUID/links и явные dry-run/apply сохраняются.
- Польза для будущей архитектуры: проверяемый contract для этой области без нового хранилища или platform migration.

## Dependencies

- [fix-work-state-path-safety](../fix-work-state-path-safety/proposal.md)
- [fix-cross-operation-mutation-serialization](../fix-cross-operation-mutation-serialization/proposal.md)
- [fix-transaction-recovery-coverage](../fix-transaction-recovery-coverage/proposal.md)

## Completion

Дельта сейчас является планом. Закрытие требует implementation, primary regression `tests/erl-asciidoc-projection-safety.zsh`, acceptance scenarios `ERL-ASCIIDOC-001`, `ERL-ASCIIDOC-002`, `ERL-ASCIIDOC-003`, полного applicable gate и evidence. Сама validation спецификаций не означает исправление недостатков.
