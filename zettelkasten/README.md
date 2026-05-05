# Zettelkasten for QOwnNotes

A QOwnNotes script that adds [Zettelkasten](https://en.wikipedia.org/wiki/Zettelkasten) support: unique IDs for notes and permanent wiki-links that survive note renames.

## Concept

In the Zettelkasten method, each note carries a **permanent unique ID** embedded in its content or filename. Links between notes are based on this ID, not on the filename. This means a note can be renamed freely without breaking any link pointing to it.

This script implements that principle inside QOwnNotes using the native `[[filename|id]]` wiki-link format. You will need to activate Settings>Interface>Editor>'Enable wiki-style link support [[note name]]'.

## Usage

- **Scripting › Insert Zettelkasten ID** — Insert a new unique ZK ID at the cursor position
- **Scripting › insert Zettelkasten link** — Open a searchable dialog to pick a note and insert a `[[filename\|id]]` link
- **Scripting › Repair Zettelkasten links** — can all notes and repair every link whose filename is out of date

You can also link those actions to a custom shortcut.

## Link format

```
[[MyNote|20260430143012]]
```

- The left part (`MyNote`) is what QOwnNotes uses to resolve the link (Ctrl+click to open). Only the note name is used — subfolder paths are never included, because QOwnNotes resolves wiki-links by filename regardless of the folder the note is in.
- The right part (`20260430143012`) is the permanent ZK ID, used by this script to repair links when the filename changes.

## Actions

Three toolbar buttons are registered, following the custom actions listed above:

| Button      | Action                                                                       |
| ----------- | ---------------------------------------------------------------------------- |
| **ZK-ID**   | Insert a new unique ZK ID at the cursor position                             |
| **ZK-Link** | Open a searchable dialog to pick a note and insert a `[[filename\|id]]` link |
| **ZK-Fix**  | Scan all notes and repair every link whose filename is out of date           |

## ID format

IDs are generated from the current date and time using a configurable format string.

Available tokens:

| Token | Value          |
| ----- | -------------- |
| `%Y`  | 4-digit year   |
| `%M`  | 2-digit month  |
| `%D`  | 2-digit day    |
| `%h`  | 2-digit hour   |
| `%m`  | 2-digit minute |
| `%s`  | 2-digit second |

Examples:

| Format                     | Result              |
| -------------------------- | ------------------- |
| `%Y%M%D%h%m%s` _(default)_ | `20260430143012`    |
| `id%Y%M%Dx%h%m%s`          | `id20260430x143012` |
| `%Y-%M-%D`                 | `2026-04-30`        |

## ID detection

When searching for a note's ZK ID, the script checks the **filename** first, then the full **note body**. Only the first match is used.

The detection pattern is a configurable ECMAScript regex. The default `\d{14}` matches any 14-digit timestamp. If you use a custom format with a prefix (e.g. `id%Y%M%Dx%h%m%s`), update the regex accordingly — for example `id\d{8}x\d{6}`.

## Rename resilience

When you rename a note in QOwnNotes, any `[[oldName|id]]` links in other notes become stale. This script fixes them automatically in two ways:

- **Automatic** — when you open the renamed note, the script silently rewrites every backlink pointing to it with the new filename. This happens in the background with no interruption.
- **Manual** — click **ZK-Fix** at any time to repair all stale links across the entire vault in one pass.

> **Note:** QOwnNotes may show a native dialog asking whether to replace link occurrences after a rename. That dialog does not understand the `[[filename|id]]` format and will not change anything. You can safely click _No_ and let this script handle it, or disable the dialog entirely in _Settings → Notes_.

## Settings

All settings are accessible in _Settings → Scripting → Zettelkasten_:

| Setting                            | Default        | Description                                                          |
| ---------------------------------- | -------------- | -------------------------------------------------------------------- |
| ID generation format               | `%Y%M%D%h%m%s` | Format string for new IDs                                            |
| ID detection pattern               | `\d{14}`       | ECMAScript regex to locate IDs in filenames and content              |
| Auto-repair backlinks on note open | enabled        | Automatically fix stale backlinks when a note with a ZK ID is opened |
