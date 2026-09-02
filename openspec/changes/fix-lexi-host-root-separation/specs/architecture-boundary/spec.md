## ADDED Requirements

### Requirement: ERL-ARCH-010 — Lexi target, host implementation and user Vault roles are disjoint

В текущем Lexi deployment target Vault и host implementation root MUST быть разными absolute canonical filesystem roots со следующими effective values:

- `ERL_HOME=/Users/steamtoad/pub/english-reading-lab` MUST обозначать workspace repository и target Vault, содержащий `notes/` и `.state/erl/`;
- `ERL_HOST_HOME=/Users/steamtoad/dev/zettelkasten-cli` MUST обозначать host implementation, предоставляющую `.scripts/objects/`;
- `/Users/steamtoad/zettelkasten` MUST считаться отдельным пользовательским Vault и MUST NOT разрешаться как Lexi `ERL_HOME`, `--vault`, `ERL_HOST_HOME` или `host_root`.

ERL operation MUST проверять role-specific markers и MUST завершаться до mutation, если roots совпадают, поменяны ролями, указывают на запрещённый пользовательский Vault либо не соответствуют назначенной роли. Наличие user Vault MUST NOT влиять на root resolution.

Для других deployments explicit local configuration MAY задавать другие absolute paths, но MUST сохранять такое же разделение ролей и MUST NOT использовать пользовательский Vault как host implementation root Lexi.

#### Scenario: Lexi resolves the supported three-root layout

- **GIVEN** Lexi работает в `/Users/steamtoad/pub/english-reading-lab`
- **WHEN** operation разрешает target Vault и canonical object constructors
- **THEN** `--vault` SHALL получить `/Users/steamtoad/pub/english-reading-lab`
- **AND** object constructors SHALL разрешаться из `/Users/steamtoad/dev/zettelkasten-cli/.scripts/objects/`
- **AND** `/Users/steamtoad/zettelkasten` SHALL не участвовать в resolution

#### Scenario: User Vault is configured as host root

- **GIVEN** effective `ERL_HOST_HOME` либо target-home `host_root` равен `/Users/steamtoad/zettelkasten`
- **WHEN** Lexi выполняет preflight ERL operation
- **THEN** operation SHALL завершиться до mutation с diagnostic forbidden-root error
- **AND** SHALL NOT искать или запускать object constructor из запрещённого root

#### Scenario: Target and host roots collapse into one role

- **GIVEN** canonical target Vault и host implementation root совпали либо были поменяны ролями
- **WHEN** Lexi проверяет runtime layout
- **THEN** validation SHALL завершиться role-conflict error
- **AND** ни Vault documents, ни persistent ERL state SHALL не изменяться

#### Scenario: Another deployment uses different paths

- **GIVEN** ERL развёрнут на другой машине с explicit target, host implementation и user Vault roots
- **WHEN** local configuration проходит validation
- **THEN** target и host roots SHALL быть absolute, canonical, различными и соответствовать role-specific markers
- **AND** user Vault SHALL оставаться вне Lexi target/host roles
