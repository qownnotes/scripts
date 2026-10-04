# `quick-commands`

This is an augmented re-implementation of the QOwnNotes `quick-commands` script.

## How does it work

When this script is enabled, you can use the QOwnNotes auto-completion feature with a number of predefined completions.

| key          | value                                    |
|:-------------|:-----------------------------------------|
| `\today`     | Formatted current date and time          |
| `\tomorrow`  | Formatted date and time of tomorrow      |
| `\yesterday` | Formatted date and time of yesterday     |
| `\week`      | Formatted week                           |
| `\now`       | 2026-10-01T17:04:01                      |
| `\u`_XXXX_   | Unicode character with code point _XXXX_ |

For date and time, a popup will allow choosing one of:
* `01-10` (day month)
* `01-10-2026` (day month year)
* `2026-10-01` (year month day)
* `2026-10-01T17:09:59` (ISO 8601)
* `Thursday 1 October 2026 17:10:17`

For week, a popup will allow choosing one of:
* `40-2026` (ISO week number and year)
* `w40-2026` (ISO week number and year)

For Unicode code points, the value _XXXX_ must be exactly four hexadecimal characters.

## Custom completions

In the script settings dialog, you can add your own completions. For example:
```
app  qownnotes
```
Then `\app` can be completed to `qownnotes`. Multiple completions can be given as space separated words. If a completion must embed spaces you can enclose it with `""`, for example:
```
thisapp  qownnotes "QOwnNotes 26.9"
```
Case matters:
```
App  qownnotes
```
Now `\App` will complete to `Qownnotes`. Yes, you see that good, if
the command starts with an uppercase letter the result will have its
first letter uppercased too.

Custom completions may contain escaped newline and Unicode characters, e.g.
```
smile smile\u263a\nand again
```

### Placeholders

 In the completions you can use a number of _placeholders_ to obtain substitutions for actual date and time values (table adapted from [QOwnNotes](https://www.qownnotes.org/scripting/methods-and-objects.html#formatting-dates-and-times):

| Placeholder   | Meaning | Example                                |
| :----------- | :---------------------|:-------------- |
| `{yyyy}`        | Year with four digits                 | 2026      |
| `{yy}`          | Year with two digits                  | 26        |
| `{MM}`          | Month with leading zero               | 09        |
| `{M}`           | Month without leading zero            | 9         |
| `{MMM}`         | Abbreviated localized month name      | Sep       |
| `{MMMM}`        | Full localized month name             | September |
| `{dd}`          | Day with leading zero                 | 05        |
| `{d}`           | Day without leading zero              | 5         |
| `{ddd}`         | Abbreviated localized day name        | Tue       |
| `{dddd}`        | Full localized day name               | Tuesday   |
| `{HH}`          | Hour (0-23) with leading zero         | 07        |
| `{hh}`          | Hour with leading zero (1-12 with AP) | 07        |
| `{mm}`          | Minute with leading zero              | 04        |
| `{ss}`          | Second with leading zero              | 09        |
| `{AP}` / `{ap}` | AM/PM or am/pm                        | AM        |
| `{w}` | ISO week number without leadign zero | 5 |
| `{ww}` | ISO week number with leadign zero | 05 |
| `{LC:locale}` | Use the given locale | `{LC:nl_NL}`|
| `{+:offset}` | Offsets the date to the future | `{+:1D}` |
| `{-:offset}` | Offsets the date to the past | `{-:1D}` |

The date offsets may be a number of days, as shown above, or a number of milliseconds. `1D` is equivalent to `86400000`.

For example, the dutch version of tomorrows full date/time:

```
morgen "{lc:nl_NL}{+:1D}{dddd} {d} {MMMM} {yyyy} {hh}:{mm}:{ss}"
```
