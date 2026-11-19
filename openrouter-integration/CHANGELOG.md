# Changelog

## 0.1.1 - 2026-11-19

- Store new OpenRouter API keys as secret settings so QOwnNotes masks them in debug reports.
- If you configured a key in 0.1.0, revoke it and create a new one. Remove the script from QOwnNotes to clear the old plaintext setting, then reinstall it and enter the replacement key. Existing settings are not migrated.

## 0.1.0 - 2026-01-12

- Added an OpenRouter backend for QOwnNotes AI features using the OpenAI-compatible chat-completions API.
- Added settings for the API key, base URL, comma-separated model IDs, and optional site attribution headers.
- Added validation for missing credentials and empty model lists, plus setup documentation.
