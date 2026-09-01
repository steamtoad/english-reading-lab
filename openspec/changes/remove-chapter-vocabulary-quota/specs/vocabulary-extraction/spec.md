## ADDED Requirements

### Requirement: ERL-CAND-010 — Chapter extraction has no Candidate quota

Default extraction policy MUST анализировать полное содержимое текущей Chapter и MUST NOT ограничивать число подходящих Vocabulary Candidates фиксированной или адаптивной квотой на Chapter.

Это требование не отменяет дедупликацию одного lexical identity внутри Chapter согласно `ERL-CAND-004` и `ERL-CAND-005`.

#### Scenario: Chapter contains more relevant lexical items than a sampling quota

- **GIVEN** Chapter содержит несколько lexical items, соответствующих active extraction policy
- **WHEN** ERL выполняет Chapter vocabulary extraction
- **THEN** каждый соответствующий policy уникальный lexical identity SHALL быть представлен Candidate на первом relevant occurrence
- **AND** extraction SHALL NOT исключать Candidate только из-за общего числа уже выбранных Candidates в Chapter
