## ADDED Requirements

### Requirement: ERL-LOCK-001 — Only an acquired owner may release a lock

Lock release MUST требовать доказательство успешного acquisition и совпадение owner token. Failed acquisition, EXIT/HUP/INT/TERM cleanup конкурента и повторный release MUST NOT удалять lock другого владельца.

#### Scenario: Rejected writer preserves owner lock

- **GIVEN** процесс A владеет lock, B пытается получить тот же lock
- **WHEN** B получает STATE_CONFLICT и выполняет cleanup
- **THEN** lock и owner token A SHALL сохраниться
- **AND** процесс C SHALL не получить защищённую область до release A

#### Scenario: Repeated cleanup is harmless

- **GIVEN** A освободил свой lock, затем его получил B
- **WHEN** повторный cleanup A выполняется после нового acquisition
- **THEN** lock B SHALL остаться действующим

### Requirement: ERL-LOCK-002 — Unknown and stale locks require explicit handling

Неизвестный, ownerless или подозреваемый stale lock MUST блокировать mutation с диагностикой. Explicit stale-lock handling MUST повторно проверять ownership/liveness и pending transactions и MUST NOT освобождать работающего владельца.

#### Scenario: Legacy lock is not guessed stale

- **GIVEN** найден lock без owner metadata
- **WHEN** новая операция запускается
- **THEN** операция SHALL сообщить blocked result и путь lock
- **AND** никакой автоматической очистки SHALL не произойти

#### Scenario: Owner changes during stale cleanup

- **GIVEN** оператор подготовил очистку старого lock
- **WHEN** перед apply обнаружен другой token либо живой owner
- **THEN** очистка SHALL быть отклонена без удаления нового lock
