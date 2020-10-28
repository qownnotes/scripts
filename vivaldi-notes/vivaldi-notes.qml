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
    }

    /**
     * This function is invoked when a custom action is triggered
     * in the menu or via button
     *
     * @param identifier string - the identifier defined in registerCustomAction
     */
    function customActionInvoked(identifier) {
        if (identifier !== "importVivaldiNotes") {
            return;
        }

        var notesFilePath = script.getOpenFileName("Select Vivaldi notes file", "", "");
        var notesData = script.readFromFile(notesFilePath);

        var rootItem = JSON.parse(notesData);
        importItem(rootItem, "");
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
}
