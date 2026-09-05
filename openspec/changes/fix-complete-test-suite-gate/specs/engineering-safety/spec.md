## ADDED Requirements

### Requirement: ERL-TEST-004 — The mandatory suite covers every declared behavioral test

Один documented test entry point MUST запускать все mandatory behavioral suites без скрытых пропусков и дублей. Каждый physical test entry MUST быть классифицирован manifest; unknown/missing mandatory test MUST делать gate неуспешным. Optional live tests MUST отдельно сообщать SKIP.

#### Scenario: A failing chain test exists outside the runner

- **GIVEN** chapter-memo-chain test падает
- **WHEN** запускается единый suite
- **THEN** общий результат SHALL быть FAIL и содержать имя теста

#### Scenario: An unclassified test file is added

- **GIVEN** новый behavioral test присутствует, manifest не обновлён
- **WHEN** запускается suite gate
- **THEN** gate SHALL сообщить classification failure

#### Scenario: Live credentials are not configured

- **GIVEN** offline suites доступны, live режим не включён
- **WHEN** runner формирует итог
- **THEN** обязательные suites SHALL выполниться
- **AND** live SHALL быть SKIP, отдельно от PASS/FAIL totals

### Requirement: ERL-TEST-005 — Test fixtures are canonical and environment-independent

Positive fixtures MUST соответствовать текущему baseline, включая exact title/key-topic. Fixture paths MUST учитывать canonical symlink aliases; tests MUST явно использовать изолированный host и не зависеть от домашнего каталога автора или private state.

#### Scenario: Temporary root has a symlink alias

- **GIVEN** TMPDIR представлен как /var/... либо его canonical /private/var/...
- **WHEN** запускаются setup/root-binding tests
- **THEN** оба варианта SHALL проверять один и тот же behavioral contract без ложного failure

#### Scenario: Fresh machine lacks author host directories

- **GIVEN** на машине есть только repo и declared dependencies
- **WHEN** запускаются mandatory offline tests
- **THEN** test host SHALL быть явно fixture-scoped и выполнение SHALL не обращаться к личному Vault

### Requirement: ERL-TEST-006 — Suite prerequisites and negative guarantees are explicit

Runner MUST иметь воспроизводимый documented preparation path для checkout и source archive и ясные diagnostics отсутствующего Git/skills/tools. Safety fixes MUST сопровождаться behavioral negative tests, а literal phrase checks MUST NOT заменять их.

#### Scenario: Unprepared source archive is tested

- **GIVEN** skills не материализованы или Git metadata отсутствует
- **WHEN** пользователь запускает documented test command
- **THEN** команда SHALL выполнить разрешённую изолированную подготовку либо выдать конкретные prerequisites
- **AND** безымянный exit без причины SHALL не быть единственной диагностикой
