import QtQml 2.0
import QOwnNotesTypes 1.0
import com.qownnotes.noteapi 1.0

/**
 * This script exports all notes as HTML files
 */
Script {
    property bool useAbsolutePaths;

    property variant settingsVariables: [
        {
            "identifier": "useAbsolutePaths",
            "name": "Use absolute paths for links",
            "description": "Internal links will only work in the export folder (not recommended)",
            "type": "boolean",
            "default": false,
        }
    ];

    /**
     * Initializes the custom actions
     */
    function init() {
        script.registerCustomAction("exportWebsite", "Export notes as website",
            "", "applications-internet", false, true, true);
    }

    function getSubFolder(note, path) {
        var fileName = note.fullNoteFilePath;
        var pathRe = new RegExp(path + "\/((.*)\/)*.*");
        var subfolderName = fileName.replace(pathRe, "$2");
        return subfolderName;
    }

    /**
     * This function is invoked when a custom action is triggered
     * in the menu or via button
     * 
     * @param identifier string the identifier defined in registerCustomAction
     */
    function customActionInvoked(identifier) {
        if (identifier != "exportWebsite") {
            return;
        }

        var noteIds = script.fetchNoteIdsByNoteTextPart("");

        noteIds.forEach(function (noteId) {
            var note = script.fetchNoteById(noteId);
            var path = script.currentNoteFolderPath();
            var subFolder = getSubFolder(note, path);
            var noteName = note.name;
            var exportFolder = path + "/export/" + subFolder;
            script.startSynchronousProcess("mkdir", ["-p", exportFolder]);
            var exportPath = exportFolder + "/" + noteName + ".html";
            var noteHtml = note.toMarkdownHtml();
            var titleMatch = noteHtml.match(/<h1>(.*)<\/h1>/);
            var noteTitle = noteName;
            if (titleMatch) {
              noteTitle = titleMatch[1];
            }
            noteHtml = noteHtml.replace(/<head>/, "<head><title>" + noteTitle + "</title>");
            var linkRe = new RegExp("file://" + path + "/([^\"]+?)\.md", "g");
            if (useAbsolutePaths) {
                noteHtml = noteHtml.replace(linkRe, "file://" + path + "/export/$1.html");
            } else {
                noteHtml = noteHtml.replace(linkRe, function(_, linkPath) {
                    var parentDir = "";
                    if (subFolder != "") {
                        var depth = linkPath.split("/").length - 1;
                        if (depth == 0) {
                            depth ++;
                        }
                        for (var i = 0; i < depth; i++) {
                            parentDir += "../";
                        }
                    }
                    return parentDir + linkPath + ".html";
                });
            }
            script.writeToFile(exportPath, noteHtml);
            script.log("Successfully exported note: " + subFolder + "/" + note.name);
        });

        script.log("All notes succssfully exported!");
    }
}
