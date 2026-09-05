# Сериализация пересекающихся мутаций

## Why

Имена locks сейчас зависят от команды и extraction, хотя writers изменяют общие generations, Chapter cards и global active Vocabulary. Предварительные ordinal, dedup и Reduce plan могут устаревать до lock.

Источник: [аудит 2026-09-05](../../../audit/2026-09-05/7e56c022-a8fc-11f1-8322-b73dbdeee0d4.adoc), пункты `F02`, `A-CONCURRENCY`, `A-GIT-PREFLIGHT`. Приоритет P1; уровень рекомендаций 2. Текущий normative baseline — `openspec/specs/`; legacy scope для traceability: `ERL-VOC-006`, `ERL-BOOK-009`, `ERL-SEQ-004`, `ERL-REDUCE-007`, `ERL-GIT-001`.

## What Changes

- Overlapping ERL writers are serializable (ERL-CONCURRENCY-001).
- Mutation preconditions are revalidated under protection (ERL-CONCURRENCY-002).
- Mass mutation preserves local worktree changes (ERL-CONCURRENCY-003).

## Capabilities

### New Capabilities

Нет.

### Modified Capabilities

- `engineering-safety`: расширить observable guarantees требованиями ERL-CONCURRENCY-001, ERL-CONCURRENCY-002, ERL-CONCURRENCY-003.

## Impact

- Затрагиваемые компоненты: `.scripts/erl/erl-vocabulary-ingest.zsh`, `.scripts/erl/erl-book-reduce.zsh`, `.scripts/erl/erl-work-rename.zsh`, `.scripts/erl/erl-transaction-recover.zsh`, `все migration commands`.
- Compatibility/migration: Public CLI, UUID и state meaning не меняются. Lock representation согласовать с prerequisite; pending несовместимой версии journal блокирует overlapping writers.
- Host boundary: изменения только в ERL; production host core и пользовательский Vault не изменяются в рамках implementation этой delta. Contract gaps оформляются отдельно.
- Польза сейчас: Имена locks сейчас зависят от команды и extraction, хотя writers изменяют общие generations, Chapter cards и global active Vocabulary — устранение описанного разрыва.
- Совместимость с workflow: local files, zsh, AsciiDoc, canonical UUID/links и явные dry-run/apply сохраняются.
- Польза для будущей архитектуры: проверяемый contract для этой области без нового хранилища или platform migration.

## Dependencies

- [fix-work-state-path-safety](../fix-work-state-path-safety/proposal.md)
- [fix-mutation-lock-ownership](../fix-mutation-lock-ownership/proposal.md)

## Completion

Дельта сейчас является планом. Закрытие требует implementation, primary regression `tests/erl-cross-operation-mutation-serialization.zsh`, acceptance scenarios `ERL-CONCURRENCY-001`, `ERL-CONCURRENCY-002`, `ERL-CONCURRENCY-003`, полного applicable gate и evidence. Сама validation спецификаций не означает исправление недостатков.
