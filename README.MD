# Zettelkasten-CLI

**Русский** | **English**

---

# Русский

## Описание

Zettelkasten-CLI — это попытка сделать систему управления знаниями настолько простой, насколько это вообще возможно.

Здесь нет собственного формата хранения, сложной внутренней структуры или обязательного графического интерфейса. Есть обычный каталог с текстовыми файлами, Git и набор shell-скриптов, которые автоматизируют рутинную работу.

Проект построен вокруг нескольких простых идей:

* знания должны храниться локально;
* заметки должны оставаться обычными текстовыми файлами;
* Git лучше встроенной истории изменений;
* shell лучше скрытой автоматизации;
* UUID никогда не должен меняться.

В основе проекта лежат:

* AsciiDoc;
* Git;
* zsh;
* Vim;
* философия Unix.

Все основные документы хранятся в виде обычных файлов:

```text
UUID.adoc
```

UUID одновременно является:

* идентификатором документа;
* именем файла;
* целью внутренних ссылок.

---

## Модель знаний

В основе системы лежит простая цепочка:

```text
Topic
   └── Memo
          └── Note
```

### Topic

Ключевая тема предметной области.

Она определяет направление развития знаний и объединяет связанные документы.

### Memo

Рабочая заметка.

Memo накапливает материалы, идеи и промежуточные выводы.

### Note

Законченная единица знания.

Note считается наиболее устойчивым типом документа и обычно переживает несколько поколений Topic.

---

## Развитие знаний

Со временем Topic начинают разрастаться.

Вместо бесконечного редактирования старой темы система использует операцию **Reduce**.

Reduce создаёт новое поколение Topic, сохраняя историю развития предметной области.

Во время Reduce:

* создаётся новая Topic;
* старая Topic становится deprecated;
* связанные Memo становятся deprecated;
* Note остаются активными;
* активные Note автоматически связываются с новой Topic;
* поколения Topic связываются ссылками:

```text
Развитие:
Основано на:
```

После повторных Reduce в предметной области остаётся одна активная Topic, а вся история сохраняется внутри хранилища.

---

## Управляемые навыки

Проект документирует не только пользовательские знания, но и собственное устройство.

Для этого используется трёхуровневая модель authority и связанная с ней
история пояснительных редакций:

```text
AGENTS.md
        ↓
managed zettelkasten-* skills
        ↓
scripts + requirements
        ↘
        подробные Note revisions
```

Каждый top-level `zt-*.zsh` имеет собственный управляемый OpenClaw-навык.
Исторический каталог `.agent-skills` сохранён только как read-only архив и не
участвует в runtime routing.

Managed skills находятся вне Git-репозитория. Совместимая с текущим checkout
редакция фиксируется в `.scripts/docs/managed-skills.adoc` и проверяется через
`zt-skills-review.zsh`. Интерактивные creation scripts являются механическим
reference для agent workflow, но до появления `zcreate --no-edit` не считаются
unattended deterministic primitives.

При изменении поведения создаётся новая редакция подробной Note, а предыдущая переводится в состояние `:deprecated:`.

Таким образом сам проект развивается теми же механизмами, которыми развивается пользовательская база знаний.


# English

## Description

Zettelkasten-CLI is an attempt to keep knowledge management as simple as possible.

There is no proprietary storage format, mandatory graphical interface, or hidden internal structure. The repository is just a directory with plain text files, Git history, and a collection of shell scripts that automate routine work.

The project is built around a few simple ideas:

* knowledge should remain local;
* notes should remain plain text;
* Git is better than built-in history;
* shell is better than hidden automation;
* UUIDs should never change.

The system is based on:

* AsciiDoc;
* Git;
* zsh;
* Vim;
* the Unix philosophy.

Every main document is stored as:

```text
UUID.adoc
```

A UUID is simultaneously:

* the document identifier;
* the filename;
* the target of internal links.

---

## Knowledge Model

The core structure is intentionally simple:

```text
Topic
   └── Memo
          └── Note
```

Topic represents a domain.

Memo accumulates working material.

Note represents durable knowledge and is expected to survive multiple Topic generations.

---

## Knowledge Evolution

As Topics grow, they eventually become difficult to maintain.

Instead of endlessly rewriting them, the system provides the **Reduce** operation.

Reduce creates a successor Topic while preserving the complete history of the domain.

Old Topics and related Memo become deprecated, Notes remain active, and active Notes are automatically linked to the new Topic.

This allows the knowledge base to evolve without losing its past.

---

## Managed Skills

The repository documents not only user knowledge but also its own behaviour.

It follows a three-level authority model with an adjacent explanatory revision
history:

```text
AGENTS.md
        ↓
managed zettelkasten-* skills
        ↓
scripts + requirements
        ↘
        detailed Note revisions
```

Every top-level `zt-*.zsh` script has one managed OpenClaw skill. The historical
`.agent-skills` directory is retained only as a read-only archive and is not
part of runtime routing.

Managed skills live outside the Git repository. The revision compatible with
the current checkout is recorded in `.scripts/docs/managed-skills.adoc` and
verified by `zt-skills-review.zsh`. Interactive creation scripts are mechanical
references for agent workflows, but are not unattended deterministic primitives
until `zcreate --no-edit` exists.

When behaviour changes, a new detailed Note revision is created and the previous one becomes deprecated.

The project therefore evolves using the same mechanisms that it uses for knowledge management.
