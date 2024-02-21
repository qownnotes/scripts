import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * Script that expands selection to the current line for fast editing purposes
 */
Script {
    /**
     * Initializes the custom actions
     */
    function init() {
        script.registerCustomAction("expandSelectionToLine", "Expand Selection To Line");
    }

    function customActionInvoked(action) {
         /**
          * Locates the current line and expands selection to it
          */
         if (action == "expandSelectionToLine") {
             // selects the current line
             script.noteTextEditSelectCurrentLine();
             // expands the selection to fit the line
             script.noteTextEditSetSelection(
                 script.noteTextEditSelectionStart(),
                 script.noteTextEditSelectionEnd());
         }
    }
}

