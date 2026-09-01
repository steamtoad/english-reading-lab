## Why

Текущий `erl-book-ingest` создаёт Book Topic и Chapter Notes как отдельные canonical documents, но не формирует между ними двустороннюю Vault-связь и не прикрепляет Chapter Notes к тематической линии Book Topic через host-defined `:key-topic:`. В результате структура книги существует только в ERL work state и не представлена полноценно внутри самого Vault.

## What Changes

- Обязать каждую Chapter Note активной Book generation иметь точное значение `:key-topic:`, равное `:key-topic:` соответствующей Book Topic.
- Добавить canonical link из каждой Chapter Note на Book Topic и обратный canonical link из Book Topic на каждую Chapter Note.
- Определить структурные секции `Book` и `Chapters`, уникальность ссылок и source-order обратных ссылок.
- Определить rebind durable Chapter Notes при переходе к новой active Book generation без изменения Chapter UUID.
- Сделать создание и обновление двухсторонних связей частью recoverable Book ingest transaction.
- Расширить `erl-check` проверкой key-topic attachment, взаимности ссылок, отсутствия duplicates и соответствия active generation.

## Capabilities

### New Capabilities

Нет.

### Modified Capabilities

- `source-chapters`: добавляется canonical attachment Chapter Note к active Book Topic через `:key-topic:` и взаимные ссылки.
- `validation`: добавляется read-only проверка Chapter–Book Topic attachment и bidirectional link integrity.

## Impact

Будущая реализация затронет ERL-owned `erl-book-ingest`, `erl-check`, transaction recovery, host-contract test double, CLI contract, legacy traceability и focused tests. Chapter UUID, source identity и work-state schema не меняются. Для существующих works потребуется отдельная explicit migration с dry-run, collision/conflict detection, rollback и recovery; эта дельта не разрешает молчаливую перезапись пользовательского Vault. Destructive operations отсутствуют.

Host-contract gap отсутствует: `:key-topic:` является canonical host key тематической группировки и связи документов, а internal links используют существующий формат `link:UUID.adoc[Description]`. ERL MUST NOT использовать `:key-topic:` как `WORK_ID`, generation UUID или иной plugin-specific foreign key.
