# classic-reduce-integration Specification

## Purpose

Определить contract интеграции Classic `zt-reduce` с English Reading Lab: поддерживаемое применение host Reduce к ERL-used Topics, границу ответственности Classic workflow, external generation closure, `CLOSURE_REQUIRED`, reconciliation diagnostics и explicit successor adoption.

## Requirements

### Requirement: ERL-CLASSIC-REDUCE-001 — Classic Reduce is supported for ERL-used Topics

ERL MUST поддерживать применение Classic `zt-reduce` к active canonical Topic, созданной или используемой ERL.

Seed Classic Reduce MUST быть Topic. Отдельные Memo или Note MUST NOT являться seed Classic Reduce.

#### Scenario: ERL-used Topic is reduced by Classic workflow

- **GIVEN** active canonical Topic создана или используется ERL
- **WHEN** пользователь применяет к ней Classic `zt-reduce`
- **THEN** такой host workflow SHALL считаться supported
- **AND** seed SHALL быть Topic
- **AND** отдельные Memo или Note SHALL NOT использоваться как seed Classic Reduce

### Requirement: ERL-CLASSIC-REDUCE-002 — Classic workflow remains unaware of ERL lifecycle

ERL MUST NOT требовать от Classic workflow обнаруживать ERL roles, читать `.state/erl/works/` или знать о ERL lifecycle.

#### Scenario: Classic Reduce operates without ERL-specific knowledge

- **GIVEN** Topic используется ERL
- **WHEN** Classic `zt-reduce` выполняет host Reduce
- **THEN** workflow SHALL NOT требовать обнаружения ERL roles
- **AND** SHALL NOT требовать чтения `.state/erl/works/`
- **AND** SHALL NOT требовать знания ERL lifecycle

### Requirement: ERL-CLASSIC-REDUCE-003 — Classic Reduce preserves host semantics

Для supported integration ERL MUST принимать host semantics Classic `zt-reduce`: successor Topic сохраняет `:key-topic:`, исходная Topic и active Memo с совпадающим `:key-topic:` deprecate, а active Note не deprecate.

#### Scenario: Classic host semantics are applied

- **GIVEN** Classic `zt-reduce` выполняется для Topic с `:key-topic:`
- **WHEN** host Reduce успешно завершён
- **THEN** successor Topic SHALL иметь тот же `:key-topic:`
- **AND** исходная Topic SHALL быть deprecated
- **AND** active Memo с совпадающим `:key-topic:` SHALL быть deprecated
- **AND** active Note SHALL NOT быть deprecated только вследствие Classic Reduce

### Requirement: ERL-CLASSIC-REDUCE-004 — Classic successor is not adopted implicitly

Classic successor Topic MUST NOT автоматически становиться ERL Book generation и MUST оставаться Classic Topic до explicit ERL adoption или migration.

#### Scenario: Classic Reduce creates a successor Topic

- **WHEN** Classic `zt-reduce` создаёт successor Topic для ERL-used Topic
- **THEN** successor SHALL NOT автоматически считаться ERL Book generation
- **AND** SHALL оставаться Classic Topic до explicit ERL adoption или migration

### Requirement: ERL-CLASSIC-REDUCE-005 — Registered Book Topic is closed externally through reconciliation

Если Classic Reduce deprecated зарегистрированную Book Topic, explicit reconciliation MUST перевести generation в `GENERATION_CLOSED_EXTERNALLY`, очистить соответствующий active-generation pointer и сохранить historical membership.

Новые processing operations для такой закрытой generation MUST быть запрещены.

#### Scenario: Deprecated registered Book Topic is reconciled

- **GIVEN** Classic Reduce deprecated зарегистрированную Book Topic
- **WHEN** `erl-classic-reduce-reconcile` применяет reconciliation
- **THEN** generation SHALL получить status `GENERATION_CLOSED_EXTERNALLY`
- **AND** active-generation pointer SHALL быть очищен, если он указывает на эту generation
- **AND** historical membership SHALL быть сохранено
- **AND** новые processing operations для закрытой generation SHALL быть запрещены

### Requirement: ERL-CLASSIC-REDUCE-006 — Deprecated Vocabulary with active Occurrences requires closure

Если Classic Topic Reduce deprecates Vocabulary Memo с active Occurrence dependants, ERL MUST классифицировать состояние как `CLOSURE_REQUIRED`.

#### Scenario: Classic Reduce deprecates referenced Vocabulary

