# Changelog

## 0.0.5 - 2026-07-30

- Replaced deprecated `Qt.btoa` usage with UTF-8-safe Base64 encoding.

## 0.0.4 - 2022-01-02

- Stopped replacing already processed Markdown by transforming only the Markdown supplied to the preview hook.

## 0.0.3 - 2021-11-24

- Fixed diagram encoding by reading the original decrypted note text and encoding Mermaid source directly.

## 0.0.2 - 2021-11-23

- Decoded HTML entities and escaped characters before sending diagram source to Mermaid Ink.

## 0.0.1 - 2021-10-17

- Initial release rendering fenced Mermaid code blocks as images through the Mermaid Ink service.
