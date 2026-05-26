# New note namer

Sets the note title and file name at creation time, with optional dialogs for each field.
Especially useful when the _Allow note file name to be different from note title_ option is enabled in QOwnNotes.

## Settings

| Setting                                    | Description                                                                         |
| ------------------------------------------ | ----------------------------------------------------------------------------------- |
| **Show a dialog to define the note title** | If checked, a dialog asks for a custom title (pre-filled with the search term).     |
| **Show a dialog to define the file name**  | If checked, a dialog asks for a custom file name (pre-filled with the search term). |
| **Heading style**                          | Format applied to the title: ATX (`# Title`), Setext (`Title / =====`), or Custom.  |
| **Custom heading – opening tag**           | Text inserted before the title (Custom style only).                                 |
| **Custom heading – closing tag**           | Text inserted after the title (Custom style only).                                  |

The two dialog options are independent: each defaults to the search term, regardless of the other.

## Behaviour

| Source           | Dialog: note title | Dialog: file name | Title                        | File name                                   |
| ---------------- | ------------------ | ----------------- | ---------------------------- | ------------------------------------------- |
| Search "foo"     | ☐                  | ☐                 | `# foo`                      | `foo`                                       |
| Search "foo"     | ☑                 | ☐                 | dialog pre-filled with `foo` | `foo` (search term, independent from title) |
| Search "foo"     | ☐                  | ☑                | `# foo`                      | dialog pre-filled with `foo`                |
| Search "foo"     | ☑                 | ☑                | dialog pre-filled with `foo` | dialog pre-filled with `foo`                |
| Menu (no search) | —                  | ☐                 | dialog (no pre-fill)         | = entered title                             |
| Menu (no search) | —                  | ☑                | dialog (no pre-fill)         | dialog pre-filled with entered title        |

> **Note:** the `n:` search prefix (name-only filter) is automatically stripped from the note name.

## Tips

- Leave both dialogs unchecked for a fully automatic workflow: create a note directly from the search bar with one keypress.
- Check only _file name_ to keep the search term as the title but write a longer or different file name.
- Check only _title_ to write a custom heading while keeping the file name equal to the search term.
- The heading style applies in all cases, including when no dialog is shown.
- All settings require a **script engine reload** to take effect after being changed.

## Upgrading from v0.0.2

v0.0.2 had a single boolean setting **Underline heading** that chose between ATX (`# Title`) and Setext (`Title / =====`).
This was replaced by the **Heading style** selection in v0.0.3.

Your stored preference is migrated automatically:

| v0.0.2 setting | Effective heading style after upgrade |
| -------------- | ------------------------------------- |
| Unchecked (default) | ATX (`# Title`) — no change |
| Checked | Setext (`Title / =====`) — preserved via the deprecated toggle |

The deprecated **Underline heading (deprecated)** entry remains visible in the script settings so QOwnNotes can still read your stored value.
Once you have set **Heading style** to your preferred option you can safely uncheck the deprecated toggle.
