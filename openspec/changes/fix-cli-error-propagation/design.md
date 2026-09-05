## Context

Ошибка resolver внутри command substitution попадает в path; непроверенный jq failure превращается в OK с пустым data. Аналогичные ветви есть в нескольких public commands.

Аудит: `F03`, `F04`, `A-REPORTING`; исходный baseline: `ERL-SHELL-002`, `ERL-SKILL-002`. Новые requirement IDs принадлежат только этой delta; другие deltas этого набора не заменяют эти же requirements.

## Goals / Non-Goals

**Goals:** выполнить observable acceptance в `specs/` и убрать перечисленные audit gaps.

**Non-Goals:** переписывать ERL на другой язык, добавлять БД/веб-платформу, менять canonical UUID или ссылки массово, изменять host core, запускать production migrations при подготовке спецификации.

## Decisions

### 1. Решение

Использовать return/REPLY внутри библиотек и окончательный envelope на command boundary; проверить каждый substitution и pipeline с критическим результатом.

### 2. Решение

Определять --json до argument parsing, чтобы order options не менял формат ошибки. Если jq недоступен, минимальный envelope формируется без него и без отражения необработанного пользовательского текста.

### 3. Решение

Для частично committed batch report обязан раскрывать committed subset; changed отражает фактические persisted domain changes, а не автоматически false для любого error. Успех допускается только с полным schema-valid data.

### 4. Решение

Транзакционный runtime не считает stderr единственным каналом ошибки: class exit 2/10/20/30/40/50/60/70 и semantic code согласуются.

## Dependencies and sequencing

Нет обязательных prerequisites внутри этого набора.

Implementation начинается после обязательных prerequisites; независимые changes допускают отдельную реализацию. Перед apply/archive перечитать current canonical specs, проверить отсутствие concurrent contract drift и обновить delta при необходимости. Возможный перенос общего кода в `.scripts/erl/lib/` выполняется в owner delta соответствующего поведения, с сохранением public CLI и regression parity.

## Risks / Trade-offs

- Механическое включение errexit может изменить управление потоком; требуются explicit checks и негативные тесты.
- Error emitter сам не должен зависеть от сломанного serializer.

## Migration and rollback

JSON envelope schema_version=1 сохраняется; обязательные data не удаляются. Более точная changed semantics для partial failure документируется как bug fix; consumers должны обрабатывать nonzero независимо от changed.

Новые state/journal representations требуют явной version policy и прочтения supported legacy. Backup, pre/post hashes, dirty-target policy и recovery должны соответствовать applied prerequisite contracts. До migration работающее состояние сохраняется; unspecified legacy не переинтерпретируется. Откат code-only изменения не должен молча читать новый state старой версией.

## Verification

Primary regression: `tests/erl-cli-error-propagation.zsh`. Tests используют disposable target и explicit test host; пользовательский Vault не является fixture. Негативные scenarios проверяют exit/envelope и pre/post inventories; structural text tests дополняют behavioral evidence. Для external/live/platform cases сохраняется NOT VERIFIED/SKIP до реального run; это не successful acceptance.

Implementation evidence хранит source/config versions, команды, результаты и применимые limitations. До completion выполнить strict delta validation, applicable complete suite и diff hygiene; перед архивированием выполнить штатные pre/post archive checks. Все tasks в этом planning change остаются открытыми до фактического исполнения.
