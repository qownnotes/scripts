# Text Snippets

Insert reusable text snippets into your notes via a selection dialog.

## Usage

- **Scripting › Insert snippet** — choose a snippet from the list and insert it at the cursor
- **Scripting › Manage snippets** — add, edit, or delete snippets

You can also link those actions to a custom shortcut.

## Actions

One toolbar button is registered:

| Button      | Action                                                     |
| ----------- | ---------------------------------------------------------- |
| **Snippet** | choose a snippet from the list and insert it at the cursor |

## Placeholders

Placeholders are replaced at insertion time.

### Date & time

| Placeholder                 | Example output           |
| --------------------------- | ------------------------ |
| `$CURRENT_YEAR`             | `2026`                   |
| `$CURRENT_YEAR_SHORT`       | `26`                     |
| `$CURRENT_MONTH`            | `04`                     |
| `$CURRENT_MONTH_NAME`       | `April` (locale système) |
| `$CURRENT_MONTH_NAME_SHORT` | `Apr` (locale système)   |
| `$CURRENT_DATE`             | `29`                     |
| `$CURRENT_HOUR`             | `14`                     |
| `$CURRENT_MINUTE`           | `07`                     |
| `$CURRENT_SECOND`           | `03`                     |
| `$CURRENT_SECONDS_UNIX`     | `1745920023`             |

### Identifiants

| Placeholder | Exemple                                |
| ----------- | -------------------------------------- |
| `$UUID`     | `550e8400-e29b-41d4-a716-446655440000` |
| `$ZK_ID`    | `20260430143012` (format configurable) |

### Note context

| Placeholder      | Example output |
| ---------------- | -------------- |
| `$NOTE_TITLE`    | `My note`      |
| `$NOTE_FILENAME` | `my-note.md`   |

## Zettelkasten integration

`$ZK_ID` generates a Zettelkasten ID using the format string syntax documented
below. Configure **Zettelkasten ID format** in _Settings → Scripting → Text
Snippets_ to match the token format you use for your Zettelkasten IDs.

| Token | Value          |
| ----- | -------------- |
| `%Y`  | 4-digit year   |
| `%M`  | 2-digit month  |
| `%D`  | 2-digit day    |
| `%h`  | 2-digit hour   |
| `%m`  | 2-digit minute |
| `%s`  | 2-digit second |

## Exemple

```
## $CURRENT_MONTH_NAME $CURRENT_DATE, $CURRENT_YEAR

$ZK_ID

#tag
```
