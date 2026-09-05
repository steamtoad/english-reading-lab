## Context

Источником истины являются notes плюс works, оба могут быть Git-ignored. Наличие journals не равно проверенному восстановлению после потери каталога. Оператору нужен read-only список pending операций, а cleanup не должен удалять persistent или unresolved данные.

Аудит: `A-BACKUP`, `A-RETENTION`, `A-OPERATIONS`, `A-TRANSACTION-LIST`; исходный baseline: `ERL-STATE-003`, `ERL-STATE-006`, `ERL-STATE-008`, `ERL-STATE-010`, `ERL-CHECK-018`. Новые requirement IDs принадлежат только этой delta; другие deltas этого набора не заменяют эти же requirements.

## Goals / Non-Goals

**Goals:** выполнить observable acceptance в `specs/` и убрать перечисленные audit gaps.

**Non-Goals:** переписывать ERL на другой язык, добавлять БД/веб-платформу, менять canonical UUID или ссылки массово, изменять host core, запускать production migrations при подготовке спецификации.

## Decisions

### 1. Решение

Минимальные local CLI wrappers над прозрачным archive+manifest, без daemon/DB. Backup получает согласованный snapshot под mutation protection: notes, works, compact audit и unresolved journals/backups; cache/locks не копируются как authoritative.

### 2. Решение

Sources включаются только explicit option либо их отсутствие явно записано с identity; credentials и global OpenClaw config не включаются. Staging policy различает disposable и незавершённый intended batch, предупреждает о невозможности resume при исключении такого input.

### 3. Решение

Restore dry-run валидирует archive inventory/hash/path/link safety и target collisions до записи. Apply по умолчанию только в empty disposable/new target, conflict-safe и recoverable. Live owner locks никогда не восстанавливаются из backup.

### 4. Решение

Relocation связывает relative target paths с новым canonical root; старые absolute journal/source pointers не применяются слепо. Неизвестный journal блокирует completion без удаления backups. External source rebind использует verified fingerprint.

### 5. Решение

erl-transaction-list --vault --json даёт operation/version/phase, scope, supported actions и blockers, включая setup journal family. Runbook сопоставляет ошибки с doctor, check, recover, backup и safe retry.

### 6. Решение

Retention cleanup рассматривает works как permanent, unresolved journals/backups не удаляет, compact audit сохраняет; destructive actions только explicit plan.

## Dependencies and sequencing

- [fix-work-state-path-safety](../fix-work-state-path-safety/proposal.md)
- [fix-cross-operation-mutation-serialization](../fix-cross-operation-mutation-serialization/proposal.md)
- [fix-transaction-recovery-coverage](../fix-transaction-recovery-coverage/proposal.md)
- [fix-source-policy-provenance](../fix-source-policy-provenance/proposal.md)
- [add-reproducible-erl-bootstrap](../add-reproducible-erl-bootstrap/proposal.md)

Implementation начинается после обязательных prerequisites; независимые changes допускают отдельную реализацию. Перед apply/archive перечитать current canonical specs, проверить отсутствие concurrent contract drift и обновить delta при необходимости. Возможный перенос общего кода в `.scripts/erl/lib/` выполняется в owner delta соответствующего поведения, с сохранением public CLI и regression parity.

## Risks / Trade-offs

- Скопировать files во время writer недостаточно для consistent snapshot.
- Disk-full/failure restore не должен оставлять частично активный Vault с fake success.
- Backup без source books восстановит state/cards, но export может потребовать rebind; это явно видно в manifest.

## Migration and rollback

Snapshot format versioned. Existing deployments получают документированную backup policy без изменения Git tracking. Restore не переименовывает UUID, не применяет пользовательские host bindings автоматически и не мигрирует чужой Vault без отдельного запроса.

Новые state/journal representations требуют явной version policy и прочтения supported legacy. Backup, pre/post hashes, dirty-target policy и recovery должны соответствовать applied prerequisite contracts. До migration работающее состояние сохраняется; unspecified legacy не переинтерпретируется. Откат code-only изменения не должен молча читать новый state старой версией.

## Verification

Primary regression: `tests/erl-erl-backup-restore.zsh`. Tests используют disposable target и explicit test host; пользовательский Vault не является fixture. Негативные scenarios проверяют exit/envelope и pre/post inventories; structural text tests дополняют behavioral evidence. Для external/live/platform cases сохраняется NOT VERIFIED/SKIP до реального run; это не successful acceptance.

Implementation evidence хранит source/config versions, команды, результаты и применимые limitations. До completion выполнить strict delta validation, applicable complete suite и diff hygiene; перед архивированием выполнить штатные pre/post archive checks. Все tasks в этом planning change остаются открытыми до фактического исполнения.
