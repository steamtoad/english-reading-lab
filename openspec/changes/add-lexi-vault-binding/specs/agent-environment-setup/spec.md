## ADDED Requirements

### Requirement: ERL-AGENT-SETUP-009 — Every Lexi skill binds Vault to ERL_HOME

После успешного разрешения absolute `ERL_HOME` каждый из семи Lexi runtime skills MUST передавать каждому ERL CLI invocation аргументы `--vault "${ERL_HOME}"`. Для Lexi resolved `ERL_HOME` MUST одновременно обозначать workspace repository root и canonical target Zettelkasten home, непосредственно содержащий `notes/` и `.state/erl/`.

Skill MUST NOT подменять этот target пользовательским Zettelkasten checkout, home directory, parent directory либо nested `vault/`, включая случаи, когда такой каталог существует и содержит host implementation. Отдельный configured host root MUST использоваться только для разрешения canonical object constructors и MUST NOT изменять значение `--vault`.

Materialized `TOOLS.md`, derived agent contract, все семь reference copies и embedded setup payload MUST сообщать одинаковое правило Vault binding. Development validation MUST завершаться ошибкой, если хотя бы один supported skill не содержит или не соблюдает этот контракт.

#### Scenario: Book ingest uses the Lexi workspace as Vault

- **GIVEN** Lexi разрешила `ERL_HOME` как `/workspace/english-reading-lab`
- **WHEN** `erl-book-ingest` формирует dry-run или apply invocation
- **THEN** invocation SHALL содержать `--vault "/workspace/english-reading-lab"`
- **AND** planned work state SHALL находиться под `/workspace/english-reading-lab/.state/erl/works/`

#### Scenario: Every supported skill has the same Vault binding

- **GIVEN** materialized полный набор семи supported Lexi runtime skills
- **WHEN** skill packaging validation проверяет agent contract и reference copies
- **THEN** каждый skill SHALL требовать `--vault "${ERL_HOME}"` для каждого ERL command
- **AND** validation SHALL завершаться ошибкой с именем skill при отсутствии этого правила

#### Scenario: Host root differs from target Vault

- **GIVEN** `ERL_HOME` указывает на Lexi workspace, а configured host root указывает на отдельный Zettelkasten host checkout
- **WHEN** Lexi запускает command, создающий canonical Vault objects
- **THEN** command SHALL получить `--vault "${ERL_HOME}"`
- **AND** host root SHALL использоваться только для object-constructor resolution
- **AND** documents и persistent ERL state SHALL создаваться внутри `ERL_HOME`, а не внутри host root

#### Scenario: User Zettelkasten checkout exists

- **GIVEN** на машине существует отдельный пользовательский Zettelkasten checkout
- **WHEN** Lexi формирует любой ERL CLI invocation
- **THEN** его наличие SHALL NOT изменять `--vault "${ERL_HOME}"`
- **AND** skill SHALL NOT автоматически выбирать пользовательский checkout как target Vault
