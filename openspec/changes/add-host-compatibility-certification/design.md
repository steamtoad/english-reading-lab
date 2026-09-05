## Context

Test double не доказывает совместимость с production host ABI. UUID v1, аргументы constructors, stdout и header/layout semantics должны проверяться на реальном поддерживаемом host. Поддержка ОС без evidence не должна заявляться.

Аудит: `A-HOST`, `A-PORTABILITY`, `A-UUID`, `A-LAYOUT`; исходный baseline: `ERL-ARCH-003`, `ERL-ARCH-008`, `ERL-DOC-002`, `ERL-DOC-003`, `ERL-SHELL-003`, `ERL-STATE-014`. Новые requirement IDs принадлежат только этой delta; другие deltas этого набора не заменяют эти же requirements.

## Goals / Non-Goals

**Goals:** выполнить observable acceptance в `specs/` и убрать перечисленные audit gaps.

**Non-Goals:** переписывать ERL на другой язык, добавлять БД/веб-платформу, менять canonical UUID или ссылки массово, изменять host core, запускать production migrations при подготовке спецификации.

## Decisions

### 1. Решение

Опубликовать ERL-consumed host contract: .scripts/objects/{topic,note,memo}-create.zsh, ZK_HOME, argument shape, stdout UUID.adoc, exit behavior, header grammar, metadata, UUID v1, links и no unrelated side effects.

### 2. Решение

Compatibility runner создаёт документы только в explicit disposable target, используя внешний configured host source read-only. Test double остаётся fixture, production fallback запрещён.

### 3. Решение

Матрица фиксирует host revision/version/capabilities и ОС/tool versions. Отсутствующий declared protocol version у старого host не компенсируется выдуманной версией: используется проверенный compatibility profile либо явный gap.

### 4. Решение

Generic CLI roots независимы; Lexi сохраняет canonical local binding из baseline. Unsupported flat Vault только диагностируется до отдельной migration specification.

## Dependencies and sequencing

- [fix-runtime-schema-conformance](../fix-runtime-schema-conformance/proposal.md)
- [fix-source-format-normalization](../fix-source-format-normalization/proposal.md)
- [fix-asciidoc-projection-safety](../fix-asciidoc-projection-safety/proposal.md)
- [add-reproducible-erl-bootstrap](../add-reproducible-erl-bootstrap/proposal.md)

Implementation начинается после обязательных prerequisites; независимые changes допускают отдельную реализацию. Перед apply/archive перечитать current canonical specs, проверить отсутствие concurrent contract drift и обновить delta при необходимости. Возможный перенос общего кода в `.scripts/erl/lib/` выполняется в owner delta соответствующего поведения, с сохранением public CLI и regression parity.

## Risks / Trade-offs

- Реальный host test может требовать локально доступный checkout; отсутствие означает NOT VERIFIED, не PASS.
- Различия GNU/BSD stat/sed/UUID инструментов требуют отдельных test adapters без production fallback.

## Migration and rollback

Host core и пользовательский Vault не изменяются. Если host ABI недостаточен — выпуск ERL для этой конфигурации блокируется с contract gap, исправление host оформляется отдельно.

Новые state/journal representations требуют явной version policy и прочтения supported legacy. Backup, pre/post hashes, dirty-target policy и recovery должны соответствовать applied prerequisite contracts. До migration работающее состояние сохраняется; unspecified legacy не переинтерпретируется. Откат code-only изменения не должен молча читать новый state старой версией.

## Verification

Primary regression: `tests/erl-host-compatibility-certification.zsh`. Tests используют disposable target и explicit test host; пользовательский Vault не является fixture. Негативные scenarios проверяют exit/envelope и pre/post inventories; structural text tests дополняют behavioral evidence. Для external/live/platform cases сохраняется NOT VERIFIED/SKIP до реального run; это не successful acceptance.

Implementation evidence хранит source/config versions, команды, результаты и применимые limitations. До completion выполнить strict delta validation, applicable complete suite и diff hygiene; перед архивированием выполнить штатные pre/post archive checks. Все tasks в этом planning change остаются открытыми до фактического исполнения.
