# AGENTS.md — QOwnNotes Script Repository

## What this repository is

This is the official community script repository for [QOwnNotes](https://www.qownnotes.org) — a plain-text Markdown notepad with Nextcloud/ownCloud integration.
Scripts extend the application using **QML (Qt Modeling Language)** and are distributed through the in-app script manager.

Each script lives in its own subdirectory and consists of at minimum:

- A `.qml` file — the script implementation
- An `info.json` file — metadata describing the script

## Repository structure

```
<script-name>/          # One directory per script, kebab-case name
    <script-name>.qml   # Main QML script file (same name as directory)
    info.json           # Script metadata
    tests/              # Optional Qt Quick Test suite
example-script/         # Template/reference for new scripts
.shared/                # Shared just recipes
justfile                # Task runner (just)
.github/                # CI workflows and test scripts
```

## Creating a new script

1. **Copy** the `example-script/` directory and rename it to a descriptive kebab-case name (e.g. `my-new-feature/`).
2. **Rename** `example-script.qml` inside the folder to match the folder name (e.g. `my-new-feature.qml`).
3. **Edit** `info.json` to fill in the metadata (see below).
4. **Implement** the script in the `.qml` file.

### info.json fields

```json
{
  "name": "Human-readable script name",
  "identifier": "script-folder-name",
  "script": "script-folder-name.qml",
  "authors": ["@github-username"],
  "platforms": ["linux", "macos", "windows"],
  "version": "0.0.1",
  "minAppVersion": "17.06.2",
  "description": "What this script does."
}
```

- `identifier` must match the folder name exactly.
- `script` must match the `.qml` filename exactly.
- `minAppVersion`: use the [current QOwnNotes version](https://github.com/pbek/QOwnNotes/blob/main/src/version.h) if unsure.
- `platforms`: include only platforms the script is tested/supported on.

### QML script structure

```qml
import QtQml 2.0

Script {
    function init() {
        // Called when the script is loaded
    }

    // Add hook functions here as needed
}
```

See the [QOwnNotes scripting documentation](https://docs.qownnotes.org/en/latest/scripting/) for available hooks and API methods.

## Finding available commands / just recipes

Run `just` (with no arguments) to list all available recipes:

```sh
just
```

Key recipes:

| Recipe                  | Description                             |
| ----------------------- | --------------------------------------- |
| `just test`             | Run metadata validation and QML tests   |
| `just format`           | Format all files using pre-commit hooks |
| `just git-create-patch` | Create a patch from staged changes      |
| `just git-apply-patch`  | Apply a saved patch                     |

## Linting and formatting

Pre-commit hooks are configured in `.pre-commit-config.yaml` and run automatically on commit. They cover:

- **QML**: `qmlformat` (auto-formats `.qml` files)
- **JSON/Markdown/YAML/JS**: `prettier`
- **Nix**: `nixfmt`, `deadnix`, `statix`
- **Shell**: `shfmt`, `shellcheck`
- **PHP**: `php-cs-fixer`

To format everything manually: `just format`

## Testing

```sh
just test
```

The test command runs:

- `.github/workflows/scripts/run-tests.php` to validate `info.json` files and script structure.
- `.github/workflows/scripts/run-qml-tests.sh` to discover `<script-name>/tests` directories and run them with `qmltestrunner`.

### Writing script tests

Use [Qt Quick Test](https://doc.qt.io/qt-6/qtquicktest-index.html) for script-specific tests. Place test files in the script's `tests/` directory and name them `tst_*.qml` so `qmltestrunner` discovers them automatically:

```text
<script-name>/
    helper.js
    <script-name>.qml
    info.json
    tests/
        tst_helper.qml
```

Prefer extracting parsing and transformation logic into a side-effect-free JavaScript resource. Import the same resource from both the production script and its test:

```qml
import QtQuick 2.0
import QtTest 1.3
import "../helper.js" as Helper

TestCase {
    name: "Helper"

    function test_example() {
        compare(Helper.transform("input"), "expected");
    }
}
```

Additional `.js` files used by a script must be listed in the script's `info.json` under `resources`:

```json
{
  "resources": ["helper.js"]
}
```

Keep unit tests deterministic and avoid depending on the live QOwnNotes application. If application interaction must be tested, isolate calls to the global `script` object behind an injectable property and provide a small mock object in the test.

Run one script's tests directly with:

```sh
QT_QPA_PLATFORM=offscreen qmltestrunner -import "$QML_TEST_IMPORT_PATH" -input <script-name>/tests
```

Run `just test` before submitting changes; CI executes the same command in the devenv environment.

## Scripting API reference

Full API docs: <https://docs.qownnotes.org/en/latest/scripting/>

The `script` global object exposes methods like:

- `script.log(text)` — log output
- `script.registerCustomAction(identifier, menuText, ...)` — register menu actions
- `script.noteTextEditWrite(text)` — insert text into the editor
- and many more

Look at existing scripts in this repository for real-world usage patterns.
