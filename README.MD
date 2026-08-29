# English Reading Lab

**Русский** | **English**

---

# Русский

## Описание

English Reading Lab — это проект для подготовки к чтению англоязычных книг через персональный словарь, построенный на базе Zettelkasten.

Проект использует готовый скриптовый движок Zettelkasten-CLI и рассматривает каждую книгу как отдельную предметную область для изучения английского языка.

Основная идея проста:

> перед чтением книги собрать сложную лексику в том порядке, в котором она впервые появляется в тексте, превратить её в связанные заметки и использовать получившуюся цепочку для подготовки к чтению.

Проект ориентирован прежде всего на лексику уровней:

* B2;
* C1;
* C2;

а также на:

* редкие слова;
* литературную лексику;
* архаизмы;
* фразовые глаголы;
* идиомы;
* устойчивые выражения;
* collocations;
* специфическую лексику конкретной книги.

Для каждого lexical item могут сохраняться:

* исходная форма в тексте;
* lemma;
* часть речи;
* уровень CEFR;
* транскрипция;
* перевод;
* определение;
* контекст первого появления;
* глава;
* порядок первого появления;
* связанные слова;
* синонимы;
* антонимы;
* устойчивые сочетания;
* ссылки на предыдущую и следующую карточку.

Проект строится вокруг нескольких принципов:

* книги остаются локальными файлами;
* словарь хранится в обычных AsciiDoc-документах;
* Git используется как история изменений;
* Zettelkasten является основной моделью хранения знаний;
* книга является темой, а vocabulary items — связанными с ней Note;
* порядок первого появления слов должен сохраняться;
* автоматизация должна оставаться прозрачной и воспроизводимой;
* агент не заменяет структуру данных и скрипты, а работает поверх них.

В основе проекта лежат:

* Zettelkasten-CLI;
* AsciiDoc;
* Git;
* zsh;
* OpenClaw;
* Unix CLI.

---

## Цель проекта

Основная задача English Reading Lab — уменьшить лексический барьер перед чтением сложной английской литературы.

Вместо изучения абстрактного списка английских слов проект строит словарь непосредственно из конкретной книги.

Таким образом подготовка соответствует будущему порядку чтения:

```text
Book
  ↓
Chapter
  ↓
First occurrence
  ↓
Vocabulary Note
  ↓
Next Vocabulary Note
```

Перед началом главы можно изучить именно те слова и выражения, которые встретятся в ней.

После этого книга становится не источником случайно возникающих незнакомых слов, а заранее подготовленным маршрутом изучения языка.

---

## Модель знаний

В основе проекта лежит модель Zettelkasten.

Книга рассматривается как главная тема:

```text
Book Topic
    │
    ├── Vocabulary Note
    ├── Vocabulary Note
    ├── Vocabulary Note
    └── ...
```

### Book

Book представляет отдельный study case.

Например:

```text
A Game of Thrones
```

Книга определяет:

* источник vocabulary;
* последовательность глав;
* порядок первого появления слов;
* контекст употребления;
* собственную цепочку vocabulary notes.

Одна книга может содержать тысячи связанных lexical items.

---

### Vocabulary Note

Vocabulary Note является самостоятельной единицей знания.

Одна Note соответствует одному lexical item:

```text
word
phrasal verb
idiom
collocation
fixed expression
```

Пример логической структуры:

```text
= Foreboding

:type: note
:description: foreboding
:cefr: C1
:lexical-type: word

Meaning
Translation
IPA
Context
Occurrences
Related vocabulary
Book links
```

Одна и та же Vocabulary Note может использоваться несколькими книгами.

Если слово уже существует в Zettelkasten, повторная встреча не требует создания дубликата.

Вместо этого существующая Note получает новую связь с источником.

---

## Книги как Study Cases

Исходные книги находятся внутри отдельной части репозитория.

Каждая книга получает собственный каталог.

Пример:

```text
books/
├── a-game-of-thrones/
├── a-clash-of-kings/
├── the-hobbit/
└── ...
```

Каталог книги содержит исходный материал и данные, относящиеся только к этому study case.

Vocabulary при этом не разделяется физически по каталогам книг.

Все vocabulary notes остаются частью общего Zettelkasten.

Это позволяет одной карточке участвовать сразу в нескольких книгах и постепенно формировать общий персональный словарь.

---

## Порядок первого появления

Одним из основных свойств проекта является сохранение порядка, в котором vocabulary впервые появляется в книге.

Для каждой книги формируется собственная последовательность:

```text
word 001
   ↓
word 002
   ↓
word 003
   ↓
word 004
```

