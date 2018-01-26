import QtQml 2.2
import QOwnNotesTypes 1.0

/// Extract a 'table of contents' from the current note's headings and insert 
/// it into the note.

Script { 
    property string tocTitle
    
    property variant settingsVariables: [
        {
            "identifier": "tocTitle",
            "name": "Title of the table of contents",
            "description": "",
            "type": "string",
            "default": "Table of Contents",
        },
    ]
    
    function init() {
        script.registerCustomAction("insertToc", "Insert TOC", "TOC", "", true)
    }
    
    function extractTOC(lines) {
        var toc = [];
        for (var n = 0; n < lines.length; n++) {
            var match = lines[n].match(/^(#+)\s+(.*)$/)
            if (match) {
                toc.push({
                    "depth": match[1].length,
                    "title": match[2].trim()
                });
            }
        }
        return toc;
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
    
    function indent(depth) {
        var s = "";
        for (var i = 0; i < depth; i++) {
            s += "    ";
        }
        return s;
    }
    
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
                if (depth > lastDepth) {
                    indexByDepth[depth] = 1;
                } else {
                    indexByDepth[depth] += 1;
                }
                lastDepth = depth;
                script.noteTextEditWrite(indent(depth) + indexByDepth[depth] + ". " + title + "\n");
            }
        }
    }
}
