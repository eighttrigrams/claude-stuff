---
name: rhizome-books
description: Modelling of books inside Rhizome's native data model
---

Rhizome models data by design as a full on graph. We have nodes and edges. Full stop.
Everything can be connected to everything.

There are no constraints in place, only markers of distinction on Items
and Relationships which control user interface behaviour and help users
manage things by providing leightweight semantics. The first thing here
is the Context / Item distinction. Every Context is an Item, but not the other way
around. Contexts can be separately searched and as such one might find them easier
(a nuance here is that for specific reasons there exists also a means of excluding
Contexts from global search).

Books are hierarchical and linear, that is, they come in tree shape. Usually
they have chapters, and then pages. A specific book is modelled as a Context,
and each individual Chapter in turn is modelled as a Context as well. A book
then contains those chapters, as well as all pages. In turn, every page, belongs
to a specific chapter, and to the book.

Sometimes there is a third layer. For example, there could be named sections below
the chapter level. In this case, every individual named section belongs to a specific
chapter, and the book. A page, then, belongs to the specific named section, to the chapter,
and to the book.

When I say "belongs to" that means one item "contains" another item, which matches
tree structure or collection semantics. In such cases, the lower down item (source) points to
the higher up item (target) in a unidirectional relation of which the lower down item is the owner
(for technical reasons).

Schem for the book (example):
- title: The Book
- is-context: true

The scheme for chapters is (example):
- title: Chapter 1 - The Chapter Title
- subtitle: Chapter 1
- sort-idx: 1
- is-context: true
- hide-in-global-search: true

The scheme for named sections is (example):
- title: 1.5 - The Named Section Title
- subtitle: Section 1.5
- sort-idx: 5 [Enumerate the named sections withing the chapters even if they are not enumerated in and by themselves per the book's structure]
- is-context: true
- hide-in-global-search: true

The scheme for a page is (example):
- title: p.137 Bla Bla blub bla… [truncated to 80 characters]
- sort-idx: 137

Here is, by example, our canonical way of preparing a book for ingest:

```yaml
title: The True and Only Heaven
subtitle: Progress and Its Critics
author: Christopher Lasch
contents:
- title: Preface
  page: 13
- chapter: 1
  title: "Introduction: The Obsolescence of Left and Right"
  sections:
  - {title: "The Current Mood", page: 21, id: 48768}
  - {title: "Limits: The Forbidden Topic", page: 22, id: 48769}
  - {title: "The Making of a Malcontent", page: 25, id: 48770}
  - {title: "The Land of Opportunity: A Parent's View", page: 31, id: 48771}
  - {title: "The Party of the Future and Its Quarrel with \"Middle America\"", page: 35, id: 48772}
  - {title: "The Promised Land of the New Right", page: 38, id: 48773}
  page: 21
  id: 48767
```

How many levels we want to capture is up to the human. For example,
books come often in "parts". If the human wants to capture that,
we insert that level between the book itself and its chapters, with the consequence
that every subordinate item, like a page, also would be associated to a part.
