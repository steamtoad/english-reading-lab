## ADDED Requirements

### Requirement: ERL-BATCH-002 — Empty chapters have explicit handoff semantics

Пустая Chapter MUST NOT создавать Memo Chain или исходящий tail-Memo handoff и MUST NOT вызывать неявное перескакивание через Chapter. Допустимая входящая связь от tail непосредственно предыдущей Chapter MUST сохраняться, а следующая Chapter продолжает global sequence без artificial gap.

#### Scenario: Empty middle chapter separates two nonempty chapters

- **GIVEN** A имеет tail Memo, B пустая, C обрабатывается следующей
- **WHEN** batch B завершён и начинается C
- **THEN** A→B handoff SHALL сохраниться
- **AND** B SHALL не получать synthetic tail, а C SHALL начать собственную chain со следующим sequence ordinal
