## Context

OpenSpec разделяет canonical baseline `openspec/specs/`, active changes и archived changes, но ERL пока не фиксирует порядок перехода между ними как проверяемый project contract.

## Goals / Non-Goals

**Goals:**

- определить единый archive readiness gate;
- исключить archival незавершённых или невалидных changes;
- сохранить полный historical record без раздвоения current source of truth.

**Non-Goals:**

- архивировать существующие changes в рамках этой задачи;
- менять runtime ERL;
- удалять или переписывать historical archives.

## Decisions

### 1. Archival является staged operation

Archive workflow сначала проверяет implementation/tasks и verification evidence, затем синхронизирует applicable deltas в canonical specs, повторно валидирует canonical baseline и только после этого перемещает полный Change в `openspec/changes/archive/`.

### 2. Canonical specs имеют единственную текущую authority

Active и archived deltas объясняют изменение, но не заменяют `openspec/specs/`. Consumers текущих требований не должны собирать baseline из archive.

### 3. Полнота archive проверяется структурно

Archive обязан сохранить proposal, все delta specs, design и tasks. Отсутствующий applicable artifact блокирует завершение archival.

## Risks / Trade-offs

- **[OpenSpec CLI синхронизирует и перемещает за одну команду]** → рассматривать command как staged transaction и проверять post-sync canonical validation до признания archival завершённым.
- **[Archived delta расходится с позднейшим baseline]** → это допустимая history; archive не используется как current source of truth.

## Migration Plan

Новые gates применяются ко всем будущим archival operations. Existing archive сохраняется без переписывания; его historical status проверяется новым contract.
