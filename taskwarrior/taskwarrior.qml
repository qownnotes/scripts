import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * This script is used for manual interaction with Taskwarrior by either
 * importing tasks from a certain project, or exporting them from a note.
 */
QtObject {
    /**
     * Initializes the custom actions
     */
    function init() {
        // export selected data to Taskwarrior 
        script.registerCustomAction("exportToTaskwarrior", "Export selected list as Taskwarrior tasks", "Export to Taskwarrior");

        // create a menu entry "Create meeting note" with a button and a freedesktop theme icon
        // script.registerCustomAction("importFromTaskwarrior", "Import tasks from Taskwarrior as a list", "Import from Taskwarrior");
    }

    /**
     * This function is invoked when a custom action is triggered
     * in the menu or via button
     * 
     * @param identifier string the identifier defined in registerCustomAction
     */
    function customActionInvoked(identifier) {

        switch (identifier) {
            // export selected lines to Taskwarriors as tasks.
            // The project name will be taken from "Project:" keyword detected in first lines.
            case "exportToTaskwarrior":
                // Get selected text and separate it by lines.
                
                var text = script.noteTextEditSelectedText();
                var separatedByLines;
                // Consider Windows different newline method.
                if (script.platformIsWindows()) {
                    separatedByLines = text.split('\r\n');
                } else {
                    separatedByLines = text.split('\n');
                }
                
                // Starting with an empty default project name.
                var projectName;
                
                // For each line, we are gathering data to properly create tasks.
                separatedByLines.forEach(function (line){
                    // We are trying to get the name of the project. 
                    // To do so, we are getting the substring of a line by using regexp group.
                    var projectRegExp = /project:[\s*]?(.+)?[\s*]?/i;
                    var isProjectNameLine = projectRegExp.exec(line);
                    if (isProjectNameLine) {
                        projectName = isProjectNameLine[1];
                        // We expect, that the project name would be the only thing in line, hence `return`.
                        return;
                    }
                    
                    // We are trying to get the task description.
                    // It should be started with either - (minus) or * (asterisk) to indicate list item.
                    var taskRegExp = /[\*\-][\s*]?(.+)[\s*]?/; 
                    var taskDescription;
                    
                    var isTask = taskRegExp.exec(line);
                    if (isTask) {
                        taskDescription = isTask[1];
                        script.log(taskDescription);
                        script.startDetachedProcess("/usr/bin/task",
                                                    [
                                                        "add",
                                                        "pro:" + projectName,
                                                        taskDescription
                                                    ]);
                        // We expect, that the task description would be the only thing in the line, hence `return`.
                        return;
                    }
                });
        }
    }
}
