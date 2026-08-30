# generation-reduce Specification

## Purpose

Определить generation-aware Reduce contract English Reading Lab: закрытие Book generations, mutation-set и reducibility semantics, dependency closure, read-only preflight, dry-run и confirmation, all-or-rollback transaction, recovery и удаление persistent metadata успешно закрытых generations.

## Requirements

### Requirement: ERL-REDUCE-001 — Book Reduce closes Book generations

`erl-book-reduce` MUST закрывать одну или несколько Book generations как ERL lifecycle operation.

#### Scenario: Book generations are reduced

- **WHEN** `erl-book-reduce` успешно выполняет Reduce
- **THEN** одна или несколько Book generations SHALL быть закрыты как ERL lifecycle operation

### Requirement: ERL-REDUCE-002 — Reduce seed uses explicitly selected active generations

Reduce seed MUST состоять из одной или нескольких явно указанных active Book Topic generation UUID.

#### Scenario: Reduce seed is selected

- **WHEN** пользователь запускает `erl-book-reduce`
- **THEN** seed SHALL состоять из одной или нескольких явно указанных active Book Topic generation UUID

### Requirement: ERL-REDUCE-003 — Initial mutation set contains reducible generation members

Initial mutation set generation MUST содержать:

- Book Topic generation;
- reducible generation members согласно `.state/erl/works/`.

Durable Chapter Notes MUST NOT входить в обычный mutation set.

#### Scenario: Initial mutation set is constructed

- **WHEN** ERL строит initial mutation set generation
- **THEN** set SHALL включать Book Topic generation
- **AND** SHALL включать reducible generation members согласно `.state/erl/works/`
- **AND** durable Chapter Notes SHALL NOT входить в обычный mutation set

### Requirement: ERL-REDUCE-004 — Reducible Book Topics and canonical Memos may be deprecated

`erl-book-reduce` MAY deprecate Book Topic и canonical Memo.

Для такой deprecation document MUST быть зарегистрирован как reducible generation member или включён в dependency closure.

#### Scenario: Reducible member is in the mutation closure

- **GIVEN** Book Topic или canonical Memo зарегистрирован как reducible generation member или включён в dependency closure
- **WHEN** `erl-book-reduce` применяет подтверждённый mutation plan
- **THEN** такой document MAY быть deprecated

### Requirement: ERL-REDUCE-005 — Canonical type alone does not determine reducibility

Canonical `:type:` сам по себе MUST NOT определять reducibility.

Note MUST NOT считаться автоматически reducible type.

#### Scenario: Reducibility is determined

- **WHEN** ERL определяет reducibility canonical document
- **THEN** canonical `:type:` SHALL NOT быть достаточным основанием для reducibility
- **AND** Note SHALL NOT считаться автоматически reducible type

### Requirement: ERL-REDUCE-006 — Canonical Notes are not automatically deprecated

`erl-book-reduce` MUST NOT автоматически deprecate canonical Note.

Durable Chapter Note MUST всегда оставаться active.

#### Scenario: Reduce encounters a canonical Note

- **WHEN** `erl-book-reduce` рассматривает canonical Note
- **THEN** Note SHALL NOT автоматически deprecate
- **AND** durable Chapter Note SHALL оставаться active

### Requirement: ERL-REDUCE-007 — Full read-only preflight precedes mutation

Перед mutation `erl-book-reduce` MUST выполнить полный read-only preflight.

Preflight MUST:

- проверить acceptable Git/worktree policy;
- проверить consistency work state `<->` Vault documents;
- построить dependency graph;
- вычислить hard-dependency closure до fixed point;
- просканировать active inbound links на mutation targets;
- показать точный mutation plan.

#### Scenario: Reduce preflight is executed

