## Context

Аудит импортировал TXT 2 210 000 bytes, но export превысил argv limit jq и вернул OK без данных. Глава не должна ограничиваться размером аргументов процесса.

Аудит: `F04`, `A-LARGE-CHAPTER`; исходный baseline: `ERL-PROC-007`, `ERL-PROC-008`, `ERL-CAND-010`. Новые requirement IDs принадлежат только этой delta; другие deltas этого набора не заменяют эти же requirements.

## Goals / Non-Goals

**Goals:** выполнить observable acceptance в `specs/` и убрать перечисленные audit gaps.

**Non-Goals:** переписывать ERL на другой язык, добавлять БД/веб-платформу, менять canonical UUID или ссылки массово, изменять host core, запускать production migrations при подготовке спецификации.

## Decisions

### 1. Решение

Передавать content как file/stream (--rawfile или equivalent), не --arg. Контракт — полный UTF-8 content, включая точное поведение trailing LF, без silent trim.

### 2. Решение

Отделить filesystem export от model context budget. Export либо возвращает всю главу, либо явную ограничительную diagnostic до model operation; segmentation относится к semantic-evaluation delta.

### 3. Решение

Temporary export files живут вне persistent works, удаляются в cleanup и не публикуются. Лимит если нужен задаётся документированно и никогда не приводит к fake success.

## Dependencies and sequencing

- [fix-cli-error-propagation](../fix-cli-error-propagation/proposal.md)

Implementation начинается после обязательных prerequisites; независимые changes допускают отдельную реализацию. Перед apply/archive перечитать current canonical specs, проверить отсутствие concurrent contract drift и обновить delta при необходимости. Возможный перенос общего кода в `.scripts/erl/lib/` выполняется в owner delta соответствующего поведения, с сохранением public CLI и regression parity.

## Risks / Trade-offs

- Переход к streaming снимает ARG_MAX, но не делает model context неограниченным.
- Нужны failure tests временного файла и записи stdout.

## Migration and rollback

Поле content и envelope сохраняются; менять UUID и persistent source records не требуется.

Новые state/journal representations требуют явной version policy и прочтения supported legacy. Backup, pre/post hashes, dirty-target policy и recovery должны соответствовать applied prerequisite contracts. До migration работающее состояние сохраняется; unspecified legacy не переинтерпретируется. Откат code-only изменения не должен молча читать новый state старой версией.

## Verification

Primary regression: `tests/erl-chapter-export-streaming.zsh`. Tests используют disposable target и explicit test host; пользовательский Vault не является fixture. Негативные scenarios проверяют exit/envelope и pre/post inventories; structural text tests дополняют behavioral evidence. Для external/live/platform cases сохраняется NOT VERIFIED/SKIP до реального run; это не successful acceptance.

Implementation evidence хранит source/config versions, команды, результаты и применимые limitations. До completion выполнить strict delta validation, applicable complete suite и diff hygiene; перед архивированием выполнить штатные pre/post archive checks. Все tasks в этом planning change остаются открытыми до фактического исполнения.
