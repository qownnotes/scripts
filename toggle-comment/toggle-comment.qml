import QtQml 2.0
import com.qownnotes.noteapi 1.0

/**
 * This script creates a custom action to comment or uncomment the current Markdown line
 */
QtObject {

    /**
     * This function is invoked when a custom action is triggered
     * in the menu or via button
     *
     * @param identifier string the identifier defined in registerCustomAction
     */
    function customActionInvoked(identifier) {
        if (identifier != "toggle-comment") {
            return;
        }

        script.noteTextEditSelectCurrentLine();
        var line = script.noteTextEditSelectedText();
        if (/^\[\/\/\]: #/.test(line)) {
            script.noteTextEditWrite(unsetComment(line));
        } else {
            script.noteTextEditWrite(setComment(line));
        }
    }
    /**
     * Initializes the custom action
     */
    function init() {
        script.registerCustomAction("toggle-comment", "Comment/uncomment the current line", "Comment/uncomment", "edit-comment");
    }
    function setComment(line) {
        var commented = line.replace(/^(.*)$/, "[//]: # ($1)");
        return commented;
    }
    function unsetComment(line) {
        var uncommented = line.replace(/^\[\/\/\]: # \((.*)\)$/, "$1");
        return uncommented;
    }
}
