# Changelog

## 0.1.2 - 2025-02-20

- Remove the deprecated `strip-empty-paragraphs` option from the bundled Pandoc defaults.

## 0.1.1 - 2023-01-08

- Pass the selected output directory to LibreOffice when converting ODT files to DOCX and PDF.

## 0.1 - 2023-01-03

- Run the Pandoc, LibreOffice, and pdfbook2 export pipeline asynchronously.
- Add a bundled LibreOffice reference document and allow note-local defaults and templates to override bundled resources.
- Add Windows cleanup support and stop the pipeline with a diagnostic when a conversion step fails.

## 0.0.1 - 2023-01-02

- Add the initial synchronous Pandoc export pipeline for ODT, Word, PDF, and short-edge A4 PDF booklets.
