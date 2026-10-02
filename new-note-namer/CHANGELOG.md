# Changelog

## 0.0.6 - 2026-10-02

- Added a _Derive the file name from the note title_ setting, so the (default) file name follows the note title instead of the search term (#304).

## 0.0.5 - 2026-09-28

- Fixed the file-name prompt wrongly firing when an existing, not-yet-indexed note is edited and saved for the first time (#300). The rename logic now gates on a flag set only by the genuine new-note creation hook, instead of `note.fileCreated`.

## 0.0.4 - 2026-05-26

- Added independent title and filename dialog settings, with search terms used directly when dialogs are disabled.
- Added ATX, Setext, and custom heading styles while preserving the prior underline setting.
- Improved title extraction and default filename generation.

## 0.0.2 - 2024-11-28

- Added an option to create a Setext-style underlined heading instead of an ATX `#` heading.

## 0.0.1 - 2024-08-09

- Initial release allowing the note title and filename to be chosen when a note is created.
