## ADDED Requirements

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