- **WHEN** `erl-book-reduce` готовит mutation
- **THEN** полный read-only preflight SHALL быть выполнен до первой mutation
- **AND** acceptable Git/worktree policy SHALL быть проверена
- **AND** consistency work state `<->` Vault documents SHALL быть проверена
- **AND** dependency graph SHALL быть построен
- **AND** hard-dependency closure SHALL быть вычислен до fixed point
- **AND** active inbound links на mutation targets SHALL быть просканированы
- **AND** точный mutation plan SHALL быть показан

### Requirement: ERL-REDUCE-008 — Hard dependencies require active targets

Hard dependency MUST означать relation, где active source требует active target.

Обязательные hard dependencies:

- active Occurrence `->` active Vocabulary;
- active generation state `->` active registered Book Topic.

Deprecated Book Topic MUST переводить generation в `GENERATION_CLOSED_EXTERNALLY`, после чего generation MUST NOT считаться active generation.

#### Scenario: Hard dependency is classified

- **WHEN** ERL классифицирует relation как hard dependency
- **THEN** active source SHALL требовать active target
- **AND** active Occurrence `->` active Vocabulary SHALL считаться hard dependency
- **AND** active generation state `->` active registered Book Topic SHALL считаться hard dependency

#### Scenario: Registered Book Topic is deprecated externally

- **GIVEN** active generation state связан с registered Book Topic
- **WHEN** этот Book Topic становится deprecated
- **THEN** generation SHALL перейти в `GENERATION_CLOSED_EXTERNALLY`
- **AND** SHALL NOT больше считаться active generation

### Requirement: ERL-REDUCE-009 — Cross-generation Occurrence dependency expands closure

Если Vocabulary из mutation set является target active Occurrence другой generation, owning generation этого Occurrence MUST входить в dependency closure.

#### Scenario: Vocabulary has an active Occurrence in another generation

- **GIVEN** Vocabulary входит в mutation set
- **AND** active Occurrence другой generation ссылается на этот Vocabulary
- **WHEN** ERL вычисляет dependency closure
- **THEN** owning generation этого Occurrence SHALL войти в dependency closure

### Requirement: ERL-REDUCE-010 — Dependency closure is transitive and unbounded by work boundaries

Dependency closure MUST быть транзитивным, MUST вычисляться до fixed point и MAY пересекать границы любого количества books, works и generations.

#### Scenario: Dependency closure crosses generation boundaries

- **WHEN** ERL вычисляет dependency closure
- **THEN** closure SHALL быть транзитивным
- **AND** SHALL вычисляться до fixed point
- **AND** MAY пересекать границы любого количества books, works и generations

### Requirement: ERL-REDUCE-011 — Wide cross-book closure is expected

Широкий cross-book dependency closure MUST считаться ожидаемой feature ERL, а не ошибкой алгоритма.

#### Scenario: Closure spans multiple books

- **WHEN** корректно вычисленный dependency closure охватывает несколько books
- **THEN** широкий cross-book closure SHALL считаться ожидаемой feature ERL
- **AND** SHALL NOT считаться ошибкой алгоритма

### Requirement: ERL-REDUCE-012 — Dependency closure is not limited to the source book

ERL MUST NOT ограничивать dependency closure границей исходной книги.

#### Scenario: Dependency requires another book

- **WHEN** hard-dependency closure выходит за границу исходной книги
- **THEN** ERL SHALL продолжить вычисление closure за этой границей
- **AND** SHALL NOT ограничивать closure исходной книгой

### Requirement: ERL-REDUCE-013 — New active-target relations join the Reduce dependency model

Любая новая ERL relation с invariant `active target required` MUST быть зарегистрирована в dependency model Reduce.

#### Scenario: New ERL relation requires an active target

- **GIVEN** новая ERL relation имеет invariant `active target required`
- **WHEN** relation вводится в ERL
- **THEN** она SHALL быть зарегистрирована в dependency model Reduce

### Requirement: ERL-REDUCE-014 — Other inbound links are soft unless active target is required

Прочие active inbound links MUST считаться soft references, если их contract не требует active target.

Неизвестная ERL-specific dependency MUST быть классифицирована до mutation.

#### Scenario: Active inbound link does not require an active target

