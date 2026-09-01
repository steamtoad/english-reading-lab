## ADDED Requirements

### Requirement: ERL-CHAPTER-012 — Chapter Note inherits Book Topic key-topic

Каждая Chapter Note, прикреплённая к active Book Topic generation, MUST содержать host-defined header attribute `:key-topic:` с точным значением `:key-topic:` этой Book Topic.

Значение MUST сохранять canonical host semantics тематической группировки и MUST NOT быть `WORK_ID`, Book Topic UUID, Chapter UUID или иным ERL-local foreign key.

#### Scenario: Chapter Note is attached during Book ingest

- **GIVEN** Book Topic содержит непустой canonical `:key-topic:`
- **WHEN** ERL создаёт Chapter Note для active Book generation
- **THEN** Chapter Note SHALL получить `:key-topic:` с точным значением из Book Topic
- **AND** значение SHALL храниться как header attribute
- **AND** ERL SHALL NOT выводить его из UUID или ERL persistent state identifier

#### Scenario: Chapter Note key-topic differs from active Book Topic

- **GIVEN** Chapter Note зарегистрирована для active Book generation
- **WHEN** её `:key-topic:` отсутствует или отличается от `:key-topic:` Book Topic
- **THEN** Chapter Note SHALL считаться неприкреплённой или неверно прикреплённой
- **AND** ingest SHALL NOT считать Book–Chapter materialization успешно завершённой

### Requirement: ERL-CHAPTER-013 — Book Topic and Chapter Note have reciprocal canonical links

Active Book Topic и каждая соответствующая Chapter Note MUST содержать взаимные canonical links формата `link:UUID.adoc[Description]`.

Chapter Note MUST содержать ровно одну active Book Topic link в структурной секции `Book`. Book Topic MUST содержать ровно одну link на каждую Chapter Note текущего source в структурной секции `Chapters`, упорядоченную по source order.

#### Scenario: Chapter Note is linked to Book Topic

- **WHEN** ERL materializes Chapter Note для active Book generation
- **THEN** секция `Book` Chapter Note SHALL содержать canonical link на UUID active Book Topic
- **AND** секция `Chapters` Book Topic SHALL содержать canonical link на UUID этой Chapter Note
- **AND** обе стороны SHALL существовать после committed ingest

#### Scenario: Book contains multiple Chapters

- **GIVEN** source содержит несколько Chapters
- **WHEN** ERL формирует секцию `Chapters` Book Topic
- **THEN** Topic SHALL содержать ровно одну canonical link на каждую зарегистрированную Chapter Note текущего source
- **AND** links SHALL следовать source order
- **AND** duplicate links на один Chapter UUID SHALL NOT создаваться

### Requirement: ERL-CHAPTER-014 — Durable Chapter is rebound to the active Book Topic generation

Поскольку Chapter UUID сохраняется между generations, Chapter Note MUST иметь одну current attachment к active Book Topic generation соответствующего logical work.

При создании новой active generation ERL MUST transactionally заменить прежнюю active Book Topic link в Chapter Note новой link и MUST установить `:key-topic:`, равный новой active Book Topic. Historical generation membership MUST оставаться в persistent audit/state semantics, а не представляться второй active attachment Chapter Note.

#### Scenario: Existing source Chapter enters a new generation

- **GIVEN** durable Chapter Note была прикреплена к предыдущей Book Topic generation
- **WHEN** ERL создаёт новую active generation для того же logical work и source Chapter
- **THEN** Chapter UUID SHALL остаться прежним
- **AND** current Book link SHALL указывать на новую active Book Topic
- **AND** Chapter `:key-topic:` SHALL точно совпадать с новой Book Topic
- **AND** Chapter Note SHALL NOT сохранять вторую active Book Topic attachment

### Requirement: ERL-CHAPTER-015 — Chapter–Topic binding is transactionally materialized

Создание или rebind Chapter `:key-topic:`, Chapter→Topic links и Topic→Chapter links MUST входить в ту же recoverable semantic transaction, что и Book generation ingest.

Operation MUST завершаться только при согласованности всех Chapter Notes текущего source и Book Topic; partial binding MUST приводить к rollback до предыдущего валидного состояния.

#### Scenario: Reciprocal link update fails

- **GIVEN** Book ingest создал или изменил часть Chapter–Topic bindings
- **WHEN** запись одной из reciprocal links или `:key-topic:` завершается ошибкой
- **THEN** transaction SHALL NOT commit generation
- **AND** все созданные documents и изменения существующих Chapter Notes SHALL быть удалены или восстановлены из journal backups
- **AND** previous valid Chapter attachment SHALL быть сохранена

