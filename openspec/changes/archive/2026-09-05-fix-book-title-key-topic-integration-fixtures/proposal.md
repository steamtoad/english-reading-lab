## Why

Два существующих интеграционных fixture всё ещё моделируют отдельный umbrella `:key-topic: Reading`, хотя активный change `fix-book-title-key-topic` требует exact equality между canonical title книги и ключами Book, Chapters и применимых Memo. Из-за этого `tests/erl-human-readable-card-content.zsh` завершается кодом 60 на финальном apply, а `tests/erl-chapter-chain-handoff.zsh` — кодом 1 на финальном `erl-check`, хотя проверяемое ими поведение не связано с конфликтом key-topic.

## What Changes

- Согласовать Book, Chapter, Vocabulary и Occurrence документы fixture `erl-human-readable-card-content.zsh` с canonical title `A Human Book`.
- Согласовать Book, все Chapters и Memo fixture `erl-chapter-chain-handoff.zsh` с canonical title `Handoff Book`.
- Сохранить исходный предмет обеих интеграционных проверок: repair человекочитаемого card content и handoff между Chapter chains.
- Подтвердить, что оба теста и полный integration suite проходят с действующей политикой `fix-book-title-key-topic`.
- Не изменять runtime-контракты, production implementation, persistent schema или пользовательские Vault documents.

## Capabilities

### New Capabilities

Нет.

### Modified Capabilities

- `engineering-safety`: положительные integration fixtures должны соответствовать действующему canonical contract и не маскировать предмет теста несвязанной validation failure.

## Impact

Изменения ограничены `tests/erl-human-readable-card-content.zsh`, `tests/erl-chapter-chain-handoff.zsh` и их regression verification. Обратная совместимость runtime не меняется; миграция и destructive operations отсутствуют. Host contract и граница ERL/host не затрагиваются.
