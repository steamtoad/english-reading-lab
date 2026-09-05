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

### Requirement: ERL-GIT-004 — Repository distributions exclude platform metadata artifacts

ERL source repository и публикуемые skill distributions MUST NOT содержать platform- или editor-generated metadata artifacts, не являющиеся частью ERL source contract, включая `.DS_Store`.

Repository ignore policy и validation workflow MUST предотвращать незаметное включение таких artifacts. Уже существующая проверка запрещённых skill installation artifacts MUST сохраняться.

#### Scenario: ERL repository distribution is validated

- **GIVEN** ERL repository или skill distribution подготовлены к validation
- **WHEN** выполняется repository/distribution hygiene check
- **THEN** platform/editor metadata artifacts SHALL отсутствовать
- **AND** обнаруженный `.DS_Store` SHALL приводить к validation failure с указанием path

#### Scenario: macOS creates ignored metadata locally

- **WHEN** поддерживаемая platform создаёт `.DS_Store` в ERL working tree
- **THEN** repository ignore policy SHALL исключать artifact из source distribution
- **AND** canonical ERL source files SHALL оставаться неизменными

#### Scenario: Other forbidden skill artifacts are checked

- **WHEN** hygiene fix для `.DS_Store` применяется
- **THEN** validation SHALL продолжать запрещать ранее распознаваемые skill installation artifacts
- **AND** fix SHALL NOT ослаблять существующий distribution boundary

### Requirement: ERL-TEST-002 — Primary regression gate учитывает lifecycle change

ERL validation MUST различать незавершённый planning/implementation change и change, у которого все implementation tasks отмечены выполненными. Отсутствие `tests/erl-<behavior-slug>.zsh` MUST приводить к validation failure для завершённого change, но MUST NOT блокировать repository suite только из-за active planning change с невыполненными tasks.

Deterministic naming rule `ERL-TEST-001` MUST применяться ко всем ERL OpenSpec changes. Planning-only исключение MUST NOT считаться освобождением от primary regression: до отметки всех implementation tasks выполненными и до archive change MUST получить свой canonical primary test.

#### Scenario: Planning-only change ещё не имеет primary test

- **GIVEN** active OpenSpec change содержит хотя бы одну невыполненную implementation task
- **AND** derived primary regression test ещё отсутствует
- **WHEN** выполняется repository regression-test naming validation
- **THEN** отсутствие test SHALL NOT завершать repository suite ошибкой
- **AND** change SHALL оставаться незавершённым

#### Scenario: Completed change не имеет primary test

- **GIVEN** все implementation tasks active OpenSpec change отмечены выполненными
- **AND** derived primary regression test отсутствует
- **WHEN** выполняется repository regression-test naming validation
- **THEN** validation SHALL завершиться ошибкой
- **AND** diagnostic SHALL содержать change name и exact expected test path

#### Scenario: Completed change имеет правильно названный primary test

- **GIVEN** все implementation tasks change отмечены выполненными
- **AND** существует executable или source-controlled test `tests/erl-<behavior-slug>.zsh`
- **WHEN** выполняется repository regression-test naming validation
- **THEN** naming gate SHALL принять этот change

#### Scenario: Additional test не заменяет primary regression

- **GIVEN** completed change имеет дополнительные focused tests, но не имеет derived primary test
- **WHEN** выполняется repository regression-test naming validation
- **THEN** validation SHALL завершиться ошибкой отсутствующего primary test

#### Scenario: Change архивируется без primary test

- **GIVEN** ERL OpenSpec change готовится к archive
- **AND** canonical derived primary regression test отсутствует
- **WHEN** выполняется archive validation
- **THEN** archive SHALL быть заблокирован
- **AND** diagnostic SHALL указать exact expected test path

### Requirement: ERL-TEST-001 — Delta-spec has a deterministically named primary regression test

Каждый ERL OpenSpec change MUST иметь primary regression test с именем, детерминированно производным от имени change directory.

Для ERL filename MUST иметь форму `erl-<behavior-slug>.zsh`. `behavior-slug` MUST вычисляться удалением ровно одного leading change-kind prefix `fix-`, `add-`, `change-`, `update-`, `migrate-`, `refactor-`, `implement-` или `remove-`, после чего MUST добавляться project prefix `erl-`. Если известный change-kind prefix отсутствует, project prefix MUST добавляться к полному change name.

Дополнительные regression tests MAY существовать, но MUST NOT заменять обязательный primary test.

#### Scenario: Fix change creates its primary regression test

- **GIVEN** OpenSpec change directory называется `fix-target-home-layout`
- **WHEN** вычисляется обязательное имя primary regression test
- **THEN** primary regression test SHALL называться `erl-target-home-layout.zsh`
- **AND** test SHALL находиться в canonical ERL tests directory

#### Scenario: Remove change creates its primary regression test

- **GIVEN** OpenSpec change directory называется `remove-chapter-vocabulary-quota`
- **WHEN** вычисляется обязательное имя primary regression test
- **THEN** filename SHALL быть `erl-chapter-vocabulary-quota.zsh`
- **AND** filename SHALL NOT быть `erl-remove-chapter-vocabulary-quota.zsh`

#### Scenario: Change has no recognized change-kind prefix

- **GIVEN** OpenSpec change directory называется `target-home-layout`
- **WHEN** вычисляется имя primary regression test
- **THEN** filename SHALL быть `erl-target-home-layout.zsh`

#### Scenario: Additional focused tests are added

- **GIVEN** primary regression test существует с canonical derived name
- **WHEN** implementation требует дополнительные focused tests
- **THEN** дополнительные test files MAY иметь более узкие имена
- **AND** canonical primary regression test SHALL сохраняться

#### Scenario: Every delta declares its primary test task

- **GIVEN** создаётся ERL OpenSpec change с implementation tasks
- **WHEN** формируется `tasks.md`
- **THEN** tasks SHALL содержать создание или обновление canonical derived primary regression test
- **AND** verification SHALL включать запуск этого test

### Requirement: ERL-TEST-003 — Positive integration fixtures conform to canonical contracts

Каждый положительный ERL integration fixture MUST удовлетворять всем применимым canonical contracts, действующим для моделируемого состояния. Integration test MUST проверять заявленное поведение на валидных preconditions и MUST NOT завершаться несвязанной validation failure из-за устаревших fixture data.

#### Scenario: Existing integration fixture remains valid after a canonical contract change

- **GIVEN** canonical contract изменил допустимое значение metadata для Book и связанных документов
- **AND** integration fixture моделирует положительное состояние этих документов
- **WHEN** выполняются предметная operation и её финальная validation
- **THEN** fixture data SHALL соответствовать текущему canonical contract во всей применимой projection
- **AND** test SHALL достигнуть assertions заявленного поведения без несвязанной validation failure

#### Scenario: Book-title key policy applies to positive integration fixtures

- **GIVEN** fixture моделирует Book, Chapters и принадлежащие им Memo
- **WHEN** canonical policy требует exact equality Book title и применимых `:key-topic:`
- **THEN** положительный fixture SHALL использовать canonical Book title во всех применимых документах
- **AND** человекочитаемое body MAY сохранять отдельную тематическую информацию, не подменяя header `:key-topic:`
