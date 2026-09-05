# Проверяемая совместимость host и платформ

## Why

Test double не доказывает совместимость с production host ABI. UUID v1, аргументы constructors, stdout и header/layout semantics должны проверяться на реальном поддерживаемом host. Поддержка ОС без evidence не должна заявляться.

Источник: [аудит 2026-09-05](../../../audit/2026-09-05/7e56c022-a8fc-11f1-8322-b73dbdeee0d4.adoc), пункты `A-HOST`, `A-PORTABILITY`, `A-UUID`, `A-LAYOUT`. Приоритет P2; уровень рекомендаций 3. Текущий normative baseline — `openspec/specs/`; legacy scope для traceability: `ERL-ARCH-003`, `ERL-ARCH-008`, `ERL-DOC-002`, `ERL-DOC-003`, `ERL-SHELL-003`, `ERL-STATE-014`.

## What Changes

- Host compatibility is an explicit observable contract (ERL-HOST-001).
- Platform support claims have executable evidence (ERL-HOST-002).

## Capabilities

### New Capabilities

Нет.

### Modified Capabilities

- `architecture-boundary`: расширить observable guarantees требованиями ERL-HOST-001.
- `engineering-safety`: расширить observable guarantees требованиями ERL-HOST-002.

## Impact

- Затрагиваемые компоненты: `fixtures/host-contract/`, `tests/`, `docs/host-contract-v1.md`, `.scripts/erl/erl-doctor.zsh`, `.scripts/erl/lib/common.zsh`.
- Compatibility/migration: Host core и пользовательский Vault не изменяются. Если host ABI недостаточен — выпуск ERL для этой конфигурации блокируется с contract gap, исправление host оформляется отдельно.
- Host boundary: изменения только в ERL; production host core и пользовательский Vault не изменяются в рамках implementation этой delta. Contract gaps оформляются отдельно.
- Польза сейчас: Test double не доказывает совместимость с production host ABI — устранение описанного разрыва.
- Совместимость с workflow: local files, zsh, AsciiDoc, canonical UUID/links и явные dry-run/apply сохраняются.
- Польза для будущей архитектуры: проверяемый contract для этой области без нового хранилища или platform migration.

## Dependencies

- [fix-runtime-schema-conformance](../fix-runtime-schema-conformance/proposal.md)
- [fix-source-format-normalization](../fix-source-format-normalization/proposal.md)
- [fix-asciidoc-projection-safety](../fix-asciidoc-projection-safety/proposal.md)
- [add-reproducible-erl-bootstrap](../add-reproducible-erl-bootstrap/proposal.md)

## Completion

Дельта сейчас является планом. Закрытие требует implementation, primary regression `tests/erl-host-compatibility-certification.zsh`, acceptance scenarios `ERL-HOST-001`, `ERL-HOST-002`, полного applicable gate и evidence. Сама validation спецификаций не означает исправление недостатков.
