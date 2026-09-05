## Context

При отказе acquisition EXIT cleanup снимает существующий чужой lock. Это воспроизведённый дефект независимо от планируемого изменения общей области сериализации.

Аудит: `F02`, `A-LOCK-OWNERSHIP`; исходный baseline: `ERL-STATE-017`, `ERL-GIT-002`. Новые requirement IDs принадлежат только этой delta; другие deltas этого набора не заменяют эти же requirements.

## Goals / Non-Goals

**Goals:** выполнить observable acceptance в `specs/` и убрать перечисленные audit gaps.

**Non-Goals:** переписывать ERL на другой язык, добавлять БД/веб-платформу, менять canonical UUID или ссылки массово, изменять host core, запускать production migrations при подготовке спецификации.

## Decisions

### 1. Решение

Успешный acquire выдаёт operation-specific owner token; release требует совпадение токена и факт acquisition.

### 2. Решение

Повторный cleanup идемпотентен. PID без token не считается достаточным доказательством ownership.

### 3. Решение

Нельзя автоматически считать legacy/unknown lock stale или удалять его по таймауту. Диагностика объясняет безопасное действие оператора.

## Dependencies and sequencing

- [fix-work-state-path-safety](../fix-work-state-path-safety/proposal.md)

Implementation начинается после обязательных prerequisites; независимые changes допускают отдельную реализацию. Перед apply/archive перечитать current canonical specs, проверить отсутствие concurrent contract drift и обновить delta при необходимости. Возможный перенос общего кода в `.scripts/erl/lib/` выполняется в owner delta соответствующего поведения, с сохранением public CLI и regression parity.

## Risks / Trade-offs

- Пустой lock может существовать между mkdir и записью token; конкурент не должен трактовать его как свободный.

## Migration and rollback

Переход к token-bearing locks additive. Existing ownerless locks блокируют writers до explicit процедуры; автоматически очищать их при запуске нельзя.

Новые state/journal representations требуют явной version policy и прочтения supported legacy. Backup, pre/post hashes, dirty-target policy и recovery должны соответствовать applied prerequisite contracts. До migration работающее состояние сохраняется; unspecified legacy не переинтерпретируется. Откат code-only изменения не должен молча читать новый state старой версией.

## Verification

Primary regression: `tests/erl-mutation-lock-ownership.zsh`. Tests используют disposable target и explicit test host; пользовательский Vault не является fixture. Негативные scenarios проверяют exit/envelope и pre/post inventories; structural text tests дополняют behavioral evidence. Для external/live/platform cases сохраняется NOT VERIFIED/SKIP до реального run; это не successful acceptance.

Implementation evidence хранит source/config versions, команды, результаты и применимые limitations. До completion выполнить strict delta validation, applicable complete suite и diff hygiene; перед архивированием выполнить штатные pre/post archive checks. Все tasks в этом planning change остаются открытыми до фактического исполнения.
