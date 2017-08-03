import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * This script adds a menu entry to the context menu of the note list to diff selected notes in an external diff program
 * The path of the diff program can be selected in the script settings of the script
 */
Script {
    property string executablePath;

    // register your settings variables so the user can set them in the script settings
    property variant settingsVariables: [
        {
            "identifier": "executablePath",
            "name": "Path of external mail client",
            "description": "Please select the path to the executable of your mail application:",
            "type": "file",
            "default": "thunderbird",
        }
    ];

    /**
     * Initializes the custom actions
     */
    function init() {
        script.registerCustomAction("sharebyemail", "Share by email", "", "", false, true, true);
    }

    /**
     * This function is invoked when a custom action is triggered
     * in the menu or via button
     * 
     * @param identifier string the identifier defined in registerCustomAction
     */
    function customActionInvoked(identifier) {
        if (identifier != "sharebyemail") {
            return;
        }
        
        // start the email programm with the selected note paths as parameters
        var params = script.selectedNotesPaths();
        script.startDetachedProcess(executablePath, params);
    }
}
