# Changelog

## 0.1.3 - 2024-08-01

- Fixed QML property assignments so the configured API URL, discovered models, and chat-completions endpoint are used correctly.

## 0.1.2 - 2024-06-18

- Fixed a missing variable declaration while processing the Ollama model response.

## 0.1.1 - 2024-06-18

- Handled an unavailable Ollama API without attempting to parse an empty response.

## 0.1.0 - 2024-06-18

- Added automatic discovery of models installed in the local Ollama service whenever the scripting engine reloads.

## 0.0.3 - 2024-06-16

- Removed the unnecessary API-key setting for the local Ollama backend.
- Renamed the script to clarify that it provides an AI backend integration.
- Raised the minimum QOwnNotes version to 24.6.3.

## 0.0.2 - 2024-06-15

- Corrected the Ollama API endpoint configuration.

## 0.0.1 - 2024-06-14

- Added the local Ollama backend integration with configurable API URL and model list.
