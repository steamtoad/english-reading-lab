# Единая проверка input и persistent contracts

## Why

Runtime policy validator принимает BOGUS threshold и numeric lexical type с корректным hash. Checker проверяет лишь часть metadata, а positive fixtures могут нарушать опубликованную schema. Идентификатор lexical identity не должен зависеть от случайных пробелов или неоднозначного delimiter.

Источник: [аудит 2026-09-05](../../../audit/2026-09-05/7e56c022-a8fc-11f1-8322-b73dbdeee0d4.adoc), пункты `F06`, `A-VALIDATION`, `A-IDENTITY`. Приоритет P1; уровень рекомендаций 2. Текущий normative baseline — `openspec/specs/`; legacy scope для traceability: `ERL-CAND-003`, `ERL-STATE-011`, `ERL-WORKSTATE-009`, `ERL-VOC-004`, `ERL-CHECK-022`.

## What Changes

- Policy validation conforms to its published schema (ERL-SCHEMA-001).
- Candidate and state validation cover the declared contract (ERL-SCHEMA-002).
- Vault and ERL identifiers retain their distinct versions (ERL-SCHEMA-003).
- Lexical normalization is explicit and collision-safe (ERL-IDENTITY-001).

## Capabilities

### New Capabilities

Нет.

### Modified Capabilities

- `validation`: расширить observable guarantees требованиями ERL-SCHEMA-001, ERL-SCHEMA-002, ERL-SCHEMA-003.
- `vocabulary`: расширить observable guarantees требованиями ERL-IDENTITY-001.

## Impact

- Затрагиваемые компоненты: `.scripts/erl/lib/common.zsh`, `.scripts/erl/erl-check.zsh`, `.scripts/erl/docs/schemas/`, `tests/erl-cli.zsh`.
- Compatibility/migration: Validation не переписывает state. Для legacy records определить отдельный read-only compatibility diagnostic и explicit migration plan; сохранение старых UUID/ссылок обязательно. Изменение canonical key representation versioned, не часть молчаливого cleanup.
- Host boundary: изменения только в ERL; production host core и пользовательский Vault не изменяются в рамках implementation этой delta. Contract gaps оформляются отдельно.
- Польза сейчас: Runtime policy validator принимает BOGUS threshold и numeric lexical type с корректным hash — устранение описанного разрыва.
- Совместимость с workflow: local files, zsh, AsciiDoc, canonical UUID/links и явные dry-run/apply сохраняются.
- Польза для будущей архитектуры: проверяемый contract для этой области без нового хранилища или platform migration.

## Dependencies

- [fix-cli-error-propagation](../fix-cli-error-propagation/proposal.md)

## Completion

Дельта сейчас является планом. Закрытие требует implementation, primary regression `tests/erl-runtime-schema-conformance.zsh`, acceptance scenarios `ERL-SCHEMA-001`, `ERL-SCHEMA-002`, `ERL-SCHEMA-003`, `ERL-IDENTITY-001`, полного applicable gate и evidence. Сама validation спецификаций не означает исправление недостатков.
