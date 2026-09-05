## MODIFIED Requirements

### Requirement: ERL-ING-010 — Created Vocabulary and Occurrence inherit Chapter book-title key-topic

Каждый Vocabulary или Occurrence Memo, созданный для lexical encounter текущей Chapter, MUST содержать `:key-topic:` с точным значением canonical book title этой Chapter Note.

Vocabulary Memo MUST наследовать key при первом приобретении lexical identity. При последующей встрече существующей global Vocabulary ERL MUST создать новый Occurrence Memo с key текущей Chapter и MUST NOT менять key исходной Vocabulary.

#### Scenario: New Vocabulary is acquired in a Chapter

- **GIVEN** Chapter книги `Friday` имеет `:key-topic: Friday`
- **WHEN** ERL создаёт новую Vocabulary Memo
- **THEN** Memo `:key-topic:` SHALL быть `Friday`
- **AND** Vocabulary SHALL считаться прикреплённой к Chapter первого приобретения

#### Scenario: Existing Vocabulary occurs in another book

- **GIVEN** active Vocabulary была приобретена в другой книге
- **WHEN** Candidate встречается в Chapter книги `Friday`
- **THEN** новый Occurrence `:key-topic:` SHALL быть `Friday`
- **AND** `:key-topic:` существующей Vocabulary SHALL NOT изменяться

#### Scenario: Existing Vocabulary occurs in another Chapter

- **GIVEN** Candidate соответствует существующей active Vocabulary, приобретённой ранее
- **WHEN** ERL создаёт Occurrence Memo в текущей Chapter
- **THEN** Occurrence `:key-topic:` SHALL точно совпадать с текущей Chapter Note
- **AND** `:key-topic:` существующей Vocabulary SHALL NOT изменяться
- **AND** attachment существующей Vocabulary к Chapter первого приобретения SHALL сохраняться