- **GIVEN** active inbound link не имеет contract, требующего active target
- **WHEN** ERL классифицирует dependency
- **THEN** link SHALL считаться soft reference

#### Scenario: Unknown ERL-specific dependency is discovered

- **GIVEN** preflight обнаружил неизвестную ERL-specific dependency
- **WHEN** `erl-book-reduce` готовит mutation
- **THEN** dependency SHALL быть классифицирована до mutation

### Requirement: ERL-REDUCE-015 — Dry-run performs full preflight without mutation

`erl-book-reduce --dry-run` MUST выполнять полный preflight и dependency closure и MUST NOT изменять Vault documents или persistent work state.

#### Scenario: Reduce runs in dry-run mode

- **WHEN** выполняется `erl-book-reduce --dry-run`
- **THEN** полный preflight SHALL быть выполнен
- **AND** dependency closure SHALL быть вычислен
- **AND** Vault documents SHALL NOT изменяться
- **AND** persistent work state SHALL NOT изменяться

### Requirement: ERL-REDUCE-016 — Additional generations require explicit confirmation

Если dependency closure включает дополнительные generations, каскад MUST NOT выполняться молча.

Полный closure MUST быть показан пользователю и MUST требовать explicit confirmation/option, например `--include-dependencies`.

#### Scenario: Closure expands beyond explicitly selected generations

- **GIVEN** dependency closure включает дополнительные generations
- **WHEN** preflight завершён
- **THEN** полный closure SHALL быть показан пользователю
- **AND** каскад SHALL NOT выполняться молча
- **AND** выполнение SHALL требовать explicit confirmation или option, например `--include-dependencies`

### Requirement: ERL-REDUCE-017 — Dry-run report explains the complete closure

Dry-run/report MUST показывать:

- все affected generations;
- все mutation target UUID;
- type/role каждого target;
- причину включения каждой generation/target в closure.

#### Scenario: Reduce report is produced

- **WHEN** `erl-book-reduce` формирует dry-run/report
- **THEN** report SHALL показывать все affected generations
- **AND** SHALL показывать все mutation target UUID
- **AND** SHALL показывать type/role каждого target
- **AND** SHALL показывать причину включения каждой generation и target в closure

### Requirement: ERL-REDUCE-018 — Reduce is an all-or-rollback transaction

Reduce MUST являться semantic all-or-rollback transaction.

#### Scenario: Reduce mutates generation state

- **WHEN** `erl-book-reduce` начинает semantic mutation
- **THEN** операция SHALL выполняться как all-or-rollback transaction

### Requirement: ERL-REDUCE-019 — Transaction journal exists before first mutation

До первой mutation MUST создаваться transaction journal:

```text
.state/erl/transactions/<TXID>/
```

Journal MUST содержать как минимум:

- mutation plan;
- original file hashes;
- backups/snapshots изменяемых documents/work-state files;
- transaction phase.

#### Scenario: Reduce transaction prepares for mutation

- **WHEN** Reduce transaction готова выполнить первую mutation
- **THEN** .state/erl/transactions/<TXID>/ SHALL уже существовать
- **AND** journal SHALL содержать mutation plan
- **AND** SHALL содержать original file hashes
- **AND** SHALL содержать backups/snapshots изменяемых documents/work-state files
- **AND** SHALL содержать transaction phase

### Requirement: ERL-REDUCE-020 — File mutations use atomic replacement where supported

Изменения отдельных файлов MUST применяться через temporary file + atomic rename, где это поддерживает локальная filesystem.

#### Scenario: Reduce changes an individual file

- **WHEN** erl-book-reduce изменяет отдельный файл
- **AND** локальная filesystem поддерживает atomic rename
- **THEN** изменение SHALL применяться через temporary file + atomic rename

### Requirement: ERL-REDUCE-021 — Post-validation failure rolls back the whole closure

После mutation MUST выполняться post-validation всего closure.
При ошибке MUST выполняться rollback всех mutation targets.

