## ADDED Requirements

### Requirement: ERL-PATH-002 — New work slugs are safe locators

Новые --work-slug и --new-slug MUST использовать одну опубликованную безопасную грамматику без slash, dot components и control characters. Чтение существующей work по WORK_ID MUST сохраняться независимо от legacy slug; исправление имени MUST быть explicit migration с сохранением identity.

#### Scenario: Existing nonstandard slug remains addressable

- **GIVEN** существующая work имеет legacy slug и stable WORK_ID
- **WHEN** пользователь читает work или явно переименовывает её в допустимый slug
- **THEN** WORK_ID, document UUID и ссылки SHALL сохраниться

#### Scenario: Existing directory is not silently adopted

- **GIVEN** каталог допустимого нового slug уже содержит посторонние файлы
- **WHEN** создаётся новая work без существующего work.json
- **THEN** операция SHALL сообщить collision либо сохранить каждый pre-existing artifact при failure
