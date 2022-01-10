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
        script.registerCustomAction("exportVivaldiNotes", "Export Vivaldi Notes", "Export Vivaldi Notes", "", false, false, true);
    }

    /**
     * This function is invoked when a custom action is triggered
     * in the menu or via button
     *
     * @param identifier string - the identifier defined in registerCustomAction
     */
    function customActionInvoked(identifier) {
        if (identifier === "importVivaldiNotes") {
            importNotes();
        } else if (identifier === "exportVivaldiNotes") {
            exportNotes();
        }
    }
    
    /* Notes import */
    
    function importNotes() {
        var notesFilePath = script.getOpenFileName("Select Vivaldi notes file", "", "");
        if (notesFilePath === "") {
            script.log("Empty filename; abort note import operation");
            return;
        }
        
        if (!script.fileExists(notesFilePath)) {
            script.log("Notes file does not exist; abort note import operation");
            return;
        }

        var notesData = script.readFromFile(notesFilePath);
        var rootItem;
        
        try {
            rootItem = JSON.parse(notesData);
        } catch (e) {
            script.log("Failed to parse Vivaldi notes file; abort note import operation");
            return;
        }
        
        importItem(rootItem, "");
    }

    function importItem(item, currentPath) {
        if (currentPath !== "") {
            if (!script.jumpToNoteSubFolder(currentPath)) {
                script.log('Failed to change subfolder to:' + currentPath);
            }
        }

        if (item.type == 'note') {
            var content = item.content;

            var subject;
            if (item.subject !== "") {
                subject = item.subject + "\n";
            } else {
                var subjectCandidate = content.match(".+\n");
                if (subjectCandidate.length !== 0) {
                    subject = subjectCandidate;
                } else {
                    subject = content.substring(0, Math.min(content.length, 50));
                }
            }
            subject += "===\n";

            var attachments = "";
            if (item.attachments) {
                attachments = '\n\n# Attachments\n';
                for (var idx in item.attachments) {
                    var attachment = "\n![attachment" + idx + "](" + item.attachments[idx].content + ")\n";
                    attachments += attachment;
                }
            }

            var noteData = subject + content + attachments;
            script.createNote(noteData);
        } else if (item.type == 'folder') {
            mainWindow.createNewNoteSubFolder(item.subject);
            for (var idx in item.children) {
                importItem(item.children[idx],
                           (currentPath === "" ? (item.subject) : (currentPath + "/" + item.subject)));
            }
        }
    }

    /* Notes export */

    function exportNotes() {
        var selectedNotesIds = script.selectedNotesIds();
        var numSelectedNotes = selectedNotesIds.length;
        var exportAllNotes = true;

        if (numSelectedNotes > 1) {
            var result = script.questionMessageBox(
                numSelectedNotes + " notes selected.<br/>Export all notes or only selected notes ?", "Export notes", 0x00000800|0x00001000, 0x00001000);

            if (result === 0x00000800) {
                exportAllNotes = false;
            }
        }

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
                "children": (exportAllNotes ?
                             getNoteSubFoldersByParentId(0).concat(getNotesInNoteSubFolder(rootSubFolder)) :
                             getSelectedNotes(selectedNotesIds))
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
    
    function getSelectedNotes(selectedNotesIds) {
        var notes = [];

        for (var idx in selectedNotesIds) {
            var noteId = selectedNotesIds[idx];
            var note = script.fetchNoteById(noteId);

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
