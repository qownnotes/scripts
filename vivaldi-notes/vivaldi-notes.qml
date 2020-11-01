import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * This script allows for importing/exporting notes from/to Vivaldi browser
 *
 * Works with the 'Notes' files (from the Vivaldi Profile directory).
 */
Script {

    /**
     * Initializes the custom actions
     */
    function init() {
        script.registerCustomAction("importVivaldiNotes", "Import Vivaldi Notes", "Import Vivaldi Notes", "", false, false, false);
        script.registerCustomAction("exportVivaldiNotes", "Export Vivaldi Notes", "Export Vivaldi Notes", "", false, false, false);
    }

    /**
     * This function is invoked when a custom action is triggered
     * in the menu or via button
     *
     * @param identifier string - the identifier defined in registerCustomAction
     */
    function customActionInvoked(identifier) {
        if (identifier === "importVivaldiNotes") {
            var notesFilePath = script.getOpenFileName("Select Vivaldi notes file", "", "");
            var notesData = script.readFromFile(notesFilePath);
            var rootItem = JSON.parse(notesData);
            importItem(rootItem, "");
        } else if (identifier === "exportVivaldiNotes") {
            exportNotes();
        }
    }

    function importItem(item, currentPath) {
        if (currentPath !== "") {
            if (!script.jumpToNoteSubFolder(currentPath)) {
                script.log('failed to change subfolder to:' + currentPath);
            }
        }

        if (item.type == 'note') {
            script.createNote(item.subject !== "" ? (item.subject + "\n===\n" + item.content) : item.content);
        } else if (item.type == 'folder') {
            mainWindow.createNewNoteSubFolder(item.subject);
            for (var idx in item.children) {
                importItem(item.children[idx],
                           (currentPath === "" ? (item.subject) : (currentPath + "/" + item.subject)));
            }
        }
    }

    function exportNotes() {
        var filename = script.getSaveFileName("Select file to save notes to", "", "");
        if (filename === "") {
            script.log("Empty filename; abort note export operation");
            return;
        }

        var uniqueFoldername = "QOwnNotes-" + Date.now();

        var noteSubFolderQmlObj = Qt.createQmlObject("import QOwnNotesTypes 1.0; NoteSubFolder{}", mainWindow, "noteSubFolder");
        var rootSubFolder = noteSubFolderQmlObj.fetchNoteSubFolderById(0);

        var rootObj = {
            "subject": "Notes",
            "type": "folder",
            "children": [ 
                {
                "subject": uniqueFoldername,
                "type": "folder",
                "children": getNoteSubFoldersByParentId(0).concat(getNotesInNoteSubFolder(rootSubFolder))
                }
            ]
        };

        var saved = script.writeToFile(filename, JSON.stringify(rootObj));
        if (saved) {
            script.log('Successfully saved notes to ' + filename);
        } else {
            script.log('Failed to save notes to ' + filename);
        }
    }

    function getNoteSubFoldersByParentId(parentId) {
        var noteSubFolders = [];
        
        var noteSubFolderQmlObj = Qt.createQmlObject("import QOwnNotesTypes 1.0; NoteSubFolder{}", mainWindow, "noteSubFolder");

        noteSubFolderQmlObj.fetchNoteSubFoldersByParentId(parentId).forEach(function(noteSubFolder) {
            var noteSubFolderObj = {
                "subject": noteSubFolder.name,
                "type": "folder",
                "children": getNoteSubFoldersByParentId(noteSubFolder.id).concat(getNotesInNoteSubFolder(noteSubFolder))
            };

            noteSubFolders.push(noteSubFolderObj);
        });

        return noteSubFolders;
    }

    function getNotesInNoteSubFolder(noteSubFolder) {
        var notes = [];

        for (var idx in noteSubFolder.notes) {
            var note = noteSubFolder.notes[idx];

            var noteObj = {
                "subject": note.name,
                "type": "note",
                "content": note.noteText
            };

           notes.push(noteObj);
        }

        return notes;
    }

}