Каждая Vocabulary Note может содержать ссылки на соседние элементы этой последовательности.

Например:

```text
Previous in A Game of Thrones:
link:UUID.adoc[...]

Next in A Game of Thrones:
link:UUID.adoc[...]
```

Таким образом vocabulary одной книги образует связанную цепочку, которую можно проходить последовательно перед чтением.

Одна Vocabulary Note может одновременно входить в несколько таких цепочек.

---

## Семантические связи

Кроме последовательности появления, vocabulary связывается по смыслу.

Например:

```text
foreboding
├── premonition
├── apprehension
├── ominous
└── unease
```

Могут использоваться связи:

* synonym;
* antonym;
* related word;
* derived word;
* collocation;
* phrasal verb;
* semantic group.

Таким образом словарь постепенно превращается из линейного списка в lexical knowledge graph.

---

## Главы

Глава используется как естественная граница подготовки к чтению.

Для каждой главы можно построить собственный vocabulary index:

```text
Chapter 1

B2: 42
C1: 18
C2: 3
Phrases: 11
Literary: 8
```

И далее последовательность vocabulary:

```text
1. deserted
2. foreboding
3. gaunt
4. defiance
5. ...
```

Это позволяет использовать модель:

```text
Prepare
   ↓
Read
   ↓
Review
```

Сначала изучается vocabulary главы.

Затем читается сама глава.

После чтения слова могут переходить в режим повторения.

---

## Архитектура обработки

Проект разделяет детерминированную обработку текста и работу языковой модели.

Механическая часть должна выполняться обычными скриптами:

```text
Book
  ↓
Text extraction
  ↓
Tokenization
  ↓
Normalization
  ↓
Occurrence detection
  ↓
First occurrence
  ↓
Candidate list
```

После этого специализированный агент обогащает данные:

```text
Candidate
  ↓
CEFR estimation
  ↓
Part of speech
  ↓
IPA
  ↓
Translation
  ↓
Definition
  ↓
Semantic relations
  ↓
Vocabulary Note
```

После работы агента данные снова проходят детерминированные проверки:

```text
Vocabulary Note
  ↓
Metadata validation
  ↓
Duplicate validation
  ↓
Link validation
  ↓
Sequence validation
  ↓
Index generation
```

Общий принцип:

```text
Scripts
   ↓
Agent
   ↓
Scripts
```

LLM отвечает за языковую интерпретацию.

Скрипты отвечают за структуру, порядок, ссылки и целостность данных.

---

## Lexi

Для English Reading Lab используется отдельный специализированный агент.

Рабочее имя агента:

```text
Lexi
```

Lexi не является универсальным персональным ассистентом.

Её предметная область ограничена:

```text
English Reading
+
Vocabulary Acquisition
+
Lexical Knowledge
```

Основные задачи Lexi:

* анализировать vocabulary candidates;
* определять lemma;
* классифицировать lexical item;
* оценивать уровень сложности;
* находить транскрипцию;
* формировать перевод;
* объяснять значение;
* находить semantic relations;
* создавать Vocabulary Note;
* связывать vocabulary с книгами;
* поддерживать lexical graph;
* проверять качество созданных карточек.

Lexi работает поверх существующего Zettelkasten-CLI и не заменяет его.

---

## OpenClaw

Lexi предполагается запускать как отдельного агента OpenClaw.

Агент получает собственный workspace, инструкции и ограниченный набор skills.

Принцип:

```text
OpenClaw
    │
    └── Lexi
          │
          ├── vocabulary extraction
          ├── vocabulary enrichment
          ├── vocabulary linking
          ├── vocabulary validation
          └── Zettelkasten CLI
```

Агент должен иметь только необходимые для своей предметной области возможности.

Это позволяет сделать его поведение более предсказуемым и воспроизводимым.

---

## Zettelkasten-CLI

English Reading Lab не создаёт новый механизм хранения заметок.

Вместо этого он использует существующий Zettelkasten-CLI как инфраструктурный слой.

Zettelkasten отвечает за:

* UUID;
* документы;
* AsciiDoc;
* ссылки;
* Topics;
* Notes;
* поиск;
* индексацию;
* проверки;
* Git workflow.

English Reading Lab добавляет поверх него специализированную lexical domain model.

Таким образом архитектура разделяется на два слоя:

```text
English Reading Lab
        ↓
Lexical domain model
        ↓
Zettelkasten-CLI
        ↓
AsciiDoc + Git + Unix
```

---

## Структура репозитория

Предполагаемая структура:

