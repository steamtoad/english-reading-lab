## ADDED Requirements

### Requirement: ERL-RECOVERY-001 — Every emitted operation journal has a recovery route

Для каждого journal, создаваемого поддерживаемой mutation, ERL MUST иметь проверяемый recovery protocol. Он MUST покрывать Book Reduce, work rename, state migrate, Classic reconcile и остальные runtime/setup mutations. Новая operation MUST NOT выпускаться без recoverability tests; unknown legacy journal MUST сохраняться с explicit manual recovery diagnostic.

#### Scenario: Book Reduce was interrupted

- **GIVEN** Reduce оставил journal и backups до committed phase
- **WHEN** оператор запускает recovery dry-run/apply
- **THEN** команда SHALL предложить и выполнить определённый rollback либо validated completion вместо RECOVERY_UNSUPPORTED

#### Scenario: Other state mutation was interrupted

- **GIVEN** work-rename, state-migrate или classic-reconcile остановлена в каждой persistent фазе
- **WHEN** оператор перезапускает recovery
- **THEN** полученное состояние SHALL быть полностью прежним либо полностью новым и valid

#### Scenario: Unknown legacy journal is found

- **GIVEN** journal version или обязательные recovery данные не распознаются
- **WHEN** запускается recovery
- **THEN** команда SHALL сохранить artifacts, вернуть blocked diagnostic и manual plan
- **AND** recovered/committed SHALL не заявляться

### Requirement: ERL-RECOVERY-002 — Write intent precedes recoverable mutation

Multi-file операции MUST сохранять достаточно intent, ownership и verified backups до первой соответствующей mutation, чтобы process interruption между любыми двумя persistent steps оставался разрешимым. Recovery MUST проверять целостность всей semantic operation до объявления commit.

#### Scenario: Crash occurs between replacement and phase update

- **GIVEN** новая версия одного файла опубликована, journal completion ещё не записан
- **WHEN** процесс аварийно остановлен и recovery запущен
- **THEN** recovery SHALL различить pre/post state по зарегистрированным данным и восстановить согласованный результат

#### Scenario: Manifest pointer exists but documents are incomplete

- **GIVEN** незавершённый ingest journal указывает generation в manifest
- **WHEN** recovery рассматривает completion
- **THEN** наличие pointer SHALL не заменять validation всех required artifacts/links

### Requirement: ERL-RECOVERY-003 — Recovery preserves external edits and is repeatable

Rollback/recovery MUST сравнить current artifacts с допустимыми pre/post hashes, проверить backup integrity и paths до изменения. Unexpected bytes MUST сохраняться с recovery conflict. Повтор recovery на завершённой operation MUST быть идемпотентным; частичный recovery MUST оставлять собственный recoverable progress.

#### Scenario: User changes a migration target

- **GIVEN** после interrupted chapter-memo-chain migration пользователь изменил документ
- **WHEN** recovery выполняет preflight
- **THEN** документ SHALL остаться неизменным и operation SHALL вернуть conflict

#### Scenario: Recovery itself is interrupted

- **GIVEN** часть восстановительных steps уже выполнена
- **WHEN** recovery перезапускается
- **THEN** результат SHALL быть таким же, как после одного полного recovery, без потери external edits

### Requirement: ERL-RECOVERY-004 — Rename and layout migrations preserve recovery reachability

Work rename, home-layout migration и source-path updates MUST сохранять доступность известных recovery targets либо блокироваться до разрешения pending journals. Atomic path mapping migration MUST охватывать все принадлежащие ERL references; legacy flat Vault MUST NOT автоматически приниматься за поддерживаемый nested layout.

#### Scenario: Rename encounters a pending journal with absolute paths

- **GIVEN** work содержит незавершённую operation со старым absolute path
- **WHEN** пользователь выполняет rename
- **THEN** операция SHALL блокироваться либо атомарно мигрировать проверяемый полный mapping
- **AND** старые backups SHALL не становиться недоступными

#### Scenario: Unrelated files or unsupported layout are present

- **GIVEN** миграция видит root-level notes или неопознанные файлы
- **WHEN** preflight определяет область переноса
- **THEN** неподдерживаемая схема SHALL получить явную diagnostic
- **AND** никакой implicit move или broad deletion SHALL не произойти
