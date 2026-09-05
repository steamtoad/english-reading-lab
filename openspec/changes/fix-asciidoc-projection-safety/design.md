## Context

Line-based helpers могут неоднозначно обрабатывать links/sections; escape helper заменяет только CR/LF. В отчёте отмечены brackets, backslashes, header parsing, false positives литературного текста и риск перезаписи user-owned содержимого.

Аудит: `A-ASCIIDOC`, `A-CARD-VALIDATION`; исходный baseline: `ERL-DOC-003`, `ERL-DOC-007`, `ERL-DOC-008`, `ERL-CHECK-030`, `ERL-ING-012`. Новые requirement IDs принадлежат только этой delta; другие deltas этого набора не заменяют эти же requirements.

## Goals / Non-Goals

**Goals:** выполнить observable acceptance в `specs/` и убрать перечисленные audit gaps.

**Non-Goals:** переписывать ERL на другой язык, добавлять БД/веб-платформу, менять canonical UUID или ссылки массово, изменять host core, запускать production migrations при подготовке спецификации.

## Decisions

### 1. Решение

Определить host header grammar, включая допустимость пустой строки после title, и читать attributes только из header. Unsupported host layout диагностируется; body :deprecated: не является attribute.

### 2. Решение

Одно правило serialization/parsing link labels: description остаётся человеком читаемой, brackets/backslashes/UTF-8 не создают дополнительные links/attributes/sections. Непредставимый безопасно input отвергается до mutation.

### 3. Решение

ERL управляет явно определёнными link projections. Неизвестный текст в управляемой секции не удаляется replace_section_links молча: сохраняется или вызывает conflict с plan.

### 4. Решение

Card-content checks различают marker-like legitimate prose и реально незаполненный template; syntax validation не заявляет semantic quality. Replacements atomic и hash-aware.

## Dependencies and sequencing

- [fix-work-state-path-safety](../fix-work-state-path-safety/proposal.md)
- [fix-cross-operation-mutation-serialization](../fix-cross-operation-mutation-serialization/proposal.md)
- [fix-transaction-recovery-coverage](../fix-transaction-recovery-coverage/proposal.md)

Implementation начинается после обязательных prerequisites; независимые changes допускают отдельную реализацию. Перед apply/archive перечитать current canonical specs, проверить отсутствие concurrent contract drift и обновить delta при необходимости. Возможный перенос общего кода в `.scripts/erl/lib/` выполняется в owner delta соответствующего поведения, с сохранением public CLI и regression parity.

## Risks / Trade-offs

- Избыточно строгая regex блокирует реальные книги; нужен corpus valid prose рядом с negative templates.
- Усложнять parser сверх host AsciiDoc subset без необходимости не следует.

## Migration and rollback

Canonical filename/UUID/link meaning сохраняется. Форматирование existing cards не меняется bulk cleanup; только explicit scoped repair с pre/post hashes. Добавление :erl-* запрещено.

Новые state/journal representations требуют явной version policy и прочтения supported legacy. Backup, pre/post hashes, dirty-target policy и recovery должны соответствовать applied prerequisite contracts. До migration работающее состояние сохраняется; unspecified legacy не переинтерпретируется. Откат code-only изменения не должен молча читать новый state старой версией.

## Verification

Primary regression: `tests/erl-asciidoc-projection-safety.zsh`. Tests используют disposable target и explicit test host; пользовательский Vault не является fixture. Негативные scenarios проверяют exit/envelope и pre/post inventories; structural text tests дополняют behavioral evidence. Для external/live/platform cases сохраняется NOT VERIFIED/SKIP до реального run; это не successful acceptance.

Implementation evidence хранит source/config versions, команды, результаты и применимые limitations. До completion выполнить strict delta validation, applicable complete suite и diff hygiene; перед архивированием выполнить штатные pre/post archive checks. Все tasks в этом planning change остаются открытыми до фактического исполнения.
