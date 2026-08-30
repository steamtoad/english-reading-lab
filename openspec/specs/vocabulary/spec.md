# vocabulary Specification

## Purpose

Определить canonical Vocabulary model English Reading Lab: представление Vocabulary как Memo, structural role, deterministic lexical identity, global active uniqueness, generation ownership и поведение deprecated Vocabulary.

## Requirements

### Requirement: ERL-VOC-001 — Vocabulary is a canonical Memo

Vocabulary MUST быть представлен canonical Memo.

#### Scenario: Vocabulary is persisted

- **WHEN** ERL создаёт persistent Vocabulary
- **THEN** Vocabulary SHALL быть canonical Memo

### Requirement: ERL-VOC-002 — Vocabulary Memo has no ERL-specific attributes

Vocabulary Memo MUST NOT получать ERL-specific attributes.

#### Scenario: Vocabulary Memo is persisted

- **WHEN** ERL создаёт или обновляет Vocabulary Memo
- **THEN** Memo SHALL NOT получать ERL-specific attributes

### Requirement: ERL-VOC-003 — Vocabulary role is determined by persistent state and lexical structure

Vocabulary role MUST определяться persistent work state и lexical card structure документа.

Минимальный deterministic lexical identity block MUST иметь структуру:

    == Lexical identity

    Lemma:: ...
    POS:: ...
    Lexical type:: ...

Дополнительные sections MAY содержать Meaning, Translation, IPA, CEFR, Usage, Context, Related vocabulary и Notes.

#### Scenario: Memo is resolved as Vocabulary

- **GIVEN** persistent work state определяет canonical Memo как Vocabulary
- **WHEN** ERL проверяет lexical card structure документа
- **THEN** Memo SHALL содержать `Lexical identity` block
- **AND** block SHALL содержать `Lemma`
- **AND** block SHALL содержать `POS`
- **AND** block SHALL содержать `Lexical type`

### Requirement: ERL-VOC-004 — Lexical identity is deterministic

Базовая lexical identity MUST определяться как:

`normalized lemma + normalized POS + normalized lexical type`.

#### Scenario: Lexical identity is calculated

- **WHEN** ERL вычисляет lexical identity
- **THEN** identity SHALL включать normalized lemma
- **AND** SHALL включать normalized POS
- **AND** SHALL включать normalized lexical type

### Requirement: ERL-VOC-005 — Surface form and sense are not required identity components

Surface form MUST NOT сам по себе являться canonical lexical identity.

Sense MUST NOT быть обязательной частью lexical identity в текущем contract.

#### Scenario: Surface forms differ

- **GIVEN** lexical items имеют одинаковые normalized lemma, POS и lexical type
- **WHEN** их surface forms различаются
- **THEN** различие surface form SHALL NOT само по себе определять другую canonical lexical identity

#### Scenario: Sense is absent

- **WHEN** lexical item имеет valid normalized lemma, POS и lexical type
- **THEN** отсутствие отдельного sense component SHALL NOT делать lexical identity invalid

### Requirement: ERL-VOC-006 — Active Vocabulary is unique by lexical identity

Среди active Vocabulary MUST существовать не более одной canonical карточки для одной lexical identity.

#### Scenario: Active Vocabulary already exists

- **GIVEN** active canonical Vocabulary существует для lexical identity
- **WHEN** ERL обрабатывает ту же lexical identity повторно
- **THEN** второй active canonical Vocabulary для этой identity SHALL NOT создаваться

### Requirement: ERL-VOC-007 — Vocabulary is global canonical lexical knowledge

Vocabulary MUST быть global canonical lexical knowledge для active library и MUST NOT существовать как отдельный book-local duplicate только из-за принадлежности lexical item к другой книге.

#### Scenario: Another Book encounters known Vocabulary

- **GIVEN** active canonical Vocabulary существует для lexical identity
- **WHEN** та же lexical identity встречается в другой Book generation
- **THEN** ERL SHALL использовать существующую global canonical Vocabulary
- **AND** SHALL NOT создавать отдельный book-local canonical duplicate

### Requirement: ERL-VOC-008 — Vocabulary belongs to its first acquisition generation

Vocabulary MUST принадлежать generation первого приобретения lexical item.

Эта ownership relation MUST храниться в persistent generation state.

#### Scenario: Vocabulary acquisition ownership is recorded

- **GIVEN** Book generation приобретает lexical item как canonical Vocabulary
- **WHEN** ownership Vocabulary устанавливается
- **THEN** эта Book generation SHALL быть записана как generation первого приобретения
- **AND** ownership relation SHALL храниться в persistent generation state

### Requirement: ERL-VOC-009 — Deprecated Vocabulary is excluded from active lookup and deduplication

Deprecated Vocabulary MUST NOT участвовать в active lookup или deduplication.

#### Scenario: Deprecated Vocabulary matches lexical identity

- **GIVEN** deprecated Vocabulary имеет совпадающую lexical identity
- **WHEN** ERL выполняет active Vocabulary lookup или deduplication
- **THEN** deprecated Vocabulary SHALL быть исключена из active lookup и deduplication

### Requirement: ERL-VOC-010 — Deprecated history does not prevent new active Vocabulary

Если historical Vocabulary для lexical identity является deprecated, новая active generation MUST иметь возможность создать новую canonical Vocabulary для той же lexical identity.

#### Scenario: Lexical identity returns after historical Vocabulary was deprecated

- **GIVEN** historical Vocabulary для lexical identity является deprecated
- **WHEN** новая active generation обрабатывает эту lexical identity
- **THEN** ERL SHALL разрешить создание новой active canonical Vocabulary для той же lexical identity
