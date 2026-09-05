# Сохранение полезного enrichment и происхождения оценок

## Why

Rich staging enrichment включает confidence, provenance, sense_gloss, labels и relations, но durable Vocabulary сохраняет лишь часть полей. Очистка staging может удалить полезные данные и происхождение CEFR оценок.

Источник: [аудит 2026-09-05](../../../audit/2026-09-05/7e56c022-a8fc-11f1-8322-b73dbdeee0d4.adoc), пункты `A-ENRICHMENT`, `A-CONFIDENCE`. Приоритет P2; уровень рекомендаций 3. Текущий normative baseline — `openspec/specs/`; legacy scope для traceability: `ERL-CAND-003`, `ERL-VOC-003`, `ERL-OCC-006`, `ERL-STATE-003`, `ERL-CHECK-017`.

## What Changes

- Useful enrichment survives staging cleanup (ERL-ENRICH-001).
- Occurrence retains its own sense and uncertainty (ERL-ENRICH-002).
- Enrichment backfill is explicit and preserves unknowns (ERL-ENRICH-003).

## Capabilities

### New Capabilities

Нет.

### Modified Capabilities

- `occurrence`: расширить observable guarantees требованиями ERL-ENRICH-002.
- `vault-integration`: расширить observable guarantees требованиями ERL-ENRICH-003.
- `vocabulary`: расширить observable guarantees требованиями ERL-ENRICH-001.

## Impact

- Затрагиваемые компоненты: `.scripts/erl/erl-vocabulary-ingest.zsh`, `.scripts/erl/erl-card-content-repair.zsh`, `.scripts/erl/docs/schemas/`, `openspec/specs/vocabulary-extraction/`, `openspec/specs/vocabulary/`.
- Compatibility/migration: Новые body sections additive, UUID/lexical identity/ownership не меняются. Material semantic policy change применяется через новую generation; backfill существующих cards только explicit preview/apply с preservation ручных заметок.
- Host boundary: изменения только в ERL; production host core и пользовательский Vault не изменяются в рамках implementation этой delta. Contract gaps оформляются отдельно.
- Польза сейчас: Rich staging enrichment включает confidence, provenance, sense_gloss, labels и relations, но durable Vocabulary сохраняет лишь часть полей — устранение описанного разрыва.
- Совместимость с workflow: local files, zsh, AsciiDoc, canonical UUID/links и явные dry-run/apply сохраняются.
- Польза для будущей архитектуры: проверяемый contract для этой области без нового хранилища или platform migration.

## Dependencies

- [fix-runtime-schema-conformance](../fix-runtime-schema-conformance/proposal.md)
- [fix-transaction-recovery-coverage](../fix-transaction-recovery-coverage/proposal.md)
- [fix-asciidoc-projection-safety](../fix-asciidoc-projection-safety/proposal.md)

## Completion

Дельта сейчас является планом. Закрытие требует implementation, primary regression `tests/erl-durable-enrichment-provenance.zsh`, acceptance scenarios `ERL-ENRICH-001`, `ERL-ENRICH-002`, `ERL-ENRICH-003`, полного applicable gate и evidence. Сама validation спецификаций не означает исправление недостатков.
