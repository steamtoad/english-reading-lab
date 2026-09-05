# agent-environment-setup Specification

## Purpose
Определить воспроизводимый, проверяемый и безопасный bootstrap локального OpenClaw workspace для специализированного ERL runtime agent Lexi.

## Requirements

### Requirement: ERL-AGENT-SETUP-001 — Setup is self-contained and versioned

ERL repository MUST содержать tracked executable setup script, который является versioned source of truth для локальной OpenClaw Lexi infrastructure и не зависит от уже существующих ignored agent files.

Script MUST содержать полный deployment payload либо его детерминированное self-contained представление. Fresh checkout с доступным OpenClaw runtime MUST быть достаточен для подготовки Lexi workspace.

#### Scenario: Fresh checkout has no local agent infrastructure

- **GIVEN** все ignored Lexi workspace artifacts отсутствуют
- **WHEN** пользователь запускает setup script для ERL workspace
- **THEN** script SHALL иметь все versioned данные, необходимые для materialization agent infrastructure
- **AND** SHALL NOT требовать копирования files из другого локального OpenClaw workspace

### Requirement: ERL-AGENT-SETUP-002 — Setup materializes the complete Lexi workspace payload

После successful apply script MUST materialize следующий managed artifact set внутри выбранного ERL workspace:

- `openclaw-workspace-state.json`;
- `HEARTBEAT.md`;
- `IDENTITY.md`;
- `SOUL.md`;
- `TOOLS.md`;
- `USER.md`;
- полный Lexi runtime `skills/` вместе с required references;
- `.scripts/erl/docs/lexi-agent.md`.

Materialized skill set MUST включать ровно семь поддерживаемых Lexi runtime skills: `erl-book-ingest`, `erl-chapter-vocabulary-extract`, `erl-vocabulary-ingest`, `erl-chapter-vocabulary-ingest`, `erl-book-reduce`, `erl-classic-reduce-reconcile` и `erl-check`.

#### Scenario: Setup applies to an empty workspace

- **WHEN** apply успешно завершается в empty target artifact set
- **THEN** каждый managed artifact SHALL существовать в ожидаемом relative path
- **AND** все семь runtime skills и их required references SHALL быть materialized
- **AND** workspace state SHALL фиксировать payload version, payload hash и успешное completion time

### Requirement: ERL-AGENT-SETUP-003 — Local values are explicit and secrets are excluded

Setup MUST принимать или детерминированно разрешать target workspace path и MUST позволять явно задать user-facing profile values, включая user name и timezone, без изменения embedded payload вручную.

Versioned или materialized payload MUST NOT содержать credentials, access tokens, session history, external channel bindings или machine-specific OpenClaw secrets. Setup MUST NOT изменять global OpenClaw configuration или регистрировать external bindings.

#### Scenario: User deploys Lexi on another machine

- **WHEN** setup запускается с другим workspace path, user name или timezone
- **THEN** generated `TOOLS.md` и `USER.md` SHALL отражать resolved values
- **AND** static Lexi identity, safety boundary и skill contracts SHALL оставаться неизменными
- **AND** global OpenClaw configuration SHALL оставаться неизменной

### Requirement: ERL-AGENT-SETUP-004 — Setup supports dry-run, check and explicit apply

Setup MUST поддерживать non-mutating dry-run, non-mutating integrity check и explicit apply.

Dry-run MUST показать target root, payload version/hash и planned create/keep/conflict actions. Check MUST сравнить managed artifact set с ожидаемым rendered manifest. Без explicit apply script MUST NOT создавать или изменять workspace artifacts.

#### Scenario: User previews fresh setup

- **WHEN** пользователь запускает dry-run для workspace без Lexi artifacts
- **THEN** output SHALL перечислить все planned created artifacts
- **AND** filesystem SHALL остаться byte-for-byte неизменной

#### Scenario: User checks configured workspace

- **WHEN** пользователь запускает integrity check после successful setup
- **THEN** check SHALL подтвердить expected manifest и content hashes
- **AND** SHALL проверить skill/reference contract consistency
- **AND** SHALL завершиться без mutation

