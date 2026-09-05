# Единый нормативный источник и трассировка аудита

## Why

Текущий AGENTS.md и canonical OS-ARCHIVE-005 уже назначают openspec/specs нормативным baseline, но openspec/config.yaml всё ещё описывает legacy requirements как текущий source и незавершённый переход. Аудит также выявил разрыв между объёмом текстов и проверенными behaviors.

Источник: [аудит 2026-09-05](../../../audit/2026-09-05/7e56c022-a8fc-11f1-8322-b73dbdeee0d4.adoc), пункты `A-GOVERNANCE`, `A-TRACEABILITY`, `A-CONFIG-DRIFT`. Приоритет P2; уровень рекомендаций 3. Текущий normative baseline — `openspec/specs/`; legacy scope для traceability: `OS-ARCHIVE-001`, `OS-ARCHIVE-005`, `ERL-TEST-001`, `ERL-TEST-003`.

## What Changes

- All consumers resolve the same current baseline (ERL-GOVERNANCE-001).
- Requirement completion is backed by behavioral evidence (ERL-GOVERNANCE-002).

## Capabilities

### New Capabilities

Нет.

### Modified Capabilities

- `openspec-governance`: расширить observable guarantees требованиями ERL-GOVERNANCE-001, ERL-GOVERNANCE-002.

## Impact

- Затрагиваемые компоненты: `openspec/config.yaml`, `AGENTS.md`, `.scripts/erl/docs/requirements.md`, `.scripts/erl/docs/cli-contract-v1.md`, `.scripts/erl/dev/`, `docs/`.
- Compatibility/migration: Текущие canonical requirements не меняют смысл. Config/readme/legacy authority wording исправляется при реализации этой delta, старые archives остаются historical records.
- Host boundary: изменения только в ERL; production host core и пользовательский Vault не изменяются в рамках implementation этой delta. Contract gaps оформляются отдельно.
- Польза сейчас: Текущий AGENTS.md и canonical OS-ARCHIVE-005 уже назначают openspec/specs нормативным baseline, но openspec/config.yaml всё ещё описывает legacy requirements как текущий source и незавершённый переход — устранение описанного разрыва.
- Совместимость с workflow: local files, zsh, AsciiDoc, canonical UUID/links и явные dry-run/apply сохраняются.
- Польза для будущей архитектуры: проверяемый contract для этой области без нового хранилища или platform migration.

## Dependencies

- [fix-complete-test-suite-gate](../fix-complete-test-suite-gate/proposal.md)

## Completion

Дельта сейчас является планом. Закрытие требует implementation, primary regression `tests/erl-openspec-contract-authority.zsh`, acceptance scenarios `ERL-GOVERNANCE-001`, `ERL-GOVERNANCE-002`, полного applicable gate и evidence. Сама validation спецификаций не означает исправление недостатков.
