import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * This script creates a custom action to create a new blank note with no headline or other text.
 */
QtObject {
    function customActionInvoked(identifier) {
        if (identifier != "blankNote") {
            return;
        }

        var headline = script.inputDialogGetText("line edit", "Note title", "");

        var text = "";
        var subFolder = getSubfolder();
        var filePath = subFolder + script.dirSeparator();
        var fileName = headline + ".md";
        script.writeToFile(filePath + fileName, text);

        // Force a reload of the note list
        mainWindow.buildNotesIndexAndLoadNoteDirectoryList(true, true);

        var note = script.fetchNoteByFileName(fileName);
        script.setCurrentNote(note);
        script.log("New blank note created: " + filePath + fileName);
    }

    /**
     * This function is invoked when a custom action is triggered
     * in the menu or via button
     *
     * @param identifier string the identifier defined in registerCustomAction
     */

    function getSubfolder() {
        var noteSubFolderQmlObj = Qt.createQmlObject("import QOwnNotesTypes 1.0; NoteSubFolder{}", mainWindow, "noteSubFolder");
        var subFolder = noteSubFolderQmlObj.activeNoteSubFolder();
        return subFolder.fullPath();
    }
    /**
     * Initializes the custom action
     */
    function init() {
        script.registerCustomAction("blankNote", "Create a new blank note", "Blank note", "document-new");
    }
}