### Requirement: ERL-AGENT-SETUP-005 — Apply is idempotent and conflict-safe

Повторный apply того же rendered payload MUST быть idempotent. Existing managed file с expected content MUST быть сохранён без rewrite.

Если target file существует с отличающимся content, default apply MUST завершиться conflict и MUST NOT перезаписывать его. Replacement MUST требовать отдельного explicit consent, создавать recoverable backup и MUST NOT удалять unknown files внутри `skills/` или других target directories.

#### Scenario: Same payload is applied again

- **GIVEN** workspace уже соответствует rendered manifest
- **WHEN** тот же setup apply запускается повторно
- **THEN** все managed artifacts SHALL быть classified as keep
- **AND** их bytes и modification times SHALL NOT изменяться

#### Scenario: Existing USER file differs

- **GIVEN** `USER.md` содержит local edits
- **WHEN** default apply обнаруживает отличие от rendered payload
- **THEN** operation SHALL сообщить conflict
- **AND** `USER.md` SHALL остаться неизменным
- **AND** другие planned mutations SHALL NOT быть partially committed

### Requirement: ERL-AGENT-SETUP-006 — Apply is recoverable and publishes completion last

Setup apply MUST materialize and validate candidate artifacts до публикации completed workspace state. Mutation existing targets MUST иметь backups и journal, достаточные для восстановления exact pre-apply bytes.

При failure операция MUST восстановить pre-apply state либо оставить явный recoverable status. `openclaw-workspace-state.json` MUST отмечать successful completion только после commit и post-apply validation всех остальных managed artifacts.

#### Scenario: Apply fails during skill materialization

- **GIVEN** apply уже подготовил часть candidate payload
- **WHEN** дальнейшая запись или validation завершается ошибкой
- **THEN** target workspace SHALL быть rolled back к pre-apply state либо помечен recovery-required
- **AND** completed workspace state SHALL NOT быть опубликован

### Requirement: ERL-AGENT-SETUP-007 — Local materialization remains ignored and verifiable

Materialized Lexi artifacts MUST оставаться local ignored infrastructure. Setup MUST NOT требовать `git add -f` и MUST NOT превращать generated copies в tracked source files.

Post-apply validation MUST проверять, что managed paths остаются ignored, отсутствуют distribution artifacts вроде `.DS_Store` и `.openclaw-install-backups`, skills проходят ERL packaging checks, а Lexi tool/safety policy соответствует agent contract.

#### Scenario: Setup completes in a clean checkout

- **WHEN** post-apply validation успешно завершается
- **THEN** managed generated artifacts SHALL быть ignored Git rules
- **AND** `git status --short` SHALL NOT показывать их как untracked files
- **AND** prohibited distribution artifacts SHALL отсутствовать

### Requirement: ERL-AGENT-SETUP-008 — Embedded skill payload matches the reference Lexi skills

Текущий полный набор семи Lexi runtime skills в настроенном reference workspace MUST быть эталоном содержимого skills для embedded setup payload. Development validation MUST сравнивать извлечённое из setup payload дерево `skills/` с reference Lexi skills по точному набору relative file paths и byte-exact content каждого file.

Расхождение, отсутствующий или лишний file, reference symlink либо отличие bytes MUST завершать validation с конкретной drift diagnostic и MUST блокировать признание payload актуальным, завершение Change и archive. Отсутствие reference `skills/` в fresh checkout MUST NOT мешать runtime dry-run, apply или check: reference comparison является development-time synchronization gate, а self-contained embedded payload остаётся deployment source of truth.

#### Scenario: Embedded payload matches current reference skills

- **GIVEN** доступны текущие reference Lexi skills
- **WHEN** development payload synchronization check извлекает embedded skills
- **THEN** exact relative file set SHALL совпадать для всех семи skills и required references
- **AND** bytes каждого corresponding file SHALL совпадать
- **AND** synchronization check SHALL успешно завершиться

#### Scenario: Reference skill changes after payload generation

