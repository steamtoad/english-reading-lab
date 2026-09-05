## Context

Имена locks сейчас зависят от команды и extraction, хотя writers изменяют общие generations, Chapter cards и global active Vocabulary. Предварительные ordinal, dedup и Reduce plan могут устаревать до lock.

Аудит: `F02`, `A-CONCURRENCY`, `A-GIT-PREFLIGHT`; исходный baseline: `ERL-VOC-006`, `ERL-BOOK-009`, `ERL-SEQ-004`, `ERL-REDUCE-007`, `ERL-GIT-001`. Новые requirement IDs принадлежат только этой delta; другие deltas этого набора не заменяют эти же requirements.

## Goals / Non-Goals

**Goals:** выполнить observable acceptance в `specs/` и убрать перечисленные audit gaps.

**Non-Goals:** переписывать ERL на другой язык, добавлять БД/веб-платформу, менять canonical UUID или ссылки массово, изменять host core, запускать production migrations при подготовке спецификации.

## Decisions

### 1. Решение

На первом этапе использовать один mutation domain lock canonical target home: простота важнее throughput. API внутреннего вызова передаёт context безопасно, без повторного получения собственного lock.

### 2. Решение

Область включает ingest, staging, Reduce, migrations, rename, repair и recover. Setup сериализует пересечение root binding/journals с runtime. Независимые target homes не блокируют друг друга.

### 3. Решение

После acquisition заново разрешать state, dedup, ordinal, receipts, source order, root binding и semantic plan. Существующий Reduce fingerprint/consent не ослабляется.

### 4. Решение

Применить documented Git/worktree policy ко всем mass mutations; non-Git Vault остаётся разрешён, а hashes защищают пользовательские изменения и в нём.

## Dependencies and sequencing

- [fix-work-state-path-safety](../fix-work-state-path-safety/proposal.md)
- [fix-mutation-lock-ownership](../fix-mutation-lock-ownership/proposal.md)

Implementation начинается после обязательных prerequisites; независимые changes допускают отдельную реализацию. Перед apply/archive перечитать current canonical specs, проверить отсутствие concurrent contract drift и обновить delta при необходимости. Возможный перенос общего кода в `.scripts/erl/lib/` выполняется в owner delta соответствующего поведения, с сохранением public CLI и regression parity.

## Risks / Trade-offs

- Общий lock уменьшает parallel throughput; измерение будет отдельной performance delta.
- Блокировка ERL не останавливает Vim и host tools: hash conflict detection остаётся обязательной.

## Migration and rollback

Public CLI, UUID и state meaning не меняются. Lock representation согласовать с prerequisite; pending несовместимой версии journal блокирует overlapping writers.

Новые state/journal representations требуют явной version policy и прочтения supported legacy. Backup, pre/post hashes, dirty-target policy и recovery должны соответствовать applied prerequisite contracts. До migration работающее состояние сохраняется; unspecified legacy не переинтерпретируется. Откат code-only изменения не должен молча читать новый state старой версией.

## Verification

Primary regression: `tests/erl-cross-operation-mutation-serialization.zsh`. Tests используют disposable target и explicit test host; пользовательский Vault не является fixture. Негативные scenarios проверяют exit/envelope и pre/post inventories; structural text tests дополняют behavioral evidence. Для external/live/platform cases сохраняется NOT VERIFIED/SKIP до реального run; это не successful acceptance.

Implementation evidence хранит source/config versions, команды, результаты и применимые limitations. До completion выполнить strict delta validation, applicable complete suite и diff hygiene; перед архивированием выполнить штатные pre/post archive checks. Все tasks в этом planning change остаются открытыми до фактического исполнения.
