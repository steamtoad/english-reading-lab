## Context

Export выдаёт новые bytes заменённого source с прежним SOURCE_ID, принимает stale policy hash и не возвращает source_fingerprint, который обязателен для staging. Локальный source_path также должен переноситься без подмены edition.

Аудит: `F05`, `A-SOURCE-RELOCATION`; исходный baseline: `ERL-CHAPTER-005`, `ERL-CHAPTER-006`, `ERL-CHAPTER-010`, `ERL-EXT-004`, `ERL-CAND-002`. Новые requirement IDs принадлежат только этой delta; другие deltas этого набора не заменяют эти же requirements.

## Goals / Non-Goals

**Goals:** выполнить observable acceptance в `specs/` и убрать перечисленные audit gaps.

**Non-Goals:** переписывать ERL на другой язык, добавлять БД/веб-платформу, менять canonical UUID или ссылки массово, изменять host core, запускать production migrations при подготовке спецификации.

## Decisions

### 1. Решение

Экспортировать из проверенного snapshot source bytes либо обнаруживать drift между hash и чтением; иначе один предварительный hash оставляет race.

### 2. Решение

Response добавляет source_identity:{source_id,source_fingerprint}; existing source_id сохраняется как compatibility field, оба значения совпадают.

### 3. Решение

Полная policy и её hash проверяются при exporter boundary. Staging сверяет validated exported identity с retained source state.

### 4. Решение

Добавить explicit erl-source-rebind.zsh --vault --work-id --source-id --source (--dry-run|--apply) --json: меняется только locator к byte-identical файлу; новый edition идёт штатным новым SOURCE_ID. Recovery новой operation обязательна.

## Dependencies and sequencing

- [fix-cli-error-propagation](../fix-cli-error-propagation/proposal.md)
- [fix-chapter-export-streaming](../fix-chapter-export-streaming/proposal.md)
- [fix-runtime-schema-conformance](../fix-runtime-schema-conformance/proposal.md)
- [fix-cross-operation-mutation-serialization](../fix-cross-operation-mutation-serialization/proposal.md)
- [fix-transaction-recovery-coverage](../fix-transaction-recovery-coverage/proposal.md)

Implementation начинается после обязательных prerequisites; независимые changes допускают отдельную реализацию. Перед apply/archive перечитать current canonical specs, проверить отсутствие concurrent contract drift и обновить delta при необходимости. Возможный перенос общего кода в `.scripts/erl/lib/` выполняется в owner delta соответствующего поведения, с сохранением public CLI и regression parity.

## Risks / Trade-offs

- Повторное хеширование больших EPUB стоит времени; оптимизации не должны принимать changed bytes под старой identity.
- Rebind меняет persistent state и внедряется только после общего transaction/recovery protocol, заданного fix-transaction-recovery-coverage.

## Migration and rollback

Дополнительное response поле backward-compatible. Rebind сохраняет WORK_ID/SOURCE_ID/Chapter UUID. Отсутствующий старый source допустим для rebind только если новый файл совпал с retained fingerprint; legacy записи без достаточной identity получают migration diagnostic.

Новые state/journal representations требуют явной version policy и прочтения supported legacy. Backup, pre/post hashes, dirty-target policy и recovery должны соответствовать applied prerequisite contracts. До migration работающее состояние сохраняется; unspecified legacy не переинтерпретируется. Откат code-only изменения не должен молча читать новый state старой версией.

## Verification

Primary regression: `tests/erl-source-policy-provenance.zsh`. Tests используют disposable target и explicit test host; пользовательский Vault не является fixture. Негативные scenarios проверяют exit/envelope и pre/post inventories; structural text tests дополняют behavioral evidence. Для external/live/platform cases сохраняется NOT VERIFIED/SKIP до реального run; это не successful acceptance.

Implementation evidence хранит source/config versions, команды, результаты и применимые limitations. До completion выполнить strict delta validation, applicable complete suite и diff hygiene; перед архивированием выполнить штатные pre/post archive checks. Все tasks в этом planning change остаются открытыми до фактического исполнения.
