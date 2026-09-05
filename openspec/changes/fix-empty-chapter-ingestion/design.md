## Context

Пустой Candidates array принимается staging и dry-run, но apply не создаёт completed receipt. При partial retry расчёт counts/ordinals должен отражать уже выполненные Candidates, а не представлять их как новые.

Аудит: `F08`, `A-BATCH-RESUME`; исходный baseline: `ERL-ING-009`, `ERL-SEQ-006`, `ERL-SEQ-012`, `ERL-SEQ-013`, `ERL-CAND-010`. Новые requirement IDs принадлежат только этой delta; другие deltas этого набора не заменяют эти же requirements.

## Goals / Non-Goals

**Goals:** выполнить observable acceptance в `specs/` и убрать перечисленные audit gaps.

**Non-Goals:** переписывать ERL на другой язык, добавлять БД/веб-платформу, менять canonical UUID или ссылки массово, изменять host core, запускать production migrations при подготовке спецификации.

## Decisions

### 1. Решение

Zero-candidate extraction — успешный содержательный результат: persisted completed receipt с пустым candidates; sequence не увеличивается и artificial Memo не создаётся.

### 2. Решение

Chapter без Memo Chain не имеет исходящего tail handoff. Существующий входящий handoff от непосредственной предыдущей Chapter сохраняется; через пустую Chapter не строится неявный skip-edge.

### 3. Решение

Dry-run/resume план классифицирует completed/new Candidates и точные prospective ordinals; финальный отчёт считает только созданные текущим invocation объекты и отдельно reused/committed receipts.

## Dependencies and sequencing

- [fix-cross-operation-mutation-serialization](../fix-cross-operation-mutation-serialization/proposal.md)
- [fix-cli-error-propagation](../fix-cli-error-propagation/proposal.md)
- [fix-transaction-recovery-coverage](../fix-transaction-recovery-coverage/proposal.md)

Implementation начинается после обязательных prerequisites; независимые changes допускают отдельную реализацию. Перед apply/archive перечитать current canonical specs, проверить отсутствие concurrent contract drift и обновить delta при необходимости. Возможный перенос общего кода в `.scripts/erl/lib/` выполняется в owner delta соответствующего поведения, с сохранением public CLI и regression parity.

## Risks / Trade-offs

- Batch остаётся per-Candidate commit/resume, а не скрытой all-or-rollback транзакцией всей книги.

## Migration and rollback

Receipt schema_version сохраняется, если пустой массив допускается текущей схемой; иначе additive version adapter. Existing completed receipts не переписываются и ordinals не переиндексируются.

Новые state/journal representations требуют явной version policy и прочтения supported legacy. Backup, pre/post hashes, dirty-target policy и recovery должны соответствовать applied prerequisite contracts. До migration работающее состояние сохраняется; unspecified legacy не переинтерпретируется. Откат code-only изменения не должен молча читать новый state старой версией.

## Verification

Primary regression: `tests/erl-empty-chapter-ingestion.zsh`. Tests используют disposable target и explicit test host; пользовательский Vault не является fixture. Негативные scenarios проверяют exit/envelope и pre/post inventories; structural text tests дополняют behavioral evidence. Для external/live/platform cases сохраняется NOT VERIFIED/SKIP до реального run; это не successful acceptance.

Implementation evidence хранит source/config versions, команды, результаты и применимые limitations. До completion выполнить strict delta validation, applicable complete suite и diff hygiene; перед архивированием выполнить штатные pre/post archive checks. Все tasks в этом planning change остаются открытыми до фактического исполнения.
