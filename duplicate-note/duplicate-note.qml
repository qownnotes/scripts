import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * This script duplicates the currently selected note
 *
 * The note copy will be created in the same folder.
 */
Script {

    /**
     * Initializes the custom actions
     */
    function init() {
        script.registerCustomAction("duplicateNote", "Duplicate selected note", "", "", false, true, true);
    }

    /**
     * This function is invoked when a custom action is triggered
     * in the menu or via button
     *
     * @param identifier string - the identifier defined in registerCustomAction
     */
    function customActionInvoked(identifier) {
        if (identifier != "duplicateNote") {
            return;
        }

        var currentNote = script.currentNote();
        script.createNote(currentNote.noteText);
    }
}