- **GIVEN** file текущего reference Lexi skill был добавлен, удалён или изменён после формирования embedded payload
- **WHEN** development payload synchronization check запускается повторно
- **THEN** check SHALL завершиться ошибкой
- **AND** diagnostic SHALL назвать drifted relative path и тип расхождения
- **AND** Change completion и archive SHALL оставаться заблокированными до явного обновления payload и повторной успешной проверки

#### Scenario: Fresh checkout has no reference skills directory

- **GIVEN** fresh checkout не содержит materialized `skills/`
- **WHEN** пользователь запускает setup dry-run, apply или integrity check
- **THEN** setup SHALL использовать self-contained embedded payload без reference directory
- **AND** runtime operation SHALL NOT завершаться ошибкой только из-за отсутствия development reference skills

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

### Requirement: ERL-AGENT-SETUP-012 — Setup materializes and repairs the Lexi root binding

Lexi setup MUST принимать или детерминированно разрешать local `ERL_HOME` и `ERL_HOST_HOME`, показывать оба effective canonical paths в dry-run и записывать согласованный local runtime contract только после explicit apply.

Для текущего deployment rendered configuration MUST задавать:

```text
ERL_HOME=/Users/steamtoad/pub/english-reading-lab
ERL_HOST_HOME=/Users/steamtoad/dev/zettelkasten-cli
```

Setup check MUST проверять generated `TOOLS.md`, common skill contract, семь reference copies, embedded payload и effective target-home host contract. Ни один из них MUST NOT назначать `/Users/steamtoad/zettelkasten` как Lexi Vault или ERL host root.

Если существующий `.state/erl/host-contract.json` содержит stale либо forbidden `host_root`, default dry-run/check MUST сообщить conflict без mutation. Replacement MUST требовать explicit apply/replacement consent, сохранить recoverable byte-exact backup, опубликовать новый contract атомарно и выполнить post-check. Failure MUST восстановить pre-apply bytes либо оставить явный recovery-required journal.

#### Scenario: Clean setup renders the required paths

- **GIVEN** setup выполняется для текущего Lexi deployment без local managed configuration
- **WHEN** пользователь запускает dry-run, затем explicit apply
- **THEN** dry-run SHALL показать оба exact effective roots
- **AND** apply SHALL materialize target Vault binding `/Users/steamtoad/pub/english-reading-lab`
- **AND** apply SHALL materialize host implementation binding `/Users/steamtoad/dev/zettelkasten-cli`

#### Scenario: Existing host contract points to the user Vault

- **GIVEN** `.state/erl/host-contract.json` содержит `host_root: /Users/steamtoad/zettelkasten`
- **WHEN** setup выполняет default dry-run или check
- **THEN** setup SHALL сообщить forbidden stale-host-root conflict
- **AND** файл SHALL остаться byte-for-byte неизменным

#### Scenario: User explicitly replaces the stale host contract

- **GIVEN** пользователь просмотрел plan замены stale host contract
- **WHEN** пользователь отдельно подтверждает replacement apply
- **THEN** setup SHALL создать recoverable backup исходного contract
- **AND** новый effective `host_root` SHALL быть `/Users/steamtoad/dev/zettelkasten-cli`
- **AND** post-check SHALL подтвердить root separation и полный managed payload

#### Scenario: Root-binding replacement fails

- **GIVEN** replacement apply начал обновление local root binding
- **WHEN** write, validation или publication завершается ошибкой
- **THEN** setup SHALL восстановить exact pre-apply configuration либо опубликовать recovery-required journal
- **AND** completed setup state SHALL NOT сообщать успешную новую конфигурацию

#### Scenario: Reference or payload reintroduces the user Vault

- **GIVEN** skill reference, `TOOLS.md` template либо embedded payload назначает `/Users/steamtoad/zettelkasten` target или host root
- **WHEN** development synchronization validation запускается
- **THEN** validation SHALL завершиться ошибкой с именем drifted artifact
- **AND** completion и archive Change SHALL оставаться заблокированными

### Requirement: ERL-AGENT-SETUP-010 — Mutation confirmation binds the exact Vault

