## ADDED Requirements

### Requirement: ERL-ING-010 — Created Vocabulary and Occurrence inherit Chapter key-topic

Каждый Vocabulary или Occurrence Memo, созданный для lexical encounter текущей Chapter, MUST содержать host-defined header attribute `:key-topic:` с точным значением `:key-topic:` этой Chapter Note.

Vocabulary Memo MUST наследовать key при первом приобретении lexical identity. При последующей встрече существующей global Vocabulary ERL MUST создать новый Occurrence Memo с key текущей Chapter и MUST NOT менять acquisition attachment исходной Vocabulary.

#### Scenario: New Vocabulary is acquired in a Chapter

- **GIVEN** Candidate не соответствует существующей active Vocabulary
- **WHEN** ERL создаёт Vocabulary Memo для Chapter
- **THEN** Memo `:key-topic:` SHALL точно совпадать с Chapter Note `:key-topic:`
- **AND** Vocabulary SHALL считаться прикреплённой к Chapter первого приобретения

#### Scenario: Existing Vocabulary occurs in another Chapter

- **GIVEN** Candidate соответствует существующей active Vocabulary, приобретённой ранее
- **WHEN** ERL создаёт Occurrence Memo в текущей Chapter
- **THEN** Occurrence `:key-topic:` SHALL точно совпадать с текущей Chapter Note
- **AND** `:key-topic:` существующей Vocabulary SHALL NOT изменяться
- **AND** attachment существующей Vocabulary к Chapter первого приобретения SHALL сохраняться

### Requirement: ERL-ING-011 — Created Memo and Chapter Note have reciprocal canonical links

Каждый созданный Vocabulary или Occurrence Memo MUST иметь reciprocal canonical relation с Chapter Note, где возник lexical encounter.

Memo MUST содержать ровно одну canonical link на Chapter Note в структурной секции `Chapter`. Chapter Note MUST содержать ровно одну canonical link на Memo в структурной секции `Vocabulary`, упорядоченную по Candidate/source order текущей Chapter.

#### Scenario: Vocabulary or Occurrence is created

- **WHEN** ERL создаёт Vocabulary или Occurrence Memo для Chapter
- **THEN** Memo section `Chapter` SHALL содержать canonical link на Chapter UUID
- **AND** Chapter section `Vocabulary` SHALL содержать reciprocal canonical link на Memo UUID
- **AND** обе links SHALL существовать после committed Candidate ingestion
- **AND** duplicate links SHALL NOT создаваться при retry

### Requirement: ERL-ING-012 — Memo attachment and chain mutation are recoverable with ingestion state

Для каждого Candidate создание Vocabulary/Occurrence Memo, наследование `:key-topic:`, Chapter reciprocal link, изменение predecessor chain link, generation membership, reading-sequence entry и ingestion receipt MUST быть одной recoverable semantic operation.

Operation MUST либо зафиксировать согласованный новый node, либо восстановить bytes всех изменённых documents и persistent state. Chapter batch retry MUST безопасно продолжать с первого Candidate без completed receipt.

#### Scenario: Failure occurs after predecessor or Chapter update

- **GIVEN** ingestion начала изменять predecessor Memo или Chapter Note
- **WHEN** последующая document или state mutation завершается ошибкой
- **THEN** current Candidate SHALL NOT получить completed receipt
- **AND** созданный Memo SHALL быть удалён или помечен recoverable transaction state
- **AND** predecessor Memo, Chapter Note и generation state SHALL быть восстановлены до pre-operation bytes

#### Scenario: Interrupted Chapter batch is retried

- **GIVEN** предыдущие Candidates имеют completed receipts, а следующий Candidate не committed
- **WHEN** Chapter ingestion запускается повторно
- **THEN** completed nodes SHALL NOT создаваться или связываться повторно
- **AND** chain SHALL продолжиться с последнего committed Memo этой Chapter

