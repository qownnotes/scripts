# Changelog

## 0.1.5 - 2023-08-01

- Replaced the image-format boolean with an explicit PNG or SVG selection.
- Corrected the working-directory setting to use a directory chooser.

## 0.1.4 - 2022-03-09

- Corrected malformed HTML tags in the package description.

## 0.1.3 - 2022-03-09

- Positioned the cursor inside newly inserted PlantUML templates.
- Expanded the package documentation for background rendering, caching, image formats, and setup.

## 0.1.2 - 2022-03-07

- Added context-menu templates for UML, Graphviz, JSON, YAML, Salt, Gantt, mind-map, and WBS diagrams.

## 0.1.1 - 2022-03-07

- Fixed native working-directory and image URL handling, notably for Windows paths.

## 0.1.0 - 2022-03-03

- Reworked rendering to run PlantUML asynchronously and removed the Node.js dependency.
- Added PNG and SVG output, configurable working directories, and a cache that renders only changed diagrams.
- Refreshed previews after background rendering without entering regeneration loops.

## 0.0.8 - 2020-05-31

- Updated the note HTML hook for QOwnNotes 20.6.0.

## 0.0.7 - 2020-03-02

- Adapted PlantUML extraction to QOwnNotes HTML escaping for quoted text and special characters.
- Preserved escaped line breaks and recognized existing PlantUML start and end directives.

## 0.0.6 - 2019-07-01

- Restored auto-tagged PlantUML start and end directives, including diagram types such as Gantt.
- Allowed apostrophes in generated diagram source.

## 0.0.5 - 2019-06-24

- Added compatibility with in-note auto-tagging by restoring or supplying `@startuml` and `@enduml` directives.

## 0.0.4 - 2018-05-01

- Fixed HTML entities in PlantUML source and prevented trailing preview HTML from being written into diagram files.

## 0.0.3 - 2018-02-14

- Generated every PlantUML diagram in a note in one process for improved performance.
- Documented the synchronous-rendering delay.

## 0.0.2 - 2018-02-13

- Added configurable arguments for the PlantUML JAR.
- Added an option to hide PlantUML source markup in the preview.
- Removed a developer-specific default PlantUML path.

## 0.0.1 - 2018-02-12

- Added rendering of fenced PlantUML source into images in the note preview.
