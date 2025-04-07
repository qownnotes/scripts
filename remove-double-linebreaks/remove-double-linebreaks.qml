import QtQml 2.2
import QOwnNotesTypes 1.0

/**
 * Toolbar button and context menu item to remove double linebreaks.
 */
Script {
    function customActionInvoked(action) {
        if (action === "remove-double-linebreaks") {
            var text = script.noteTextEditSelectedText();
            text = text.replace(/\n\n/gm, "\n");
            script.noteTextEditWrite(text);
        }
    }
    function init() {
        script.registerCustomAction("remove-double-linebreaks", "Remove double linebreaks", "\\n\\n", "edit-paste", true, true);
    }
}
