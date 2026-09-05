## Why

Lexi разрешает ERL repository через `ERL_HOME`, но её текущий нормативный контракт не определяет однозначно target Vault для CLI invocation. Из-за этого агент может выбрать пользовательский Zettelkasten checkout и создать Book, Chapters и persistent work state вне изолированного ERL workspace.

## What Changes

- Обязать каждый из семи Lexi runtime skills передавать `--vault "${ERL_HOME}"` каждому вызываемому ERL command.
- Определить resolved `ERL_HOME` одновременно как Lexi repository root и canonical target Zettelkasten home с root `notes/` и `.state/erl/`.
- Запретить skills подменять target Vault пользовательским Zettelkasten checkout, home directory, parent path или nested `vault/`.
- Сохранить отдельное разрешение host object constructors через target-home host contract либо `ERL_HOST_HOME`; host root не становится target Vault.
- Добавить deterministic validation всех семи skills, generated `TOOLS.md` и embedded setup payload.

## Capabilities

### New Capabilities

Нет.

### Modified Capabilities

- `agent-environment-setup`: materialized Lexi skills и local tooling contract получают обязательную привязку `--vault` к resolved `ERL_HOME`.

## Impact

Изменение затрагивает derived agent contract, семь reference copies, skill packaging checker, OpenClaw setup payload, `TOOLS.md` rendering и regression tests. Public ERL CLI продолжает принимать любой explicit `--vault`; новое правило относится только к Lexi runtime orchestration.

Для существующего Lexi workspace потребуется повторная materialization setup payload с backup/conflict workflow. Существующие документы и state в прежнем Vault автоматически не переносятся и не изменяются; destructive operations и data migration отсутствуют. Host core не изменяется: ERL workspace может использовать отдельный configured host root только для canonical object constructors.
