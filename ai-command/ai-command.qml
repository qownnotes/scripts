import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * This script allows just send a written command  to the AI completer to replace the selected text, but showing the differences first.
 */
Script {
    /**
     * Initializes the custom actions
     */
    function init() {
        script.registerCustomAction("run-ai-command", "AI Command", "", "network-server-database", true, true, false);
    }

    /**
     * This function is invoked when a custom action is triggered
     * in the menu or via button
     *
     * @param identifier string the identifier defined in registerCustomAction
     */
    function customActionInvoked(identifier) {
        if (identifier !== "run-ai-command") {
            return;
        }

        let command = script.inputDialogGetText("AI Command", "Please enter a command");

        if (command === '') {
            return;
        }

        const text = script.noteTextEditSelectedText();
        const aiResult = script.aiComplete(
            "Execute the following command on the Markdown text afterwards, just output the result. " +
            command + ":\n\n" + text);
        let dialogResult = script.textDiffDialog("AI Command", "Resulting text", text, aiResult);

        if (dialogResult === '') {
            return;
        }

        script.noteTextEditWrite(dialogResult);
    }
}
