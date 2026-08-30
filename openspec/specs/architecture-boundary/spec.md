# architecture-boundary Specification

## Purpose

Определить архитектурную и repository boundary English Reading Lab относительно Zettelkasten Vault и Classic Zettelkasten: допустимые dependency directions, ответственность слоёв, границы изменений и порядок обработки host contract gaps.

## Requirements

### Requirement: ERL-ARCH-001 — ERL is a separate domain layer

English Reading Lab MUST быть отдельным domain layer/plugin над Zettelkasten Vault.

#### Scenario: ERL functionality is classified architecturally

- **WHEN** новая ERL functionality проектируется или реализуется
- **THEN** она SHALL рассматриваться как часть отдельного ERL domain layer/plugin
- **AND** canonical Zettelkasten Vault SHALL оставаться host storage/object layer

### Requirement: ERL-ARCH-002 — ERL is separate from Classic Zettelkasten workflow

ERL MUST NOT рассматриваться как часть Classic Zettelkasten workflow.

#### Scenario: ERL workflow is introduced

- **WHEN** ERL вводит новый domain workflow
- **THEN** этот workflow SHALL оставаться отдельным от Classic Zettelkasten workflow
- **AND** Classic workflow SHALL NOT получать ERL-specific semantics как обязательную часть своего contract

### Requirement: ERL-ARCH-003 — Runtime dependency direction

ERL runtime dependencies MUST соблюдать направление:

`ERL -> objects -> lib`

и MAY использовать:

`ERL -> lib`.

`objects/` и `lib/` в этой dependency model являются host-provided
runtime contracts и MUST NOT подразумевать repository ownership этих
components со стороны ERL.

#### Scenario: Runtime dependency is added

- **WHEN** ERL implementation добавляет runtime dependency
- **THEN** dependency MAY направляться из ERL в host-provided canonical `objects/` или domain-neutral `lib/`
- **AND** canonical object layer MAY зависеть от `lib/`
- **AND** dependency SHALL NOT обращать это направление в сторону ERL
- **AND** наличие runtime dependency SHALL NOT требовать хранения production implementation этой dependency в ERL repository

### Requirement: ERL-ARCH-004 — No Classic implementation API dependency

ERL MUST NOT зависеть от `.scripts/zettelkasten/` как от implementation API и MUST NOT использовать `zcreate` как plugin object API.

#### Scenario: ERL needs to create or manipulate a canonical Vault object

- **WHEN** ERL implementation требуется canonical object operation
- **THEN** она SHALL использовать допустимый canonical object/lib contract
- **AND** она SHALL NOT source implementation из `.scripts/zettelkasten/`
- **AND** она SHALL NOT вызывать `zcreate` как ERL implementation API

### Requirement: ERL-ARCH-005 — Canonical host commands may remain user workflows

ERL MAY использовать canonical host commands, включая Classic `zt-reduce`, как поддерживаемые пользовательские host-level workflows над ERL documents.

Такое использование MUST NOT превращать implementation этих commands в ERL runtime dependency.

#### Scenario: User applies a supported Classic command to ERL-used documents

- **WHEN** пользователь применяет поддерживаемый canonical host command к ERL-used Vault documents
- **THEN** ERL MAY поддерживать последствия этого host workflow
- **BUT** ERL implementation SHALL NOT source или зависеть от implementation Classic command как от plugin API

### Requirement: ERL-ARCH-006 — Layer responsibilities

ERL layers MUST сохранять разделение ответственности:

- Skill выполняет semantic decisions и orchestration.
- `.scripts/erl/` реализует deterministic ERL domain operations.
- Host `.scripts/objects/` предоставляет canonical Topic, Note и Memo construction.
- Host `.scripts/lib/` предоставляет domain-neutral primitives.

#### Scenario: New functionality is assigned to a layer

- **WHEN** новая ERL functionality проектируется
- **THEN** semantic reasoning и orchestration SHALL размещаться на skill layer
- **AND** deterministic ERL mutation/validation SHALL размещаться в ERL domain tooling
- **AND** canonical Vault object construction SHALL оставаться в host-owned canonical object layer
- **AND** reusable host domain-neutral primitives SHALL оставаться в host-owned library layer

### Requirement: ERL-ARCH-007 — ERL is developed in its own repository

ERL MUST разрабатываться в отдельном repository.

Обычная ERL implementation task MUST NOT изменять host Zettelkasten repository.

#### Scenario: Implementation agent performs an ordinary ERL task

- **WHEN** Marta или другой implementation agent выполняет обычную ERL development task
- **THEN** изменения SHALL ограничиваться ERL repository
- **AND** host Zettelkasten repository SHALL оставаться неизменённым

### Requirement: ERL-ARCH-008 — Host contract gaps are explicit

Если существующего host contract недостаточно для требуемого ERL behavior, ERL MUST зафиксировать explicit contract gap и MUST NOT автоматически патчить host core.

#### Scenario: Required host capability is unavailable

- **GIVEN** ERL change требует capability, отсутствующей в существующем host contract
- **WHEN** implementation достигает этой архитектурной границы
- **THEN** deficiency SHALL быть зафиксирована как host contract gap
- **AND** ERL SHALL NOT автоматически изменять host core
- **AND** host contract change SHALL требовать отдельного решения

