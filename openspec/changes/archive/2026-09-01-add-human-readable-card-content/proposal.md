## Why

Canonical тип и корректная metadata ещё не гарантируют, что созданная ERL карточка полезна читателю: Book, Chapter, Vocabulary или Occurrence могут оказаться формально валидными, но пустыми, машинно-ориентированными либо содержать необработанные данные. Для всех ERL cards нужен единый проверяемый контракт человекочитаемого AsciiDoc content.

## What Changes

- Обязать каждую ERL card роли Book, Chapter, Vocabulary или Occurrence быть валидным UTF-8 AsciiDoc document с непустым человекочитаемым содержимым.
- Определить общие признаки readability: понятный document title, структурированное body, role-relevant information, canonical links с осмысленными labels и отсутствие raw serialization, необработанного source markup и unresolved placeholders.
- Сохранить существующие role-specific structural contracts Vocabulary и Occurrence и распространить эквивалентное требование полезного content на Book Topic и Chapter Note.
- Добавить read-only validation синтаксиса, минимальной role-relevant полноты и запрещённых machine-oriented artifacts.
- Требовать explicit audit/repair существующих ERL cards; автоматическая перезапись пользовательского content не допускается.

## Capabilities

### New Capabilities

Нет.

### Modified Capabilities

- `vault-integration`: добавляется общий presentation/content contract для всех persistent ERL cards.
- `validation`: добавляется read-only диагностика AsciiDoc validity и human-readable role content.

## Impact

Будущая реализация затронет Book/Chapter/Vocabulary/Occurrence creation paths, `erl-check`, fixtures, CLI contract и legacy requirements traceability. Изменение обратно совместимо для существующих cards, уже удовлетворяющих контракту; остальные потребуют explicit audit/repair с dry-run и conflict reporting. Persistent work-state schema, UUID, filenames, canonical types, `:key-topic:` semantics и lifecycle не меняются.

Пользовательский Vault не изменяется на стадии спецификации и не должен изменяться автоматически при будущей проверке. Destructive operations отсутствуют. Host-contract gap отсутствует: canonical constructors уже создают AsciiDoc Topic/Note/Memo, а role-relevant body является ответственностью ERL; host core не изменяется.
