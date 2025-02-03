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

        let pastCommands = JSON.parse(script.getPersistentVariable('aiCommand/pastCommands', '[]'));
        let command = script.inputDialogGetItem("AI Command", "Please enter a command", pastCommands, 0, true);

        if (command === '') {
            return;
        }

        // Remove any existing occurrences of command
        pastCommands = pastCommands.filter(cmd => cmd !== command);

        // Add command to the beginning
        pastCommands.unshift(command);

        // Trim the array to the last 15 entries
        pastCommands = pastCommands.slice(0, 15);

        script.setPersistentVariable('aiCommand/pastCommands', JSON.stringify(pastCommands));
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
