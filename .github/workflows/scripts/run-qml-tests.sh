#!/usr/bin/env bash

set -euo pipefail

if ! command -v qmltestrunner >/dev/null 2>&1; then
  printf 'qmltestrunner was not found in PATH\n' >&2
  exit 1
fi

shopt -s nullglob
test_directories=(*/tests)
qml_import_arguments=()

if [[ -n "${QML_TEST_IMPORT_PATH:-}" ]]; then
  qml_import_arguments=(-import "$QML_TEST_IMPORT_PATH")
fi

if [[ -n "${QML_TEST_FONTCONFIG_FILE:-}" ]]; then
  export FONTCONFIG_FILE="$QML_TEST_FONTCONFIG_FILE"
fi

if ((${#test_directories[@]} == 0)); then
  printf 'No QML tests were found\n'
  exit 0
fi

for test_directory in "${test_directories[@]}"; do
  printf 'Running QML tests in %s\n' "$test_directory"
  QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-offscreen}" qmltestrunner "${qml_import_arguments[@]}" -input "$test_directory"
done
