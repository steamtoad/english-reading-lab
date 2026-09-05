# Воспроизводимая установка и read-only диагностика

## Why

README не описывает путь от clean checkout до первой книги; setup/check ожидают host, Git и materialized skills. Личные defaults не заменяют переносимый explicit profile. Нужна диагностика готовности, а не автоматическая перенастройка пользовательской машины.

Источник: [аудит 2026-09-05](../../../audit/2026-09-05/7e56c022-a8fc-11f1-8322-b73dbdeee0d4.adoc), пункты `A-INSTALL`, `A-DOCTOR`, `A-ROOT-CONFIG`. Приоритет P2; уровень рекомендаций 3. Текущий normative baseline — `openspec/specs/`; legacy scope для traceability: `ERL-ARCH-009`, `ERL-ARCH-010`, `ERL-AGENT-SETUP-001`, `ERL-AGENT-SETUP-003`, `ERL-AGENT-SETUP-009`.

## What Changes

- Installation is reproducible from declared prerequisites (ERL-BOOT-001).
- Doctor reports readiness without mutation (ERL-BOOT-002).
- Embedded payload is reproducibly built from reviewed sources (ERL-BOOT-003).

## Capabilities

### New Capabilities

Нет.

### Modified Capabilities

- `agent-environment-setup`: расширить observable guarantees требованиями ERL-BOOT-001, ERL-BOOT-002, ERL-BOOT-003.

## Impact

- Затрагиваемые компоненты: `README.MD`, `.scripts/erl/dev/erl-openclaw-agent-setup.zsh`, `.scripts/erl/erl-doctor.zsh`, `.scripts/erl/docs/cli-contract-v1.md`, `docs/`.
- Compatibility/migration: Current working profiles сохраняются без переписывания. Setup создаёт/заменяет managed файлы только через существующие dry-run/apply/replace-managed modes. Global OpenClaw config, credentials и agent registration остаются внешними действиями.
- Host boundary: изменения только в ERL; production host core и пользовательский Vault не изменяются в рамках implementation этой delta. Contract gaps оформляются отдельно.
- Польза сейчас: README не описывает путь от clean checkout до первой книги; setup/check ожидают host, Git и materialized skills — устранение описанного разрыва.
- Совместимость с workflow: local files, zsh, AsciiDoc, canonical UUID/links и явные dry-run/apply сохраняются.
- Польза для будущей архитектуры: проверяемый contract для этой области без нового хранилища или platform migration.

## Dependencies

- [fix-work-state-path-safety](../fix-work-state-path-safety/proposal.md)
- [fix-cli-error-propagation](../fix-cli-error-propagation/proposal.md)
- [fix-runtime-schema-conformance](../fix-runtime-schema-conformance/proposal.md)
- [fix-complete-test-suite-gate](../fix-complete-test-suite-gate/proposal.md)

## Completion

Дельта сейчас является планом. Закрытие требует implementation, primary regression `tests/erl-reproducible-erl-bootstrap.zsh`, acceptance scenarios `ERL-BOOT-001`, `ERL-BOOT-002`, `ERL-BOOT-003`, полного applicable gate и evidence. Сама validation спецификаций не означает исправление недостатков.