#### Scenario: Post-validation fails

- **GIVEN** mutation применена ко всему подтверждённому closure
- **WHEN** post-validation обнаруживает ошибку
- **THEN** rollback SHALL быть выполнен для всех mutation targets

### Requirement: ERL-REDUCE-022 — Interrupted transactions block new Reduce transactions

Crash или interruption MUST оставлять recovery journal.
Новая Reduce transaction MUST NOT начинаться до завершения или explicit rollback предыдущей transaction.

#### Scenario: Reduce transaction is interrupted

- **GIVEN** Reduce transaction была прервана до успешного завершения
- **WHEN** ERL восстанавливается после crash или interruption
- **THEN** recovery journal SHALL оставаться доступным
- **AND** новая Reduce transaction SHALL NOT начинаться до завершения или explicit rollback предыдущей transaction

### Requirement: ERL-REDUCE-023 — Rollback protects unexpected user changes

Rollback MUST проверять recorded hashes и MUST NOT молча перетирать неожиданные пользовательские изменения, появившиеся после начала transaction.

#### Scenario: File changed unexpectedly after transaction start

- **GIVEN** файл был изменён после начала Reduce transaction
- **WHEN** rollback рассматривает восстановление этого файла
- **THEN** recorded hashes SHALL быть проверены
- **AND** неожиданные пользовательские изменения SHALL NOT быть молча перезаписаны

### Requirement: ERL-REDUCE-024 — Classic Topic Reduce may trigger ERL dependency closure

Если Classic Topic Reduce deprecates Vocabulary Memo с active dependants, это MUST считаться supported closure trigger.
erl-check или erl-book-reduce MUST обнаруживать такое состояние и предлагать полный closure.

#### Scenario: Classic Topic Reduce deprecates Vocabulary with active dependants

- **GIVEN** Classic Topic Reduce deprecated Vocabulary Memo
- **AND** Vocabulary имеет active dependants
- **WHEN** erl-check или erl-book-reduce анализирует ERL state
- **THEN** состояние SHALL быть обнаружено как supported closure trigger
- **AND** пользователю SHALL быть предложен полный dependency closure

### Requirement: ERL-REDUCE-025 — Closed generation metadata is removed transactionally

Для каждой confirmed Book generation `erl-book-reduce` MUST удалить generation-specific persistent metadata из `.state/erl/works/`.

Удаление MUST участвовать в той же Reduce transaction и journal backup. Failure MUST восстанавливать state. После commit `cache/` и `staging/` MUST NOT считаться его допустимыми копиями.

#### Scenario: Confirmed generation is closed successfully

- **GIVEN** Book generation входит в подтверждённый mutation set или dependency closure
- **WHEN** erl-book-reduce успешно закрывает generation
- **THEN** Book generation state SHALL быть удалён из .state/erl/works/
- **AND** processing policy SHALL быть удалена
- **AND** reading sequence SHALL быть удалена
- **AND** ingestion receipts SHALL быть удалены
- **AND** reducible/dependency metadata SHALL быть удалена
- **AND** generation reference SHALL быть удалена из work manifest
- **AND** active-generation pointer SHALL быть удалён, если он указывает на закрываемую generation

#### Scenario: Generation metadata participates in Reduce transaction recovery

- **GIVEN** generation-specific persistent metadata входит в mutation plan
- **WHEN** Reduce transaction выполняет mutation
- **THEN** удаление metadata SHALL входить в ту же all-or-rollback transaction, что и deprecation Vault documents
- **AND** до commit удаляемые state files/records SHALL быть включены в journal backup
- **AND** ошибка mutation или post-validation SHALL восстанавливать state вместе с документами

#### Scenario: Closed generation transaction is committed

- **GIVEN** Reduce transaction успешно committed
- **WHEN** ERL рассматривает удалённый persistent generation state
- **THEN** cache/ SHALL NOT считаться допустимой его копией
- **AND** staging/ SHALL NOT считаться допустимой его копией
