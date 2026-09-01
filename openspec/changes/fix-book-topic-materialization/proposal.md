## Why

Текущий `erl-book-ingest` может зарегистрировать Book generation в persistent state, однако создаваемая Topic представлена заголовком тематического `key-topic`, а не названием книги. В результате книга не становится узнаваемым canonical Topic внутри Vault, хотя исходные требования `Book = Topic` формально считаются выполненными.

## What Changes

- Уточнить, что успешный Book ingest обязан материализовать canonical Topic именно для книги, а не только создать type-compatible Topic или state-only generation.
- Сделать название logical work основой видимого title Book Topic; тематический `:key-topic:` сохранить отдельной host-compatible классификацией.
- Запретить публикацию успешного generation state и `generation_uuid`, если соответствующий canonical Book Topic отсутствует, невалиден или не соответствует книге.
- Потребовать атомарный rollback документов и state при невозможности создать или проверить Book Topic.
- Добавить проверку существующих active/retained generations и диагностировать state-only или неверно представленную Book Topic.

## Capabilities

### New Capabilities

Нет.

### Modified Capabilities

- `work-generation`: усиливается обязательная материализация Book generation как canonical Topic конкретной книги и согласованность Topic с generation state.
- `validation`: добавляется обязательная диагностика отсутствующей или неверно представленной Book Topic для зарегистрированной generation.

## Impact

Будущая реализация затронет ERL-owned `erl-book-ingest`, `erl-check`, интеграционные тесты, CLI contract и legacy traceability. Persistent state schema, canonical host metadata и host constructors не меняются. Для уже зарегистрированных generations потребуется read-only аудит; автоматическая перезапись или создание Topic для пользовательского Vault в рамках этой дельты не выполняются. Destructive operations отсутствуют. Host-contract gap не обнаружен: canonical Topic constructor уже доступен через target host contract.