```text
english-reading-lab/
├── books/
│   ├── a-game-of-thrones/
│   ├── a-clash-of-kings/
│   └── ...
│
├── .scripts/
├── .scripts/lib/
├── .state/
├── skills/
├── all-todays/
├── AGENTS.md
├── README.md
└── UUID.adoc
```

Основные vocabulary notes находятся в общем пространстве Zettelkasten:

```text
UUID.adoc
```

Книга хранит только собственный исходный материал и book-specific данные.

---

## Первая книга

Первым study case проекта является:

```text
A Game of Thrones
George R. R. Martin
```

Задача первого этапа — построить vocabulary map книги, содержащую прежде всего лексику уровней B2, C1 и C2.

Первый study case также используется для разработки и проверки:

* модели Vocabulary Note;
* структуры Book Topic;
* порядка first occurrence;
* cross-links;
* semantic links;
* chapter indexes;
* Lexi skills;
* validation scripts.

После стабилизации модели тот же механизм должен применяться к другим книгам без изменения основной архитектуры.

---

# English

## Description

English Reading Lab is a project for preparing to read English-language books through a personal vocabulary system built on top of Zettelkasten.

The project uses the existing Zettelkasten-CLI scripting engine and treats every book as a separate study case.

The central idea is simple:

> extract difficult vocabulary before reading a book, preserve the order in which lexical items first appear, turn them into interconnected notes, and use the resulting sequence as a preparation path.

The project primarily targets:

* B2 vocabulary;
* C1 vocabulary;
* C2 vocabulary;

as well as:

* rare words;
* literary vocabulary;
* archaic vocabulary;
* phrasal verbs;
* idioms;
* fixed expressions;
* collocations;
* book-specific vocabulary.

A lexical item may contain:

* the original surface form;
* lemma;
* part of speech;
* CEFR level;
* IPA transcription;
* translation;
* definition;
* first-occurrence context;
* chapter;
* occurrence order;
* related vocabulary;
* synonyms;
* antonyms;
* collocations;
* previous and next links.

The project is built around several principles:

* books remain local files;
* vocabulary remains plain AsciiDoc;
* Git provides history;
* Zettelkasten provides the knowledge model;
* a book is a topic and vocabulary items are Notes;
* first-occurrence order must be preserved;
* automation should remain transparent and reproducible;
* agents operate on top of scripts and data structures rather than replacing them.

The system is based on:

* Zettelkasten-CLI;
* AsciiDoc;
* Git;
* zsh;
* OpenClaw;
* Unix CLI.

---

## Goal

The main goal of English Reading Lab is to reduce the lexical barrier before reading difficult English literature.

Instead of studying an abstract vocabulary list, the project derives vocabulary directly from a specific book.

The resulting preparation path follows the future reading order:

```text
Book
  ↓
Chapter
  ↓
First occurrence
  ↓
Vocabulary Note
  ↓
Next Vocabulary Note
```

Before reading a chapter, the reader can study exactly the vocabulary that will appear in that chapter.

---

## Knowledge Model

The project uses the existing Zettelkasten model.

A book acts as the main Topic:

```text
Book Topic
    │
    ├── Vocabulary Note
    ├── Vocabulary Note
    ├── Vocabulary Note
    └── ...
```

### Book

A Book represents one study case.

For example:

```text
A Game of Thrones
```

The Book defines:

* the vocabulary source;
* chapter sequence;
* first-occurrence order;
* usage context;
* its own vocabulary path.

---

### Vocabulary Note

A Vocabulary Note is an independent knowledge unit.

One Note represents one lexical item:

```text
word
phrasal verb
idiom
collocation
fixed expression
```

The same Vocabulary Note may be associated with several books.

When an existing lexical item appears in another book, no duplicate Note is required.

Instead, another source relationship is added to the existing Note.

Over time this creates a shared personal lexical knowledge base across multiple books.

---

## Books as Study Cases

Source books are stored in a dedicated part of the repository.

Each book receives its own directory:

```text
books/
├── a-game-of-thrones/
├── a-clash-of-kings/
├── the-hobbit/
└── ...
```

Book directories contain source material and data specific to that study case.

Vocabulary Notes are not physically separated by book.

They remain part of the shared Zettelkasten so that one lexical item can participate in several books and several semantic contexts.

---

## First-Occurrence Order

One of the central properties of the project is preservation of the order in which vocabulary first appears in a book.

Each book therefore creates its own sequence:

```text
word 001
   ↓
word 002
   ↓
word 003
   ↓
word 004
```

Vocabulary Notes may contain links to the previous and next lexical items in that sequence.

This creates a vocabulary path that can be studied before reading the corresponding part of the book.

A single Vocabulary Note may participate in several such paths at the same time.

---

