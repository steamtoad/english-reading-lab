## Purpose

Определить воспроизводимый, проверяемый и безопасный bootstrap локального OpenClaw workspace для специализированного ERL runtime agent Lexi.

## ADDED Requirements

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

