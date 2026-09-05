# Правдивые ошибки и JSON envelope

## Why

Ошибка resolver внутри command substitution попадает в path; непроверенный jq failure превращается в OK с пустым data. Аналогичные ветви есть в нескольких public commands.

Источник: [аудит 2026-09-05](../../../audit/2026-09-05/7e56c022-a8fc-11f1-8322-b73dbdeee0d4.adoc), пункты `F03`, `F04`, `A-REPORTING`. Приоритет P1; уровень рекомендаций 1. Текущий normative baseline — `openspec/specs/`; legacy scope для traceability: `ERL-SHELL-002`, `ERL-SKILL-002`.

## What Changes

- Prerequisite failures stop the public command (ERL-CLI-001).
- JSON output is deterministic on every exit path (ERL-CLI-002).
- Partial mutations are reported accurately (ERL-CLI-003).

## Capabilities

### New Capabilities

Нет.

### Modified Capabilities

- `engineering-safety`: расширить observable guarantees требованиями ERL-CLI-001, ERL-CLI-002, ERL-CLI-003.

## Impact

- Затрагиваемые компоненты: `.scripts/erl/lib/common.zsh`, `все public .scripts/erl/*.zsh`, `.scripts/erl/docs/cli-contract-v1.md`.
- Compatibility/migration: JSON envelope schema_version=1 сохраняется; обязательные data не удаляются. Более точная changed semantics для partial failure документируется как bug fix; consumers должны обрабатывать nonzero независимо от changed.
- Host boundary: изменения только в ERL; production host core и пользовательский Vault не изменяются в рамках implementation этой delta. Contract gaps оформляются отдельно.
- Польза сейчас: Ошибка resolver внутри command substitution попадает в path; непроверенный jq failure превращается в OK с пустым data — устранение описанного разрыва.
- Совместимость с workflow: local files, zsh, AsciiDoc, canonical UUID/links и явные dry-run/apply сохраняются.
- Польза для будущей архитектуры: проверяемый contract для этой области без нового хранилища или platform migration.

## Dependencies

Нет обязательных prerequisites внутри этого набора.

## Completion

Дельта сейчас является планом. Закрытие требует implementation, primary regression `tests/erl-cli-error-propagation.zsh`, acceptance scenarios `ERL-CLI-001`, `ERL-CLI-002`, `ERL-CLI-003`, полного applicable gate и evidence. Сама validation спецификаций не означает исправление недостатков.
