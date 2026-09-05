## ADDED Requirements

### Requirement: ERL-PATH-001 — Mutation targets remain within their canonical roots

Каждая ERL mutation MUST проверить принадлежность canonical destination своему разрешённому root до первой записи и при обнаружении path drift. Traversal, symlink escape и путь из неподтверждённого journal MUST отклоняться без изменения данных вне scope.

#### Scenario: Traversal slug is rejected

- **GIVEN** существует сторонний sentinel рядом с Vault
- **WHEN** dry-run и apply получают --work-slug ../../../../victim
- **THEN** обе команды SHALL вернуть invalid-input/conflict diagnostic до записи
- **AND** sentinel и его hash SHALL сохраниться

#### Scenario: Symlink and prefix sibling are not contained

- **GIVEN** notes либо компонент state указывает symlink за пределы разрешённого root
- **WHEN** операция планирует или выполняет запись
- **THEN** операция SHALL остановиться до изменения external target
- **AND** каталог с совпадающим строковым prefix SHALL не считаться вложенным

### Requirement: ERL-PATH-003 — Rollback removes only owned artifacts

Rollback MUST различать pre-existing и newly created artifacts и MUST NOT рекурсивно удалять заранее существовавший каталог. Constructor output MUST быть проверенным canonical UUID.adoc внутри target notes до использования как destination. Несовпадение current hash с journal MUST сохранять файл и давать recovery conflict.

#### Scenario: Constructor failure preserves unrelated files

- **GIVEN** в target или соседнем каталоге находится sentinel до начала transaction
- **WHEN** constructor завершается ошибкой и выполняется rollback
- **THEN** sentinel SHALL сохранить bytes и location
- **AND** удалены SHALL быть только подтверждённые новые артефакты

#### Scenario: Malformed constructor output is rejected

- **GIVEN** test constructor возвращает ../outside.adoc или постороннюю строку
- **WHEN** ingest обрабатывает stdout constructor
- **THEN** ERL SHALL завершиться ошибкой до append по этому пути
