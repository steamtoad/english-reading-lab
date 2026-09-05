# English Reading Lab

## Русский

### Что это

English Reading Lab (ERL) помогает подготовиться к чтению сложных книг на английском языке.

### Какую проблему решает

При чтении основной барьер часто создаёт незнакомая лексика. ERL помогает заранее разобраться со словами и выражениями, которые встретятся именно в выбранной книге.

### Как это работает

ERL обрабатывает книгу по главам, выделяет сложную лексику, сохраняет её в персональный словарь и учитывает уже известные слова.

В результате перед чтением каждой главы у вас есть подготовленный набор нужной лексики в контексте книги.

### Настройка

ERL работает вместе с Zettelkasten.

После установки проекта выполните:

```bash
.scripts/erl/erl-check.zsh
```

Для настройки агента Lexi:

```bash
.scripts/erl/dev/erl-openclaw-agent-setup.zsh \
  --workspace "$PWD" \
  --user-name Саша \
  --timezone Europe/Sofia \
  --apply
```

---

## English

### What is it?

English Reading Lab (ERL) helps you prepare for reading difficult books in English.

### What problem does it solve?

Unknown vocabulary is often the main barrier to fluent reading. ERL helps you learn the words and expressions that actually appear in the book you are about to read.

### How does it work?

ERL processes a book chapter by chapter, extracts difficult vocabulary, stores it in your personal vocabulary, and reuses words you already know.

Before reading each chapter, you get a focused set of relevant vocabulary in the context of the book.

### Setup

ERL works together with Zettelkasten.

After installing the project, run:

```bash
.scripts/erl/erl-check.zsh
```

To configure the Lexi agent:

```bash
.scripts/erl/dev/erl-openclaw-agent-setup.zsh \
  --workspace "$PWD" \
  --user-name Sasha \
  --timezone Europe/Sofia \
  --apply
```
