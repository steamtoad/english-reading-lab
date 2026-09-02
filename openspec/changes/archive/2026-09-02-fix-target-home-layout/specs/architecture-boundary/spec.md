## MODIFIED Requirements

### Requirement: ERL-ARCH-009 — ERL source, host source and target home are independent

ERL source location, host implementation location и target Zettelkasten home MUST быть независимыми filesystem roots.

ERL executables MUST NOT требовать, чтобы production host core implementation или пользовательские canonical documents находились внутри ERL repository или `ERL_HOME`.

Canonical host operations MUST разрешаться через host contract, предоставляемый целевым Zettelkasten host, а destination для persistent documents и ERL state MUST разрешаться как target Zettelkasten home.

#### Scenario: ERL and host use different filesystem roots

- **GIVEN** ERL repository и целевой Zettelkasten host/Vault находятся в разных filesystem roots
- **WHEN** ERL operation требует canonical host object или library operation
- **THEN** operation SHALL использовать host contract, предоставляемый целевым host/Vault
- **AND** operation SHALL NOT требовать `.scripts/objects/`, `.scripts/lib/` или `.scripts/zettelkasten/` внутри ERL repository
- **AND** различие ERL repository root и host/Vault root SHALL считаться нормальной поддерживаемой конфигурацией

#### Scenario: ERL, host and data use different filesystem roots

- **GIVEN** ERL repository, Zettelkasten host implementation и target Zettelkasten home находятся в разных filesystem roots
- **WHEN** ERL operation требует canonical host object или library operation
- **THEN** operation SHALL использовать host contract, предоставляемый целевым host
- **AND** persistent output SHALL направляться в target Zettelkasten home
- **AND** operation SHALL NOT требовать production host implementation или user data внутри ERL repository

#### Scenario: Required host contract is unavailable

- **GIVEN** целевой host не предоставляет обязательную часть host contract
- **WHEN** ERL пытается выполнить operation, зависящую от этой capability
- **THEN** ERL SHALL завершить operation с явной diagnostic error
- **AND** ERL SHALL NOT silently fallback к bundled, vendored или repository-relative production copy host implementation
- **AND** deficiency SHALL обрабатываться согласно `ERL-ARCH-008`