### Requirement: ERL-ARCH-009 — ERL source and host source are independent

ERL source location MUST быть независима от source location целевого
Zettelkasten host/Vault.

ERL executables MUST NOT требовать, чтобы production host core
implementation находилась внутри ERL repository или `ERL_HOME`.

Canonical host operations MUST разрешаться через host contract,
предоставляемый целевым Zettelkasten host/Vault, а не через
repository-relative production copies внутри ERL source tree.

#### Scenario: ERL and host use different filesystem roots

- **GIVEN** ERL repository и целевой Zettelkasten host/Vault находятся в разных filesystem roots
- **WHEN** ERL operation требует canonical host object или library operation
- **THEN** operation SHALL использовать host contract, предоставляемый целевым host/Vault
- **AND** operation SHALL NOT требовать `.scripts/objects/`, `.scripts/lib/` или `.scripts/zettelkasten/` внутри ERL repository
- **AND** различие ERL repository root и host/Vault root SHALL считаться нормальной поддерживаемой конфигурацией

#### Scenario: Required host contract is unavailable

- **GIVEN** целевой host/Vault не предоставляет обязательную часть host contract
- **WHEN** ERL пытается выполнить operation, зависящую от этой capability
- **THEN** ERL SHALL завершить operation с явной diagnostic error
- **AND** ERL SHALL NOT silently fallback к bundled, vendored или repository-relative production copy host implementation
- **AND** deficiency SHALL обрабатываться согласно `ERL-ARCH-008`

### Requirement: ERL-REPO-001 — ERL repository ownership

ERL repository MUST владеть только ERL plugin code, skills, tests, fixtures, documentation и ERL-local data contracts.

#### Scenario: New repository artifact is introduced

- **WHEN** новый artifact добавляется в ERL repository
- **THEN** artifact SHALL относиться к ERL plugin implementation, skills, tests, fixtures, documentation или ERL-local data contracts
- **AND** repository SHALL NOT становиться владельцем host core implementation

### Requirement: ERL-REPO-002 — Implementation agents respect host write boundary

Marta и другие implementation agents MUST NOT изменять host `.scripts/lib/`, `.scripts/objects/`, `.scripts/zettelkasten/`, `zcreate`, `zt-check` или пользовательские Vault documents как часть обычной ERL development task.

#### Scenario: Agent encounters code outside ERL write boundary

- **WHEN** implementation agent обнаруживает необходимость изменения host-owned component или пользовательского Vault document
- **THEN** agent SHALL NOT изменять этот component в рамках обычной ERL task
- **AND** необходимость SHALL быть обработана через отдельный host contract/change decision

### Requirement: ERL-REPO-003 — Host contract changes require separate scope

Изменение host contract MUST требовать отдельного решения и отдельного change scope.

#### Scenario: ERL proposal requires a host contract modification

- **WHEN** proposed ERL behavior невозможно реализовать в рамках существующего host contract
- **THEN** host contract modification SHALL быть выделена в отдельное решение
- **AND** она SHALL NOT быть скрыто включена в обычный ERL implementation scope

### Requirement: ERL-REPO-004 — Plugin removal preserves host workflow

Удаление ERL plugin MUST NOT ломать Classic Zettelkasten workflow, существующие UUID, filenames или internal links.

#### Scenario: ERL plugin is removed

- **GIVEN** Vault содержит canonical documents, которые ранее создавались или использовались ERL
- **WHEN** ERL plugin удаляется
- **THEN** Classic Zettelkasten workflow SHALL оставаться работоспособным
- **AND** существующие canonical UUID SHALL сохранять identity
- **AND** filenames SHALL оставаться действительными
- **AND** canonical internal links SHALL оставаться действительными

### Requirement: ERL-REPO-005 — No committed production host implementation

ERL repository MUST NOT содержать tracked production copies host-owned
implementation.

К host-owned production implementation относятся как минимум:

- `.scripts/lib/`;
- `.scripts/objects/`;
- `.scripts/zettelkasten/`;
- host `zcreate`;
- host `zt-*` implementation;
- иные production components, принадлежащие canonical Zettelkasten host.

ERL repository MAY содержать минимальные test doubles, stubs и fixtures,
реализующие необходимую часть host contract исключительно для ERL tests.

Такие test artifacts MUST быть явно test-scoped и MUST NOT использоваться
как production fallback host implementation.

#### Scenario: Repository ownership is validated

- **WHEN** tracked contents ERL repository проверяются на соответствие architecture boundary
- **THEN** production host implementation SHALL NOT присутствовать среди ERL-owned files
- **AND** ERL production runtime SHALL NOT зависеть от такой repository-local copy

#### Scenario: ERL test needs an isolated host implementation

- **WHEN** ERL contract или unit test требует контролируемую реализацию host contract
- **THEN** test MAY использовать минимальный test double, stub или fixture
- **AND** artifact SHALL быть явно ограничен test scope
- **AND** artifact SHALL NOT считаться canonical host implementation
- **AND** production ERL runtime SHALL NOT использовать его как fallback
