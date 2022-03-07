QOwnNotes PlantUML support script
=====

## Render PlantUML Diagrams for QOwnNotes editor

This script for [QOwnNotes](https://www.qownnotes.org/) renders text based diagram descriptions into image files using the program [PlantUML](https://plantuml.com/).

![Example of diagram generated with the QownNotes and PlantUML](Demo.gif)

## Install

1. [Download PlantUML](https://plantuml.com/en/download) with GraphViz support.
2. Verify or install JAVA or OpenJDK.
3. If not installed, [install QownNotes](https://www.qownnotes.org/installation/).
4. In QOwnNotes, go to `Scripting`>`Find scripts in script repository` menu. And install `Support for PlantUML in notes`.
5. In the sript parameters configure the JAVA and `plantuml.jar` paths.  
 ![Script Parameters Screenshot showing the JAVA and PlanUML paths](Params.png)
7. Enjoy !

## Features

- Backround diagram rendering
- Cache system that renders only new or modified diagram descriptions
- Diagram rendering in PNG or SVG
- Context menu to add header/footer of most PlantUML diagram types

## Developpement

The script is developped on Github: https://github.com/qownnotes/scripts/tree/master/render-plantuml

Feel free to contribute.
