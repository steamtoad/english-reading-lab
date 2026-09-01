## ADDED Requirements

### Requirement: ERL-SEQ-012 — Chapter chain tail links to the next Chapter

После completed Chapter-level ingestion tail Memo текущей Chapter MUST содержать ровно одну canonical link на непосредственно следующую Chapter Note того же source в source order.

Link MUST находиться в структурной секции `Reading handoff` и иметь label `Следующая глава`. Reciprocal link на следующей Chapter Note MUST соответствовать `ERL-CHAPTER-016`.

Handoff MUST соединять tail Memo с Chapter Note и MUST NOT соединять две Chapter-local Memo Chains напрямую.

#### Scenario: Chapter with a Memo tail has a next Chapter

- **GIVEN** текущая Chapter имеет completed Memo Chain
- **AND** source state содержит непосредственно следующую Chapter
- **WHEN** Chapter-level ingestion завершается успешно
- **THEN** tail Memo SHALL содержать `Следующая глава` link на следующую Chapter Note
- **AND** следующая Chapter SHALL содержать reciprocal link на tail Memo
- **AND** первая Memo следующей Chapter SHALL оставаться head отдельной chain без predecessor из предыдущей Chapter

#### Scenario: Current Chapter is the last source Chapter

- **GIVEN** current Chapter является последней Chapter данного source
- **WHEN** Chapter-level ingestion завершается успешно
- **THEN** tail Memo SHALL NOT получать `Следующая глава` handoff link
- **AND** отсутствие handoff SHALL считаться valid terminal state

### Requirement: ERL-SEQ-013 — Chapter handoff is committed with batch completion

Chapter→next-Chapter handoff MUST вычисляться только после завершения всех Candidates текущего extraction batch, когда tail Memo окончательно определён.

Tail Memo update, next Chapter Note update и completed Chapter-level ingestion result MUST быть одной recoverable semantic operation. Partial или stale handoff MUST приводить к rollback или `RECOVERY_REQUIRED` и MUST NOT считаться completed handoff.

#### Scenario: Handoff mutation fails after tail update

- **GIVEN** tail Memo получила outgoing handoff link
- **WHEN** reciprocal next Chapter update или batch commit завершается ошибкой
- **THEN** outgoing link SHALL быть rolled back или transaction SHALL остаться recoverable
- **AND** one-sided handoff SHALL NOT считаться committed

#### Scenario: Completed batch is retried

- **GIVEN** reciprocal handoff уже committed для completed Chapter batch
- **WHEN** тот же batch запускается повторно
- **THEN** additional handoff links SHALL NOT создаваться
- **AND** existing reciprocal pair SHALL оставаться неизменной

