import QtQml 2.0
import com.qownnotes.noteapi 1.0

/**
 * This script creates a custom action to italicize selected text using single underscores
 */
QtObject {
    /**
     * Initializes the custom action
     */
    function init() {
        script.registerCustomAction("italicize", "Italicize selected text using underscores", "Italicize text", "format-text-italic");
    }

    function addItalics(text) {
        var italics = text.replace(/^(.*)$/, "_$1_");
        return italics;
    }

    /**
     * This function is invoked when a custom action is triggered
     * in the menu or via button
     *
     * @param identifier string the identifier defined in registerCustomAction
     */
    function customActionInvoked(identifier) {
        if (identifier != "italicize") {
            return;
        }

        // get the selected text from the note text edit
        var text = script.noteTextEditSelectedText();
        // write text to the note text edit
        script.noteTextEditWrite(addItalics(text));
    }
}
