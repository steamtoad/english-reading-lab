## Why

Локальная инфраструктура OpenClaw agent Lexi сейчас существует только в ignored workspace files, поэтому её нельзя воспроизводимо восстановить из ERL repository на новой машине или после очистки workspace. Нужен один versioned setup script, содержащий полный безопасный bootstrap payload и разворачивающий одинаковое agent environment по явной команде.

## What Changes

- Добавить tracked self-contained setup script для OpenClaw Lexi workspace.
- Включить в versioned payload script все текущие agent-owned ignored artifacts: `openclaw-workspace-state.json`, `HEARTBEAT.md`, `IDENTITY.md`, `SOUL.md`, `TOOLS.md`, `USER.md`, полный `skills/` и `.scripts/erl/docs/lexi-agent.md`.
- Параметризовать machine/user-specific значения, включая workspace path, user name и timezone; не включать credentials, tokens, session history или channel bindings.
- Добавить dry-run/check/apply contract, deterministic manifest и content hashes, idempotent повторный запуск, conflict detection, backup и rollback.
- Зафиксировать текущий полный набор Lexi skills как reference payload и блокировать завершение/обновление embedded payload при расхождении file set или bytes с этим эталоном.
- После apply проверять полноту workspace, семь Lexi runtime skills, reference-contract consistency и отсутствие запрещённых capabilities.
- Оставить перечисленные materialized artifacts в `.gitignore`: versioned source of truth находится внутри setup script, локальные копии остаются runtime infrastructure.

## Capabilities

### New Capabilities

- `agent-environment-setup`: воспроизводимое и безопасное развёртывание локального OpenClaw Lexi workspace из self-contained ERL setup script.

### Modified Capabilities

Нет.

## Impact

Будущая реализация добавит ERL-owned setup executable, regression tests и setup documentation; обновит static packaging checks и CLI/developer contract. Скрипт будет писать только перечисленные ignored paths внутри явно выбранного ERL workspace и собственные recovery artifacts. Existing Vault documents, `.state/erl/works/`, Book/Chapter/Vocabulary/Occurrence contracts и host core не затрагиваются.

Для уже настроенного workspace первый apply должен выполнить reconciliation: совпадающие files принять без изменений, отличающиеся — показать как conflicts и не перезаписывать без explicit replace consent. Удаление пользовательских или неизвестных files запрещено. Destructive operations отсутствуют; replacement допускается только после backup. Host-contract gap отсутствует. Глобальная OpenClaw registration/configuration, credentials и external bindings не входят в этот change.
