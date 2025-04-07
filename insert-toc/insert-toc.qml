import QtQml 2.2
import QOwnNotesTypes 1.0

/// Extract a 'table of contents' from the current note's headings and insert
/// it into the note.

Script {
    property variant settingsVariables: [
        {
            "identifier": "tocTitle",
            "name": "Title of the table of contents",
            "description": "",
            "type": "string",
            "default": "Table of Contents"
        },
        {
            "identifier": "tocLinks",
            "name": "Generate links to sections",
            "description": "",
            "type": "boolean",
            "default": false
        },
    ]
    property bool tocLinks
    property string tocTitle

    function customActionInvoked(action) {
        if (action == "insertToc") {
            var lines = script.currentNote().noteText.split("\n");
            var toc = extractTOC(lines);
            toc = normalizeDepths(toc);

            script.noteTextEditWrite("\n" + tocTitle + "\n\n");
            var indexByDepth = {};
            for (var n = 0; n < toc.length; n++) {
                indexByDepth[toc[n].depth] = 0;
            }
            var lastDepth = 0;
            for (var n = 0; n < toc.length; n++) {
                var depth = toc[n].depth;
                var title = toc[n].title;
                var link = toc[n].link;
                if (depth > lastDepth) {
                    indexByDepth[depth] = 1;
                } else {
                    indexByDepth[depth] += 1;
                }
                lastDepth = depth;

                if (tocLinks) {
                    script.noteTextEditWrite(indent(depth) + indexByDepth[depth] + ". [" + title + "](#" + link + ")\n");
                } else {
                    script.noteTextEditWrite(indent(depth) + indexByDepth[depth] + ". " + title + "\n");
                }
            }
        }
    }
    function extractLink(title) {
        var lowercase = title.toLowerCase();
        var spaceReplaced = lowercase.replace(/ /g, "-");
        var invalidCharsRemoved = spaceReplaced.replace(/[^0-9A-Za-zÀ-ÿ-_]/g, "");
        return invalidCharsRemoved;
    }
    function extractTOC(lines) {
        var toc = [];
        for (var n = 0; n < lines.length; n++) {
            var match = lines[n].match(/^(#+)\s+(.*)$/);
            if (match) {
                toc.push({
                    "depth": match[1].length,
                    "title": match[2].trim(),
                    "link": extractLink(match[2].trim())
                });
            }
        }
        return toc;
    }
    function indent(depth) {
        var s = "";
        for (var i = 0; i < depth; i++) {
            s += "    ";
        }
        return s;
    }
    function init() {
        script.registerCustomAction("insertToc", "Insert TOC", "TOC", "", true);
    }
    function normalizeDepths(toc) {
        var min = -1;
        for (var n = 0; n < toc.length; n++) {
            var depth = toc[n].depth;
            if (min < 0 || depth < min) {
                min = depth;
            }
        }
        for (var n = 0; n < toc.length; n++) {
            toc[n].depth -= min;
        }

        return toc;
    }
}
