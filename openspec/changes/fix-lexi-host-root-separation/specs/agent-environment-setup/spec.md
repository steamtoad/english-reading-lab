## ADDED Requirements

### Requirement: ERL-AGENT-SETUP-012 — Setup materializes and repairs the Lexi root binding

Lexi setup MUST принимать или детерминированно разрешать local `ERL_HOME` и `ERL_HOST_HOME`, показывать оба effective canonical paths в dry-run и записывать согласованный local runtime contract только после explicit apply.

Для текущего deployment rendered configuration MUST задавать:

```text
ERL_HOME=/Users/steamtoad/pub/english-reading-lab
ERL_HOST_HOME=/Users/steamtoad/dev/zettelkasten-cli
```

Setup check MUST проверять generated `TOOLS.md`, common skill contract, семь reference copies, embedded payload и effective target-home host contract. Ни один из них MUST NOT назначать `/Users/steamtoad/zettelkasten` как Lexi Vault или ERL host root.

Если существующий `.state/erl/host-contract.json` содержит stale либо forbidden `host_root`, default dry-run/check MUST сообщить conflict без mutation. Replacement MUST требовать explicit apply/replacement consent, сохранить recoverable byte-exact backup, опубликовать новый contract атомарно и выполнить post-check. Failure MUST восстановить pre-apply bytes либо оставить явный recovery-required journal.

#### Scenario: Clean setup renders the required paths

- **GIVEN** setup выполняется для текущего Lexi deployment без local managed configuration
- **WHEN** пользователь запускает dry-run, затем explicit apply
- **THEN** dry-run SHALL показать оба exact effective roots
- **AND** apply SHALL materialize target Vault binding `/Users/steamtoad/pub/english-reading-lab`
- **AND** apply SHALL materialize host implementation binding `/Users/steamtoad/dev/zettelkasten-cli`

#### Scenario: Existing host contract points to the user Vault

- **GIVEN** `.state/erl/host-contract.json` содержит `host_root: /Users/steamtoad/zettelkasten`
- **WHEN** setup выполняет default dry-run или check
- **THEN** setup SHALL сообщить forbidden stale-host-root conflict
- **AND** файл SHALL остаться byte-for-byte неизменным

#### Scenario: User explicitly replaces the stale host contract

- **GIVEN** пользователь просмотрел plan замены stale host contract
- **WHEN** пользователь отдельно подтверждает replacement apply
- **THEN** setup SHALL создать recoverable backup исходного contract
- **AND** новый effective `host_root` SHALL быть `/Users/steamtoad/dev/zettelkasten-cli`
- **AND** post-check SHALL подтвердить root separation и полный managed payload

#### Scenario: Root-binding replacement fails

- **GIVEN** replacement apply начал обновление local root binding
- **WHEN** write, validation или publication завершается ошибкой
- **THEN** setup SHALL восстановить exact pre-apply configuration либо опубликовать recovery-required journal
- **AND** completed setup state SHALL NOT сообщать успешную новую конфигурацию

#### Scenario: Reference or payload reintroduces the user Vault

- **GIVEN** skill reference, `TOOLS.md` template либо embedded payload назначает `/Users/steamtoad/zettelkasten` target или host root
- **WHEN** development synchronization validation запускается
- **THEN** validation SHALL завершиться ошибкой с именем drifted artifact
- **AND** completion и archive Change SHALL оставаться заблокированными
