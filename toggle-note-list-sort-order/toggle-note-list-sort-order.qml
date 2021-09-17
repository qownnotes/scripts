import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * This script toggles the sort order of the note list between 'Alphabetical' and 'By date'.
 */
Script {

    /**
     * Initializes the custom action
     */
    function init() {
        // https://www.qownnotes.org/scripting/methods-and-objects.html#registering-a-custom-action
        script.registerCustomAction("toggle-note-list-sort-order", "Toggle note list sort order", "", "", false, false, true);
    }

    /**
     * This function is invoked when a custom action is triggered
     * in the menu or via button
     *
     * @param identifier string - the identifier defined in registerCustomAction
     */
    function customActionInvoked(identifier) {
        if (identifier != "toggle-note-list-sort-order") {
            return;
        }

        var isSortOrderAlphabetical =
            script.getApplicationSettingsVariable("notesPanelSort", 1) == 0;
        script.triggerMenuAction(isSortOrderAlphabetical ?
            "actionBy_date" : "actionAlphabetical");
    }
}
