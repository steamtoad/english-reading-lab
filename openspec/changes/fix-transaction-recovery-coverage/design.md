## Context

Recovery не поддерживает Book Reduce, work rename, state migrate и Classic reconcile. Часть handlers не проверяет current post-hash или фазу каждого заменённого файла; journal обновляется после write, оставляя crash windows.

Аудит: `F07`, `A-RECOVERY`, `A-JOURNAL-PATHS`, `A-MIGRATION`; исходный baseline: `ERL-STATE-008`, `ERL-STATE-017`, `ERL-REDUCE-018`, `ERL-REDUCE-019`, `ERL-REDUCE-023`, `ERL-ING-008`. Новые requirement IDs принадлежат только этой delta; другие deltas этого набора не заменяют эти же requirements.

## Goals / Non-Goals

**Goals:** выполнить observable acceptance в `specs/` и убрать перечисленные audit gaps.

**Non-Goals:** переписывать ERL на другой язык, добавлять БД/веб-платформу, менять canonical UUID или ссылки массово, изменять host core, запускать production migrations при подготовке спецификации.

## Decisions

### 1. Решение

Описать для каждой operation таблицу состояний: planned, backed-up/prepared, per-artifact intent/result, domain-applied, validated, committed, rolled-back, conflict. Конкретные имена внутренние, journal schema version публично распознаётся.

### 2. Решение

Backup и intent публикуются до изменяемых bytes; crash между filesystem write и journal completion разрешается по pre/post hashes и inventories. Документировать границу durability: process crash обязателен, power-loss гарантия только при проверенной fsync strategy.

### 3. Решение

Recovery сначала preflight всех targets и backups, затем mutation; на external edit запрещены blind cp и delete. Commit recovery проверяет complete state/links, а не только наличие manifest pointer.

### 4. Решение

Общий transaction.zsh/context уменьшает разницу handlers; failure injection обеспечивает остановку после каждого persistent step, включая constructor side effects и финализацию.

### 5. Решение

Path rename/layout move не переписывают неизвестные pending journals. До миграции их нужно восстановить либо явно мигрировать paths с hashes в той же recoverable операции.

## Dependencies and sequencing

- [fix-work-state-path-safety](../fix-work-state-path-safety/proposal.md)
- [fix-cross-operation-mutation-serialization](../fix-cross-operation-mutation-serialization/proposal.md)
- [fix-cli-error-propagation](../fix-cli-error-propagation/proposal.md)
- [fix-runtime-schema-conformance](../fix-runtime-schema-conformance/proposal.md)

Implementation начинается после обязательных prerequisites; независимые changes допускают отдельную реализацию. Перед apply/archive перечитать current canonical specs, проверить отсутствие concurrent contract drift и обновить delta при необходимости. Возможный перенос общего кода в `.scripts/erl/lib/` выполняется в owner delta соответствующего поведения, с сохранением public CLI и regression parity.

## Risks / Trade-offs

- Generic engine без operation semantics недостаточен; ownership, closure и receipt invariants остаются обязательными.
- Нельзя удалять backups до validation и durable finalization; cleanup committed artifacts не удаляет compact audit record.

## Migration and rollback

Legacy journals сохраняются и читаются с version adapters там, где есть достаточные backups/hashes. Неполный старый journal даёт blocked manual recovery plan с inventory; unsupported legacy не может быть помечен recovered. Каждый новый writer обязан зарегистрировать recovery до выпуска.

Новые state/journal representations требуют явной version policy и прочтения supported legacy. Backup, pre/post hashes, dirty-target policy и recovery должны соответствовать applied prerequisite contracts. До migration работающее состояние сохраняется; unspecified legacy не переинтерпретируется. Откат code-only изменения не должен молча читать новый state старой версией.

## Verification

Primary regression: `tests/erl-transaction-recovery-coverage.zsh`. Tests используют disposable target и explicit test host; пользовательский Vault не является fixture. Негативные scenarios проверяют exit/envelope и pre/post inventories; structural text tests дополняют behavioral evidence. Для external/live/platform cases сохраняется NOT VERIFIED/SKIP до реального run; это не successful acceptance.

Implementation evidence хранит source/config versions, команды, результаты и применимые limitations. До completion выполнить strict delta validation, applicable complete suite и diff hygiene; перед архивированием выполнить штатные pre/post archive checks. Все tasks в этом planning change остаются открытыми до фактического исполнения.
