## Context

Minimal EPUB экспортируется как raw XHTML на macOS; fallback другой ОС отличается. Частично читаемые spine items могут пропускаться. TXT/Markdown/HTML сейчас дают по одной Chapter на файл, что не объяснено пользователю.

Аудит: `F09`, `A-FORMATS`; исходный baseline: `ERL-CHAPTER-007`, `ERL-EXT-003`, `ERL-SHELL-003`, `ERL-DOC-008`. Новые requirement IDs принадлежат только этой delta; другие deltas этого набора не заменяют эти же requirements.

## Goals / Non-Goals

**Goals:** выполнить observable acceptance в `specs/` и убрать перечисленные audit gaps.

**Non-Goals:** переписывать ERL на другой язык, добавлять БД/веб-платформу, менять canonical UUID или ссылки массово, изменять host core, запускать production migrations при подготовке спецификации.

## Decisions

### 1. Решение

Определить единые normalization rules: XML/HTML markup и script/style не входят в extracted prose; entities декодируются; paragraph separation, Unicode и source order сохраняются.

### 2. Решение

Explicit input format для converter; вместо regex fallback, меняющего meaning, использовать проверенный доступный parser либо явную unsupported-format/tool diagnostic.

### 3. Решение

EPUB package/manifest/href resolution обрабатывает namespaces, percent-encoding, fragments и relative paths; logical locator сохраняется. linear=no support документируется и не смешивается молча с main reading order.

### 4. Решение

Broken/missing spine item, traversal/unsafe external reference и некорректный UTF-8 дают explicit failure до partial Book commit. Никаких сетевых обращений ради content resolution.

### 5. Решение

Для TXT/Markdown/HTML v1 одна Chapter на файл — заявленный scope; автоматическое распознавание произвольных глав не добавляется.

## Dependencies and sequencing

- [fix-cli-error-propagation](../fix-cli-error-propagation/proposal.md)
- [fix-chapter-export-streaming](../fix-chapter-export-streaming/proposal.md)
- [fix-source-policy-provenance](../fix-source-policy-provenance/proposal.md)

Implementation начинается после обязательных prerequisites; независимые changes допускают отдельную реализацию. Перед apply/archive перечитать current canonical specs, проверить отсутствие concurrent contract drift и обновить delta при необходимости. Возможный перенос общего кода в `.scripts/erl/lib/` выполняется в owner delta соответствующего поведения, с сохранением public CLI и regression parity.

## Risks / Trade-offs

- Parser различия могут изменить пробелы; expected fixture output является каноническим поведением.
- Поддержка формата не означает поддержку всех DRM/EPUB вариаций; неподдержанное диагностируется.

## Migration and rollback

Existing SOURCE_ID/Chapter locators не переписываются. Изменение normalization, влияющее на semantic extraction, версионируется в processing contract для последующих generations; existing committed memos сохраняются.

Новые state/journal representations требуют явной version policy и прочтения supported legacy. Backup, pre/post hashes, dirty-target policy и recovery должны соответствовать applied prerequisite contracts. До migration работающее состояние сохраняется; unspecified legacy не переинтерпретируется. Откат code-only изменения не должен молча читать новый state старой версией.

## Verification

Primary regression: `tests/erl-source-format-normalization.zsh`. Tests используют disposable target и explicit test host; пользовательский Vault не является fixture. Негативные scenarios проверяют exit/envelope и pre/post inventories; structural text tests дополняют behavioral evidence. Для external/live/platform cases сохраняется NOT VERIFIED/SKIP до реального run; это не successful acceptance.

Implementation evidence хранит source/config versions, команды, результаты и применимые limitations. До completion выполнить strict delta validation, applicable complete suite и diff hygiene; перед архивированием выполнить штатные pre/post archive checks. Все tasks в этом planning change остаются открытыми до фактического исполнения.
