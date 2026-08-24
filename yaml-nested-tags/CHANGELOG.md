# Changelog

## 0.0.6 - 2020-05-31

- Update the Markdown HTML hook signature for QOwnNotes 20.6.0 export compatibility.

## 0.0.5 - 2020-05-12

- Rewrite YAML front matter parsing and updates to reliably create and modify the tags field and either supported closing delimiter.

## 0.0.3 - 2020-05-10

- Support Windows line endings when reading YAML front matter.

## 0.0.2 - 2020-05-02

- Remove obsolete note-name hooks and noisy tag-operation debug logging.

## 0.0.1 - 2020-05-01

- Add synchronization between QOwnNotes nested tags and a YAML front matter `tags` field.
- Support configurable hierarchy separators and `---` or `...` YAML closers while hiding front matter from previews.
