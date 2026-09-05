# Полный и воспроизводимый тестовый запуск

## Why

Runner пропускает падающий chapter-memo-chain test и два других behavioral entry point, при этом часть suites дублируется. Четыре tests зависят от различия /var и /private/var, а archive/skills prerequisites не документированы.

Источник: [аудит 2026-09-05](../../../audit/2026-09-05/7e56c022-a8fc-11f1-8322-b73dbdeee0d4.adoc), пункты `F10`, `A-TEST-GATE`. Приоритет P2; уровень рекомендаций 1. Текущий normative baseline — `openspec/specs/`; legacy scope для traceability: `ERL-TEST-001`, `ERL-TEST-002`, `ERL-TEST-003`.

## What Changes

- The mandatory suite covers every declared behavioral test (ERL-TEST-004).
- Test fixtures are canonical and environment-independent (ERL-TEST-005).
- Suite prerequisites and negative guarantees are explicit (ERL-TEST-006).

## Capabilities

### New Capabilities

Нет.

### Modified Capabilities

- `engineering-safety`: расширить observable guarantees требованиями ERL-TEST-004, ERL-TEST-005, ERL-TEST-006.

## Impact

- Затрагиваемые компоненты: `tests/erl-all.zsh`, `tests/erl-chapter-memo-chain.zsh`, `tests/erl-*-setup.zsh`, `.scripts/erl/dev/erl-delta-test-naming-check.zsh`, `README.MD`.
- Compatibility/migration: Runtime state и canonical specs meaning не меняются. Старые архивы сохраняются как history; не переписывать completed tasks, чтобы скрыть test debt.
- Host boundary: изменения только в ERL; production host core и пользовательский Vault не изменяются в рамках implementation этой delta. Contract gaps оформляются отдельно.
- Польза сейчас: Runner пропускает падающий chapter-memo-chain test и два других behavioral entry point, при этом часть suites дублируется — устранение описанного разрыва.
- Совместимость с workflow: local files, zsh, AsciiDoc, canonical UUID/links и явные dry-run/apply сохраняются.
- Польза для будущей архитектуры: проверяемый contract для этой области без нового хранилища или platform migration.

## Dependencies

Нет обязательных prerequisites внутри этого набора.

## Completion

Дельта сейчас является планом. Закрытие требует implementation, primary regression `tests/erl-complete-test-suite-gate.zsh`, acceptance scenarios `ERL-TEST-004`, `ERL-TEST-005`, `ERL-TEST-006`, полного applicable gate и evidence. Сама validation спецификаций не означает исправление недостатков.
