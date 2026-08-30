# engineering-safety Specification

## Purpose

Определить нормативные Git, shell и portability constraints для разработки и выполнения English Reading Lab: безопасную работу с локальными изменениями, отделение миграций persistent state от обычного refactoring, canonical Zsh implementation contract и требования к переносимости shell scripts.

## Requirements

### Requirement: ERL-GIT-001 — Git history and mutation preflight

Git MUST использоваться как основная история source code ERL plugin.

Mass mutation Vault documents или persistent ERL work state MUST выполняться только после проверки применимой working tree policy.

#### Scenario: ERL prepares a mass mutation

- **GIVEN** ERL operation собирается изменить несколько Vault documents или persistent work-state files
- **WHEN** операция выполняет mutation preflight
- **THEN** она SHALL проверить применимую Git/worktree policy до первой mutation
- **AND** операция SHALL NOT начинать mass mutation, если preflight запрещает продолжение

### Requirement: ERL-GIT-002 — Local changes must not be destroyed

ERL tooling and development workflows MUST NOT выполнять destructive Git reset или иным образом уничтожать существующие локальные изменения пользователя.

#### Scenario: Working tree contains local changes

- **GIVEN** Git working tree содержит локальные изменения
- **WHEN** ERL tooling или development workflow выполняет Git-related operation
- **THEN** существующие локальные изменения SHALL NOT уничтожаться
- **AND** tooling SHALL NOT выполнять destructive reset как способ очистки working tree

### Requirement: ERL-GIT-003 — Persistent-state migration is separate from refactoring

Изменение schema `.state/erl/works/` MUST рассматриваться как explicit data migration и MUST быть отделено от обычного implementation refactoring.

#### Scenario: Persistent work-state schema changes

- **GIVEN** proposed implementation меняет schema persistent data в `.state/erl/works/`
- **WHEN** изменение планируется или реализуется
- **THEN** оно SHALL быть явно классифицировано как migration
- **AND** migration requirements, compatibility и transition strategy SHALL быть определены отдельно от обычного refactoring

### Requirement: ERL-SHELL-001 — Canonical shell is Zsh

Основным shell для ERL shell implementation MUST быть Zsh.

#### Scenario: New ERL shell implementation is created

- **WHEN** создаётся новый ERL shell executable или sourceable shell library
- **THEN** его implementation SHALL использовать Zsh

### Requirement: ERL-SHELL-002 — Defensive shell behavior

ERL shell implementation MUST использовать корректное quoting, predictable exit codes и проверки пустого или отсутствующего обязательного input.

ERL shell implementation MUST NOT использовать hard-coded absolute paths или `cut -b` для пользовательского текста.

#### Scenario: Shell command handles user-controlled input

- **WHEN** ERL shell command получает paths, text или другие пользовательские значения
- **THEN** значения SHALL обрабатываться с корректным shell quoting
- **AND** обязательный пустой input SHALL быть обнаружен до выполнения зависимой operation
- **AND** command SHALL завершаться предсказуемым exit code
- **AND** implementation SHALL NOT зависеть от hard-coded absolute path
- **AND** implementation SHALL NOT использовать `cut -b` для разбиения пользовательского текста

### Requirement: ERL-SHELL-003 — macOS and Linux compatibility

ERL shell implementation MUST учитывать различия macOS и Linux там, где operation использует shared host/tooling contracts или platform-sensitive Unix utilities.

#### Scenario: ERL uses platform-sensitive tooling

- **GIVEN** ERL shell operation зависит от поведения utility или host contract, которое может различаться между macOS и Linux
- **WHEN** implementation выбирает invocation или parsing strategy
- **THEN** она SHALL учитывать обе поддерживаемые платформы
- **AND** platform-specific assumption SHALL NOT вводиться молча как universal behavior

### Requirement: ERL-SHELL-004 — Canonical .zsh filenames

Каждый shell script и каждая sourceable shell library, принадлежащие ERL, MUST иметь расширение `.zsh`.

Это относится к public CLI, internal utilities, development checks, libraries и test scripts ERL.

Skill и operation identifiers MAY оставаться extensionless, но canonical executable path MUST иметь форму `.scripts/erl/<command>.zsh`.

Extensionless executable wrappers и дублирующие копии ERL scripts MUST NOT использоваться как параллельный canonical interface.

#### Scenario: ERL shell executable is added

- **WHEN** новый ERL shell executable добавляется в repository
- **THEN** его filename SHALL завершаться на `.zsh`
- **AND** canonical executable path SHALL использовать `.zsh` filename
- **AND** extensionless duplicate executable SHALL NOT создаваться

#### Scenario: ERL shell library or test script is added

- **WHEN** добавляется ERL-owned sourceable shell library, development check или shell test
- **THEN** filename SHALL завершаться на `.zsh`

### Requirement: ERL-SHELL-005 — Canonical Zsh file header

После обязательного shebang каждый ERL Zsh-файл MUST содержать индивидуальный header из пяти comment lines: opening separator, полное имя файла, поле `Тип`, поле `Назначение` и closing separator.

Separator MUST иметь форму `#------------------------------------------------------------------------------`.

#### Scenario: ERL Zsh file header is validated

- **GIVEN** ERL-owned Zsh file существует в repository
- **WHEN** его header проверяется
- **THEN** первой строкой SHALL быть применимый shebang
- **AND** непосредственно после shebang SHALL находиться пятистрочный ERL header
- **AND** header SHALL содержать полное имя файла
- **AND** header SHALL содержать индивидуальные значения `Тип` и `Назначение`
- **AND** opening и closing separators SHALL быть `#------------------------------------------------------------------------------`
