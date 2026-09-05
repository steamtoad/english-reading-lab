## ADDED Requirements

### Requirement: ERL-HOST-002 — Platform support claims have executable evidence

Supported platform/host profiles MUST иметь versioned matrix и passing shared contract tests для file paths, UUID, AsciiDoc, parser, error handling и recovery. Missing или skipped profile MUST быть NOT VERIFIED/experimental и MUST NOT подменяться сертификатом от другой ОС.

#### Scenario: Linux was not exercised for a release

- **GIVEN** есть только macOS evidence
- **WHEN** публикуется release support matrix
- **THEN** Linux SHALL не маркироваться verified supported

#### Scenario: Different host revision is configured

- **GIVEN** doctor видит revision вне tested profiles
- **WHEN** оценивается readiness
- **THEN** он SHALL сообщить compatibility unknown и указать contract test, не угадывая совместимость
