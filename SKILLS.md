# SKILLS.md — Patterns and lessons for QOwnNotes script development

## QOwnNotes API gotchas

### Focus after custom actions
After any `customActionInvoked` handler that writes to the editor, the keyboard focus is stolen by the toolbar/menu button.
**Fix:** always end `customActionInvoked` with:
```javascript
mainWindow.focusNoteTextEdit();
```
`script.noteTextEditSetFocus()` does **not** exist and throws `TypeError` (confirmed on v26.5.14).

### noteToMarkdownHtmlHook performance
This hook runs on every keystroke in live preview. Avoid inside it:
- `new RegExp(...)` — recompiles the regex each call. Pre-compile in `init()` and store as `property variant`.
- `script.platformIsWindows()` — cache result in `init()` as `property bool _isWindows`.
- Constant string concatenations — extract as `property string`.
- `(?:.|\n)*?` — catastrophically slow on large HTML; use `[\s\S]*?` instead.

Pattern for pre-compiled regex with `g` flag (stored as property):
```javascript
// in init():
_urlAttrRe = /(\b(?:src|href|data-[\w-]+)\s*=\s*)(["'])([^"']+)\2/gi;

// in noteToMarkdownHtmlHook():
_urlAttrRe.lastIndex = 0;   // mandatory reset before each replace()
mdHtml = mdHtml.replace(_urlAttrRe, ...);
```

### handleNewNoteHeadlineHook — parameter is a plain string
`handleNewNoteHeadlineHook(headline)` receives the headline as a **plain string** (the search term
or QOwnNotes default text), NOT a Note object. `headline.noteText`, `headline.fileCreated`, etc.
are all `undefined`.

- Returning `null` → QOwnNotes shows its own built-in headline dialog.
- Returning a real string → that string becomes the note content, no dialog.
- If `headline` is non-empty, a source (search or QOwnNotes own dialog) already provided it —
  use it directly. If empty, ask the user.

```javascript
function handleNewNoteHeadlineHook(headline) {
    var name = headline !== "" ? headline : newNamer("New note", "New note title", "Title");
    return buildHeadline(name);
}
```

### handleNoteTextFileNameHook — note.noteText holds the headline hook's return value
`handleNoteTextFileNameHook(note)` receives a proper Note object. `note.noteText` contains the
content returned by `handleNewNoteHeadlineHook`. `note.fileCreated` equals `"Invalid Date"` only
at the moment of creation; use this to block file renaming after creation:

```javascript
if (note.fileCreated != "Invalid Date") {
    return "";
}
```

### buildHeadline / extractTitle symmetry
When a script both formats a headline and derives a file name from it, keep the two functions
symmetric — one adds markup, the other strips it — so title and file name are always consistent:

```javascript
function buildHeadline(name) {
    if (headingStyle === "1") return name + "\n" + "=".repeat(name.length);
    return "# " + name;
}
function extractTitle(noteText) {
    var first = (noteText || "").split("\n")[0];
    if (headingStyle === "1") return first;       // setext: bare title
    return first.slice(2);                        // ATX: strip "# "
}
```

### Hook execution order on note creation
`handleNewNoteHeadlineHook` → `handleNoteTextFileNameHook` → `noteOpenedHook`

### settingsVariables always require a script engine reload
All setting types (boolean, string, selection) take effect only after reloading the script engine.
There is no live-update mechanism. Do not try to work around this in code — just document it.

### QML property types for JS objects
Use `property variant` for RegExp, Array, and markdown-it instances.
Default values that require JS expressions (regex literals, `new`) must be set in `init()`, not inline:
```qml
property variant _headRe   // set in init(), not here
```

### markdown-it inline rules: fast-fail pattern
Inline rules are tried at every character position. Add a charCode fast-fail before any `slice()` + `exec()`:
```javascript
var ch = src.charCodeAt(pos);
if (!((ch >= 0x41 && ch <= 0x5a) || (ch >= 0x61 && ch <= 0x7a)))
    return false;
```

### JS bundled files in QML
Extra `.js` files must export via a top-level `var`, not ESM:
```javascript
var myExport;
(function(f){ /* UMD wrapper */ myExport = f(); })(...);
```
They are imported in QML as:
```qml
import "my-lib.js" as MyLib
// usage: MyLib.myExport
```

### script.noteTextEditSetSelection + noteTextEditWrite
These two work together to replace a range:
```javascript
script.noteTextEditSetSelection(lineStart, lineEnd);
script.noteTextEditWrite(newLine);
```
The cursor ends after the inserted text. There is no dedicated "replace range" API.

### Heading toggle pattern
```javascript
var sameLevelRe = new RegExp("^" + markers + "\\s+.*?\\s+" + markers + "\\s*$");
var newLine = sameLevelRe.test(line) ? content : markers + " " + content + " " + markers;
```
Toggle off if already at the requested level, otherwise apply.

## info.json conventions

- `identifier` and `script` must exactly match the folder/file name.
- `minAppVersion`: use the current QOwnNotes version when unsure.
- Extra JS/QML files go in `resources` array.
- `platforms` list only platforms actually tested.

## Formatting

- `.qml` files: `qmlformat -i` (runs automatically on commit via pre-commit hook).
- `.js`/`.json`/`.md`: `prettier` (also runs on commit).
- Never add comments that describe *what* the code does; only add comments for non-obvious *why* (hidden constraints, workarounds).

## Testing

```sh
just test   # validates info.json and script structure across all scripts
```

There are no unit tests for script logic — manual testing in QOwnNotes is required for rendering and UI behaviour.
