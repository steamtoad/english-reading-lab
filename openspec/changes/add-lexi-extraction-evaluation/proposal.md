# Измеримое качество извлечения и полный агентный сценарий

## Why

Routing smoke test проверяет выбор имени skill, а не полноту/точность лексики, CEFR, first occurrence или безопасное исполнение. Наличие Vocabulary означает существующую карточку, а не доказанное знание слова пользователем. Для длинных глав нужна проверяемая segmentation без квоты Candidates.

Источник: [аудит 2026-09-05](../../../audit/2026-09-05/7e56c022-a8fc-11f1-8322-b73dbdeee0d4.adoc), пункты `A-SEMANTIC-EVAL`, `A-KNOWN-WORDS`, `A-SEGMENTATION`, `A-MODEL-DATA-BOUNDARY`. Приоритет P2; уровень рекомендаций 3. Текущий normative baseline — `openspec/specs/`; legacy scope для traceability: `ERL-CAND-003`, `ERL-CAND-004`, `ERL-CAND-010`, `ERL-PROC-008`, `ERL-SOURCE-004`, `ERL-AGENT-SETUP-010`, `ERL-AGENT-SETUP-011`.

## What Changes

- Extraction quality has a versioned measurable baseline (ERL-EVAL-001).
- Segmented extraction preserves whole-chapter semantics (ERL-EVAL-002).
- Agent safety and end-to-end behavior are executed (ERL-EVAL-003).
- Vocabulary reuse is not presented as demonstrated learning (ERL-EVAL-004).
- Evaluation artifacts respect source and logging boundaries (ERL-EVAL-005).

## Capabilities

### New Capabilities

- `quality-evaluation`: Определить воспроизводимую оценку семантического качества и безопасного end-to-end поведения Lexi, отдельно от deterministic CLI и routing smoke tests.

### Modified Capabilities

- `incremental-processing`: расширить observable guarantees требованиями ERL-EVAL-002.
- `source-content-safety`: расширить observable guarantees требованиями ERL-EVAL-005.
- `vocabulary`: расширить observable guarantees требованиями ERL-EVAL-004.

## Impact

- Затрагиваемые компоненты: `skills/erl-chapter-vocabulary-extract/`, `tests/`, `fixtures/evaluation/`, `docs/`, `README.MD`, `.scripts/erl/dev/`.
- Compatibility/migration: Semantic output contract не переписывает старые generations. Material policy/segmentation changes требуют новой semantic generation по существующему baseline. Live harness явно opt-in и использует отдельно настроенные operator credentials без включения их в repo.
- Host boundary: изменения только в ERL; production host core и пользовательский Vault не изменяются в рамках implementation этой delta. Contract gaps оформляются отдельно.
- Польза сейчас: Routing smoke test проверяет выбор имени skill, а не полноту/точность лексики, CEFR, first occurrence или безопасное исполнение — устранение описанного разрыва.
- Совместимость с workflow: local files, zsh, AsciiDoc, canonical UUID/links и явные dry-run/apply сохраняются.
- Польза для будущей архитектуры: проверяемый contract для этой области без нового хранилища или platform migration.

## Dependencies

- [fix-chapter-export-streaming](../fix-chapter-export-streaming/proposal.md)
- [fix-source-policy-provenance](../fix-source-policy-provenance/proposal.md)
- [fix-runtime-schema-conformance](../fix-runtime-schema-conformance/proposal.md)
- [fix-empty-chapter-ingestion](../fix-empty-chapter-ingestion/proposal.md)
- [fix-source-format-normalization](../fix-source-format-normalization/proposal.md)
- [add-durable-enrichment-provenance](../add-durable-enrichment-provenance/proposal.md)

## Completion

Дельта сейчас является планом. Закрытие требует implementation, primary regression `tests/erl-lexi-extraction-evaluation.zsh`, acceptance scenarios `ERL-EVAL-001`, `ERL-EVAL-002`, `ERL-EVAL-003`, `ERL-EVAL-004`, `ERL-EVAL-005`, полного applicable gate и evidence. Сама validation спецификаций не означает исправление недостатков.
