## Purpose

Определить readiness, synchronization, preservation и source-of-truth правила архивирования OpenSpec changes English Reading Lab.

## ADDED Requirements

### Requirement: OS-ARCHIVE-001 — Archive only completed and verified changes

Change MAY быть archived только после полного завершения implementation, verification и specification validation. Archive workflow MUST отклонять Change, пока хотя бы одно из этих условий не выполнено.

#### Scenario: Incomplete change is submitted for archival

- **GIVEN** implementation, verification или specification validation Change не завершены
- **WHEN** запрашивается archival
- **THEN** archival SHALL быть отклонён

### Requirement: OS-ARCHIVE-002 — Delta specifications are synchronized before archival completes

До завершения archival все applicable delta specifications SHALL быть синхронизированы в canonical specifications под `openspec/specs/`.

#### Scenario: Applicable delta is not synchronized

- **GIVEN** Change содержит applicable delta specification, отсутствующую в canonical specs
- **WHEN** archive workflow достигает finalization
- **THEN** finalization SHALL быть заблокирован до синхронизации и validation canonical specs

### Requirement: OS-ARCHIVE-003 — Complete Change is preserved in archive

Полный Change, включая delta specifications, proposal, design и tasks, SHALL сохраняться в `openspec/changes/archive/`.

#### Scenario: Change archival completes

- **WHEN** Change успешно archived
- **THEN** archive SHALL содержать proposal, design, tasks и все applicable delta specifications

### Requirement: OS-ARCHIVE-004 — Archived deltas are historical records

Archived delta specifications SHALL считаться historical records и SHALL NOT использоваться как current source of truth.

#### Scenario: Current requirement is resolved

- **GIVEN** archived delta и canonical specification описывают requirement
- **WHEN** определяется текущее нормативное поведение
- **THEN** archived delta SHALL использоваться только для historical context

### Requirement: OS-ARCHIVE-005 — Canonical specs remain current source of truth

`openspec/specs/` SHALL оставаться source of truth текущих system requirements.

#### Scenario: Consumer loads current requirements

- **WHEN** tooling или development workflow загружает текущий requirements baseline
- **THEN** baseline SHALL разрешаться из `openspec/specs/`
- **AND** active или archived change artifacts SHALL NOT заменять canonical baseline
