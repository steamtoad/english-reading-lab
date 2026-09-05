## Context

Rich staging enrichment включает confidence, provenance, sense_gloss, labels и relations, но durable Vocabulary сохраняет лишь часть полей. Очистка staging может удалить полезные данные и происхождение CEFR оценок.

Аудит: `A-ENRICHMENT`, `A-CONFIDENCE`; исходный baseline: `ERL-CAND-003`, `ERL-VOC-003`, `ERL-OCC-006`, `ERL-STATE-003`, `ERL-CHECK-017`. Новые requirement IDs принадлежат только этой delta; другие deltas этого набора не заменяют эти же requirements.

## Goals / Non-Goals

**Goals:** выполнить observable acceptance в `specs/` и убрать перечисленные audit gaps.

**Non-Goals:** переписывать ERL на другой язык, добавлять БД/веб-платформу, менять canonical UUID или ссылки массово, изменять host core, запускать production migrations при подготовке спецификации.

## Decisions

### 1. Решение

Разделить ephemeral orchestration metadata и durable learner-useful enrichment. В readable Memo body сохранять sense_gloss, usage/register/rarity/labels, semantic relations/collocations и confidence/provenance рядом с утверждением, которое они описывают.

### 2. Решение

Candidate confidence и CEFR confidence различаются. Данные конкретного sense/context для повторного lexical item сохраняются в Occurrence, а existing canonical Vocabulary не переписывается неявно.

### 3. Решение

Связи, не являющиеся canonical Vault UUID, представлять как текстовые lexical relations; invalid external UUID не превращать в link. No :erl-* metadata.

### 4. Решение

Legacy карточкам нельзя выдумывать отсутствующие provenance: explicit repair показывает known missing и использует доступный утверждённый input без повторной генерации фактов скрытно.

## Dependencies and sequencing

- [fix-runtime-schema-conformance](../fix-runtime-schema-conformance/proposal.md)
- [fix-transaction-recovery-coverage](../fix-transaction-recovery-coverage/proposal.md)
- [fix-asciidoc-projection-safety](../fix-asciidoc-projection-safety/proposal.md)

Implementation начинается после обязательных prerequisites; независимые changes допускают отдельную реализацию. Перед apply/archive перечитать current canonical specs, проверить отсутствие concurrent contract drift и обновить delta при необходимости. Возможный перенос общего кода в `.scripts/erl/lib/` выполняется в owner delta соответствующего поведения, с сохранением public CLI и regression parity.

## Risks / Trade-offs

- Большой enrichment может ухудшить читаемость; sections должны оставаться краткими и human-readable.
- Наличие сохранённой provenance не доказывает истинность model estimate — качество проверяет отдельная eval delta.

## Migration and rollback

Новые body sections additive, UUID/lexical identity/ownership не меняются. Material semantic policy change применяется через новую generation; backfill существующих cards только explicit preview/apply с preservation ручных заметок.

Новые state/journal representations требуют явной version policy и прочтения supported legacy. Backup, pre/post hashes, dirty-target policy и recovery должны соответствовать applied prerequisite contracts. До migration работающее состояние сохраняется; unspecified legacy не переинтерпретируется. Откат code-only изменения не должен молча читать новый state старой версией.

## Verification

Primary regression: `tests/erl-durable-enrichment-provenance.zsh`. Tests используют disposable target и explicit test host; пользовательский Vault не является fixture. Негативные scenarios проверяют exit/envelope и pre/post inventories; structural text tests дополняют behavioral evidence. Для external/live/platform cases сохраняется NOT VERIFIED/SKIP до реального run; это не successful acceptance.

Implementation evidence хранит source/config versions, команды, результаты и применимые limitations. До completion выполнить strict delta validation, applicable complete suite и diff hygiene; перед архивированием выполнить штатные pre/post archive checks. Все tasks в этом planning change остаются открытыми до фактического исполнения.