- **GIVEN** Classic Topic Reduce deprecated Vocabulary Memo
- **AND** active Occurrence зависит от этого Vocabulary
- **WHEN** ERL анализирует resulting state
- **THEN** состояние SHALL быть классифицировано как `CLOSURE_REQUIRED`

### Requirement: ERL-CLASSIC-REDUCE-007 — New hard dependencies are blocked until closure

До завершения требуемого closure ERL MUST NOT создавать новые hard dependencies на deprecated target.

#### Scenario: Required closure is still unresolved

- **GIVEN** состояние имеет unresolved `CLOSURE_REQUIRED`
- **AND** target уже deprecated
- **WHEN** ERL готовит создание новой relation
- **THEN** новая hard dependency на deprecated target SHALL NOT быть создана

### Requirement: ERL-CLASSIC-REDUCE-008 — Classic Reduce itself is not a validation error

Сам факт Classic Reduce ERL-used Topic MUST NOT считаться validation error.

Незавершённая reconciliation MUST представляться как диагностируемый status.

#### Scenario: ERL-used Topic was reduced externally

- **GIVEN** ERL-used Topic была обработана supported Classic Reduce
- **WHEN** ERL выполняет validation
- **THEN** сам факт Classic Reduce SHALL NOT считаться validation error
- **AND** незавершённая reconciliation SHALL представляться диагностируемым status

### Requirement: ERL-CLASSIC-REDUCE-009 — erl-check detects Classic Reduce reconciliation conditions

`erl-check` MUST обнаруживать externally closed Book Topic, незарегистрированную Classic successor Topic и deprecated Vocabulary с active dependants.

#### Scenario: Externally closed Book Topic is detected

- **GIVEN** registered Book Topic была deprecated Classic Reduce
- **WHEN** выполняется `erl-check`
- **THEN** externally closed Book Topic SHALL быть обнаружена

#### Scenario: Unregistered Classic successor is detected

- **GIVEN** Classic Reduce создал successor Topic
- **AND** successor не зарегистрирован как ERL Book generation
- **WHEN** выполняется `erl-check`
- **THEN** незарегистрированный Classic successor SHALL быть обнаружен

#### Scenario: Deprecated Vocabulary with active dependants is detected

- **GIVEN** Vocabulary deprecated
- **AND** Vocabulary имеет active dependants
- **WHEN** выполняется `erl-check`
- **THEN** deprecated Vocabulary с active dependants SHALL быть обнаружен

### Requirement: ERL-CLASSIC-REDUCE-010 — Explicit successor adoption creates a new generation

Explicit adoption Classic successor MUST создавать новую generation state запись с тем же `WORK_ID`.

Adoption MUST допускаться только при отсутствии другой active Book generation того же `WORK_ID`.

#### Scenario: Successor is explicitly adopted

- **GIVEN** compatible Classic successor Topic выбран для adoption
- **AND** у `WORK_ID` нет другой active Book generation
- **WHEN** выполняется explicit successor adoption
- **THEN** новая generation state запись SHALL быть создана
- **AND** `WORK_ID` SHALL остаться прежним
- **AND** successor SHALL стать active Book generation этого work

#### Scenario: Work already has another active generation

- **GIVEN** у того же `WORK_ID` существует другая active Book generation
- **WHEN** запрашивается explicit adoption Classic successor
- **THEN** adoption SHALL быть запрещена

### Requirement: ERL-CLASSIC-REDUCE-011 — Reconciliation is explicit, deterministic and dry-runnable

`erl-classic-reduce-reconcile` MUST быть explicit deterministic operation для записи `GENERATION_CLOSED_EXTERNALLY` и optional adoption Classic successor.

Операция MUST поддерживать read-only dry-run и MUST NOT изменять state без explicit apply.

#### Scenario: Reconciliation runs as dry-run

- **GIVEN** Classic Reduce deprecated зарегистрированную Book Topic
- **WHEN** `erl-classic-reduce-reconcile` выполняется в dry-run mode
- **THEN** операция SHALL показать старую Topic
- **AND** SHALL показать найденный successor, если он обнаружен
- **AND** SHALL показать planned work-state changes
- **AND** SHALL показать blockers
- **AND** SHALL NOT изменять persistent state

#### Scenario: Reconciliation is explicitly applied

- **GIVEN** reconciliation plan не имеет blockers
- **WHEN** пользователь выполняет explicit apply
- **THEN** operation SHALL записать `GENERATION_CLOSED_EXTERNALLY`
- **AND** SHALL выполнить optional successor adoption только если она была явно запрошена
