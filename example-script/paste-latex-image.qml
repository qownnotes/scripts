import QtQml 2.0

/**
 * This script is just an example of how to use scripts
 * Visit http://docs.qownnotes.org/ for more information about scripting
 */
QtObject {
    /**
     * Just show some log entries when the script is initialized
     */
    function init() {
        script.log("This is just an example script.");
        script.log("Visit http://docs.qownnotes.org/ for more information about scripting.");
    }
}