Перед каждым L2 или L3 `--apply` Lexi MUST показать пользователю план, содержащий absolute canonical path фактического target Vault в отдельном поле `Vault`, и MUST дождаться отдельного явного подтверждения уже показанного плана. Для Lexi это поле MUST иметь resolved значение `${ERL_HOME}`.

После получения подтверждения и непосредственно перед mutation Lexi MUST повторно разрешить и проверить target Vault. Apply разрешён только если повторно полученный canonical path byte-for-byte совпадает с Vault подтверждённого плана, repository markers и target-home layout по-прежнему действительны, а применяемый plan относится к тому же Vault.

Если path, identity, markers или plan изменились, Lexi MUST отменить прежнее подтверждение, MUST NOT запускать `--apply` и MUST сформировать новый dry-run plan, который требует нового явного подтверждения.

#### Scenario: User confirms a Book ingest plan for the Lexi Vault

- **GIVEN** Book ingest dry-run разрешил `${ERL_HOME}` как `/Users/steamtoad/pub/english-reading-lab`
- **WHEN** Lexi запрашивает L2 confirmation
- **THEN** показанный план SHALL содержать `Vault: /Users/steamtoad/pub/english-reading-lab`
- **AND** Lexi SHALL NOT запускать `--apply` до отдельного явного подтверждения этого плана

#### Scenario: Vault remains unchanged after confirmation

- **GIVEN** пользователь явно подтвердил план с определённым absolute Vault path
- **WHEN** Lexi готовится выполнить `--apply`
- **THEN** Lexi SHALL повторно разрешить и проверить target Vault
- **AND** invocation SHALL использовать тот же canonical path через `--vault "${ERL_HOME}"`

#### Scenario: Vault changes after confirmation

- **GIVEN** пользователь подтвердил план для одного Vault
- **WHEN** pre-apply revalidation получает другой path, изменённую identity, недействительные markers либо plan другого Vault
- **THEN** Lexi SHALL NOT выполнять mutation
- **AND** прежнее подтверждение SHALL считаться недействительным
- **AND** новый dry-run plan SHALL требовать нового явного подтверждения

### Requirement: ERL-AGENT-SETUP-011 — Post-mutation validation and report use the confirmed Vault

После успешного mutation Lexi MUST запустить canonical `${ERL_HOME}/.scripts/erl/erl-check.zsh` с exact `--vault "${ERL_HOME}"` и наиболее широким изменённым semantic scope. Для Book workflow с известным `WORK_ID` invocation MUST содержать `--work "${WORK_ID}" --json`.

Lexi MUST сверить, что проверяемый Vault совпадает с Vault подтверждённого и применённого plan. Итоговый отчёт MUST явно содержать absolute фактический Vault, validation scope и результат `erl-check`. Lexi MUST NOT сообщать об успешной материализации, если post-check не был выполнен для того же Vault, завершился ошибкой либо обнаружил несоответствие scope.

#### Scenario: Book ingest is checked in the same Vault

- **GIVEN** Book ingest был применён к `${ERL_HOME}` и вернул `WORK_ID`
- **WHEN** Lexi выполняет post-mutation validation
- **THEN** invocation SHALL быть эквивалентен `${ERL_HOME}/.scripts/erl/erl-check.zsh --vault "${ERL_HOME}" --work "${WORK_ID}" --json`
- **AND** Lexi SHALL проверить, что `${ERL_HOME}` совпадает с Vault подтверждённого plan

#### Scenario: Final success report identifies the actual Vault

- **GIVEN** mutation и post-check того же Vault успешно завершились
- **WHEN** Lexi формирует итоговый отчёт
- **THEN** отчёт SHALL содержать absolute фактический Vault
- **AND** отчёт SHALL содержать проверенный `WORK_ID` или иной validation scope
- **AND** отчёт SHALL содержать результат `erl-check`

#### Scenario: Post-check targets another Vault

- **GIVEN** mutation была применена к подтверждённому Vault
- **WHEN** post-check настроен на другой Vault либо не может доказать identity проверяемого Vault
- **THEN** Lexi SHALL NOT сообщать об успешном завершении
- **AND** SHALL сообщить validation failure с обоими известными paths без автоматической повторной mutation
