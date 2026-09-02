## Why

Lexi target Vault и canonical host implementation сейчас могут разрешаться через один пользовательский Zettelkasten checkout; локальный `.state/erl/host-contract.json` фактически задаёт `/Users/steamtoad/zettelkasten` как `host_root`. Это смешивает user data с ERL runtime и позволяет повторно направить документы либо object-constructor lookup в неправильный filesystem root.

## What Changes

- Зафиксировать для текущего Lexi deployment независимые absolute roots:
  - `ERL_HOME=/Users/steamtoad/pub/english-reading-lab` как единственный target Vault;
  - `ERL_HOST_HOME=/Users/steamtoad/dev/zettelkasten-cli` как единственный host implementation root для object constructors.
- **BREAKING**: запретить `/Users/steamtoad/zettelkasten` как Lexi `--vault`, `ERL_HOME`, `ERL_HOST_HOME` или `host_root` ERL host contract.
- Обязать setup/check валидировать разные root identities, обязательные markers и отсутствие запрещённого пользовательского checkout в effective configuration.
- Добавить безопасную замену неправильного local host contract с dry-run, explicit apply, backup, post-check и rollback/recovery.
- Сохранить user Zettelkasten полностью read-only и вне migration scope.

## Capabilities

### New Capabilities

Нет.

### Modified Capabilities

- `architecture-boundary`: уточнить независимость target Vault, host implementation и user Zettelkasten для Lexi deployment и запретить role substitution.
- `agent-environment-setup`: setup должен материализовать и проверять exact local `ERL_HOME`/`ERL_HOST_HOME` binding и исправлять stale host contract только через recoverable explicit apply.

## Impact

Изменение затрагивает ERL host-root resolution/preflight, Lexi setup payload и rendered local configuration, семь runtime skills/common references, `TOOLS.md`, runtime documentation и regression fixtures. Existing local `.state/erl/host-contract.json` требует reviewed replacement.

Public CLI для других deployments сохраняет portable explicit configuration; exact absolute paths являются machine profile текущего Lexi deployment, а не repository-wide fallback. Host core и `/Users/steamtoad/zettelkasten` не изменяются. Автоматический перенос Vault documents/state отсутствует.