## Semantic Links

Vocabulary is also connected semantically.

For example:

```text
foreboding
├── premonition
├── apprehension
├── ominous
└── unease
```

Relationships may include:

* synonyms;
* antonyms;
* related words;
* derived words;
* collocations;
* phrasal verbs;
* semantic groups.

The vocabulary therefore evolves from a linear list into a lexical knowledge graph.

---

## Chapters

A chapter is a natural preparation boundary.

Each chapter may have its own vocabulary index:

```text
Chapter 1

B2: 42
C1: 18
C2: 3
Phrases: 11
Literary: 8
```

The intended workflow is:

```text
Prepare
   ↓
Read
   ↓
Review
```

Vocabulary is studied first.

The chapter is read second.

Vocabulary can then enter a review workflow.

---

## Processing Architecture

English Reading Lab separates deterministic text processing from language-model reasoning.

Mechanical processing should be handled by scripts:

```text
Book
  ↓
Text extraction
  ↓
Tokenization
  ↓
Normalization
  ↓
Occurrence detection
  ↓
First occurrence
  ↓
Candidate list
```

The specialized agent then enriches lexical candidates:

```text
Candidate
  ↓
CEFR estimation
  ↓
Part of speech
  ↓
IPA
  ↓
Translation
  ↓
Definition
  ↓
Semantic relations
  ↓
Vocabulary Note
```

The generated data is then validated again by deterministic tooling:

```text
Vocabulary Note
  ↓
Metadata validation
  ↓
Duplicate validation
  ↓
Link validation
  ↓
Sequence validation
  ↓
Index generation
```

The overall principle is:

```text
Scripts
   ↓
Agent
   ↓
Scripts
```

The language model handles linguistic interpretation.

Scripts handle structure, ordering, links, validation, and reproducibility.

---

## Lexi

English Reading Lab uses a dedicated specialized agent.

Its working name is:

```text
Lexi
```

Lexi is not intended to be a general-purpose personal assistant.

Its bounded domain is:

```text
English Reading
+
Vocabulary Acquisition
+
Lexical Knowledge
```

Its responsibilities include:

* processing vocabulary candidates;
* identifying lemmas;
* classifying lexical items;
* estimating difficulty;
* providing IPA;
* producing translations;
* explaining meanings;
* discovering semantic relationships;
* creating Vocabulary Notes;
* linking vocabulary to books;
* maintaining the lexical graph;
* validating generated vocabulary data.

Lexi operates on top of Zettelkasten-CLI rather than replacing it.

---

## OpenClaw

Lexi is intended to run as a dedicated OpenClaw agent.

The agent has its own workspace, instructions, and restricted skill set.

Conceptually:

```text
OpenClaw
    │
    └── Lexi
          │
          ├── vocabulary extraction
          ├── vocabulary enrichment
          ├── vocabulary linking
          ├── vocabulary validation
          └── Zettelkasten CLI
```

The agent should only receive capabilities required for its domain.

This keeps its behaviour narrow, predictable, and reproducible.

---

## Zettelkasten-CLI

English Reading Lab does not introduce another note-storage engine.

It uses the existing Zettelkasten-CLI as its infrastructure layer.

Zettelkasten-CLI remains responsible for:

* UUIDs;
* documents;
* AsciiDoc;
* links;
* Topics;
* Notes;
* search;
* indexes;
* validation;
* Git workflow.

English Reading Lab adds a specialized lexical domain model on top.

The resulting architecture is:

```text
English Reading Lab
        ↓
Lexical domain model
        ↓
Zettelkasten-CLI
        ↓
AsciiDoc + Git + Unix
```

---

## Repository Structure

The intended repository structure is:

```text
english-reading-lab/
├── books/
│   ├── a-game-of-thrones/
│   ├── a-clash-of-kings/
│   └── ...
│
├── .scripts/
├── .scripts/lib/
├── .state/
├── skills/
├── all-todays/
├── AGENTS.md
├── README.md
└── UUID.adoc
```

Vocabulary Notes remain in the shared Zettelkasten namespace:

```text
UUID.adoc
```

Book directories contain only source material and book-specific data.

---

## First Study Case

The first study case is:

```text
A Game of Thrones
George R. R. Martin
```

The first stage of the project is to build a vocabulary map focused primarily on B2, C1, and C2 lexical items.

This first study case is also used to design and validate:

* the Vocabulary Note model;
* the Book Topic model;
* first-occurrence sequencing;
* cross-links;
* semantic links;
* chapter indexes;
* Lexi skills;
* validation scripts.

Once the model becomes stable, the same workflow should be reusable for other books without changing the core architecture.
