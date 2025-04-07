# Select Current Section

`select-section` is a script for the [amazing markdown notebook QownNotes](http://www.qownnotes.org/).

This script provides menu entries and icons meant **to select** (**or cut** to the clipboard) **the current section content**, header included.

A _section_ is all the content of a note between two headers of the same level. Mind that a section begins with its own header.  
The _current_ section is the section where the cursor is located at.

**Why Selecting (or cutting) the current section?** What for? For instance, I use the script to quickly organize my note content (move sections). It is especially useful when the note content is used as a slide deck for tools such as [Marp](https://marp.app/).

**Beware**: this script only works with [ATX standard markdown headers (headers beginning with several “#” defining the level)](https://github.com/chrisalley/markdown-garden/blob/master/source/guides/headers/atx-headers.md), not with [Setex headers (headers underlined with “=” or “-”)](https://github.com/chrisalley/markdown-garden/blob/master/source/guides/headers/setext-headers.md).
