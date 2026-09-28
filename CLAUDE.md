# CLAUDE.md — QOwnNotes scripts workspace

## Working conventions

- **Always write responses and reports in English**, regardless of the language the user uses to ask.

## Repository layout

```
luginf/
  qownnotes-scripts/   ← fork of https://github.com/qownnotes/scripts (working directory)
    <script-name>/     ← one directory per script (kebab-case)
      <name>.qml       ← main script (same name as directory)
      info.json        ← script metadata
    AGENTS.md          ← contributor guide (read this first)
    CLAUDE.md          ← this file
    justfile           ← task runner
    devenv.nix         ← dev environment with pre-commit hooks
```

Active scripts authored by @luginf: **txt2tags-it**, **zettelkasten**, **snippets**.
Scripts contributed to by @luginf: **new-note-namer**.

Current branch: `snippets-zettelkasten-doc` (documentation updates for snippets and zettelkasten).

## Language and tooling

- Scripts are written in **QML** (Qt Modeling Language) with embedded JavaScript (Qt V4 engine — ES5/ES6 subset, no `import`/`export`, no Node APIs).
- Extra JS files bundled as `resources` in `info.json` must use `var`-level exports (not ESM) so they are accessible from QML via module qualifier (e.g., `import "markdown-it.js" as MarkdownIt`).
- Formatter: `qmlformat` for `.qml`, `prettier` for `.js`/`.json`/`.md` — run automatically on commit via pre-commit hooks.
- Test suite: `just test` (PHP, validates `info.json` structure and script layout).

## QOwnNotes scripting API — key facts

- `script` global: most API methods (`script.log()`, `script.noteTextEditWrite()`, `script.registerCustomAction()`, …).
- `mainWindow` global: UI-level methods. **`mainWindow.focusNoteTextEdit()`** restores keyboard focus to the editor after a custom action — `script.noteTextEditSetFocus()` does NOT exist.
- `init()` is called once on script load. Store heavy initialisation (regex compilation, platform detection) here.
- `noteToMarkdownHtmlHook(note, html, forExport)` is called on **every preview refresh** (every keystroke in live mode) — keep it fast.
- `customActionInvoked(identifier)` is called when a toolbar/menu action fires. Always call `mainWindow.focusNoteTextEdit()` at the end to return focus to the editor.
- Custom actions are registered with `script.registerCustomAction(id, menuText, buttonText, icon, useInToolbar, checkable, checked)`.
- **`handleNewNoteHeadlineHook(headline)`** — `headline` is a **plain string** (the search term or default text), NOT a Note object. Accessing `headline.noteText`, `headline.fileCreated`, etc. gives `undefined`. Return the desired note content as a string; returning `null` causes QOwnNotes to show its own built-in headline dialog.
- **`handleNoteTextFileNameHook(note)`** — `note` IS a Note object. `note.fileCreated` equals `"Invalid Date"` only at the moment of creation; use this to gate file-name changes on creation only. `note.noteText` holds the content returned by `handleNewNoteHeadlineHook`.
- **`settingsVariables` always require a script engine reload** to take effect — this applies to all setting types (boolean, string, selection). There is no live-update mechanism.
- Hook execution order on note creation: `handleNewNoteHeadlineHook` → `handleNoteTextFileNameHook` → `noteOpenedHook`.
- Full API reference: https://www.qownnotes.org/scripting/methods-and-objects.html
- Exposed classes (NoteApi, etc.): https://www.qownnotes.org/scripting/classes.html

## new-note-namer script specifics

`new-note-namer/` sets the note title and file name at creation time.

**Behaviors:**
- **Creating from search**: the search term is used directly as the title — no dialog.
- **Creating from menu**: a dialog asks for the title (pre-filled empty).
- **`extraDialogForFileName`**: in both cases, shows a second dialog to enter a file name different from the title, pre-filled with the derived title.
- **`headingStyle`**: `"0"` ATX (`# Title`), `"1"` Setext (`Title / =====`), `"2"` Custom (with `customHeadingOpen`/`customHeadingClose` tags).

**Key implementation details:**
- `handleNewNoteHeadlineHook(headline)`: if `headline` is non-empty (search term or QOwnNotes own dialog), use it directly; if empty (menu creation without prior prompt), show dialog. Returns `buildHeadline(name)`.
- `handleNoteTextFileNameHook(note)`: derives file name via `extractTitle(note.noteText)`, which strips heading markers according to `headingStyle`. If `extraDialogForFileName`, shows dialog pre-filled with the result.
- `buildHeadline(name)` / `extractTitle(noteText)`: symmetric functions — one adds heading markup, the other strips it.

## txt2tags-it script specifics

`txt2tags-it/` renders notes using **markdown-it** (bundled v8.4.2) augmented by a custom plugin (`markdown-it-txt2tags.js`) adding txt2tags syntax:

| Syntax | Output |
|--------|--------|
| `= H1 =` … `===== H5 =====` | headings |
| `//italic//` | `<em>` |
| `__underline__` | `<u>` |
| `--strikethrough--` | `<del>` |
| `+ item` lines | ordered list |
| `% comment` | silently consumed |
| `[[wikilink]]`, `[[wikilink\|label]]` | note links |
| `[label url]` | bare links |

Performance notes:
- Regexes used in `noteToMarkdownHtmlHook` are pre-compiled in `init()` and stored as `property variant` (`_headRe`, `_urlAttrRe`).
- Platform check (`_isWindows`) and constant CSS string (`_cssInject`) are also cached in `init()`.
- `_urlAttrRe.lastIndex = 0` must be reset before each `replace()` call because it is a stored global regex.
- The `txt2tags_autolink` inline rule has a fast-fail letter check to avoid `src.slice(pos)` at non-letter positions.

## Workflow

```sh
just          # list all recipes
just test     # run test suite
just format   # format all files
just git-create-patch   # export staged changes as patch to Nextcloud Transfer
just git-apply-patch    # apply patch from Nextcloud Transfer
```

Patch workflow is used to move changes between machines via Nextcloud.
