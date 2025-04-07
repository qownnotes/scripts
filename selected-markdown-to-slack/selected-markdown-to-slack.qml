import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * This script creates a menu item and a button that converts the selected Markdown-text
 * to Markdown-text that is better understood by Slack (https://slack.com) in the clipboard
 */
Script {

    /**
     * This function is invoked when a custom action is triggered
     * in the menu or via button
     *
     * @param identifier string the identifier defined in registerCustomAction
     */
    function customActionInvoked(identifier) {
        if (identifier != "markdownToSlack") {
            return;
        }

        // get the selected text from the note text edit
        var text = script.noteTextEditSelectedText();

        // remove unordered lists
        //        text = text.replace(/^-/gm, "");
        //        text = text.replace(/\t-/gm, "");

        // change links
        text = text.replace(/<(http.+?)>/mg, "\$1");
        text = text.replace(/\[(.+?)\]\((http.+?)\)/mg, "\$1 (\$2)");

        // put the result into the clipboard
        script.setClipboardText(text);
    }
    /**
     * Initializes the custom action
     */
    function init() {
        script.registerCustomAction("markdownToSlack", "Markdown to Slack", "Slack", "edit-copy", true, true);
    }
}
