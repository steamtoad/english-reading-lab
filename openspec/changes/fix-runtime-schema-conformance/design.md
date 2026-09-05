## Context

Runtime policy validator принимает BOGUS threshold и numeric lexical type с корректным hash. Checker проверяет лишь часть metadata, а positive fixtures могут нарушать опубликованную schema. Идентификатор lexical identity не должен зависеть от случайных пробелов или неоднозначного delimiter.

Аудит: `F06`, `A-VALIDATION`, `A-IDENTITY`; исходный baseline: `ERL-CAND-003`, `ERL-STATE-011`, `ERL-WORKSTATE-009`, `ERL-VOC-004`, `ERL-CHECK-022`. Новые requirement IDs принадлежат только этой delta; другие deltas этого набора не заменяют эти же requirements.

## Goals / Non-Goals

**Goals:** выполнить observable acceptance в `specs/` и убрать перечисленные audit gaps.

**Non-Goals:** переписывать ERL на другой язык, добавлять БД/веб-платформу, менять canonical UUID или ссылки массово, изменять host core, запускать production migrations при подготовке спецификации.

## Decisions

### 1. Решение

Один contract проверяется production boundary и checker. Реализация может остаться jq; независимые table-driven fixtures сверяют все published JSON Schema constraints.

### 2. Решение

Policy hash всегда вычисляется по canonical del(.identity). Candidate validates exact keys/type/enums/ordinals/source identity; state validates version, required values, references, receipts и uniqueness в объявленном scope.

### 3. Решение

Document UUID v1 и ERL-local UUID v4 проверяются отдельно; malformed values из host не переписываются автоматически.

### 4. Решение

Нормализация lexical tuple формализует trim/collapse whitespace/ASCII case и lexical_type; ключ не должен иметь коллизии из-за delimiter. Existing identity keys не массово заменяются: выявленные расхождения требуют explicit migration с collision preview.

## Dependencies and sequencing

- [fix-cli-error-propagation](../fix-cli-error-propagation/proposal.md)

Implementation начинается после обязательных prerequisites; независимые changes допускают отдельную реализацию. Перед apply/archive перечитать current canonical specs, проверить отсутствие concurrent contract drift и обновить delta при необходимости. Возможный перенос общего кода в `.scripts/erl/lib/` выполняется в owner delta соответствующего поведения, с сохранением public CLI и regression parity.

## Risks / Trade-offs

- Строгие validators обнаружат недостоверные positive fixtures и старые данные; отсутствие автоматического исправления является необходимой сохранностью.
- Проверка схемы не устанавливает семантическую истинность английского контекста.

## Migration and rollback

Validation не переписывает state. Для legacy records определить отдельный read-only compatibility diagnostic и explicit migration plan; сохранение старых UUID/ссылок обязательно. Изменение canonical key representation versioned, не часть молчаливого cleanup.

Новые state/journal representations требуют явной version policy и прочтения supported legacy. Backup, pre/post hashes, dirty-target policy и recovery должны соответствовать applied prerequisite contracts. До migration работающее состояние сохраняется; unspecified legacy не переинтерпретируется. Откат code-only изменения не должен молча читать новый state старой версией.

## Verification

Primary regression: `tests/erl-runtime-schema-conformance.zsh`. Tests используют disposable target и explicit test host; пользовательский Vault не является fixture. Негативные scenarios проверяют exit/envelope и pre/post inventories; structural text tests дополняют behavioral evidence. Для external/live/platform cases сохраняется NOT VERIFIED/SKIP до реального run; это не successful acceptance.

Implementation evidence хранит source/config versions, команды, результаты и применимые limitations. До completion выполнить strict delta validation, applicable complete suite и diff hygiene; перед архивированием выполнить штатные pre/post archive checks. Все tasks в этом planning change остаются открытыми до фактического исполнения.
