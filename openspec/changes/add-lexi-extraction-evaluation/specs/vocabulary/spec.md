## ADDED Requirements

### Requirement: ERL-EVAL-004 — Vocabulary reuse is not presented as demonstrated learning

README, CLI и Lexi reports MUST отличать существование active Vocabulary от знания слова пользователем. До отдельного learner-state contract они MUST NOT заявлять проверенное усвоение, mastery или learned-word filtering только на основании dedup.

#### Scenario: An existing card is reused

- **GIVEN** active Vocabulary найдена при новом encounter
- **WHEN** пользователь получает отчёт
- **THEN** результат SHALL описывать reuse/existing card
- **AND** он SHALL не утверждать, что пользователь уже выучил слово
