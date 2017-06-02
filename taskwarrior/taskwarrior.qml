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
        script.registerCustomAction("importFromTaskwarrior", "Import tasks from Taskwarrior as a list", "Import from Taskwarrior");
    }
    
    /**
     * Get selected text and separate it by lines.
     * 
     * @returns array of strings representing separate lines
     */
    function getSelectedTextAndSeparateByNewline() {
        var text = script.noteTextEditSelectedText();
        var separatedByLines;
        // Consider Windows different newline method.
        if (script.platformIsWindows()) {
            separatedByLines = text.split('\r\n');
        } else {
            separatedByLines = text.split('\n');
        }
        return separatedByLines;
    }

    /**
     * Parse input string to get the project name and run supplied function if found.
     * 
     * @param str input string which may contain project name
     * @param func function to be executed if the project name is found
     *
     * @returns boolean for if the project name was detected or not
     */
    function getProjectNameAndRun(str, func) {
        // We are trying to get the name of the project. 
        // To do so, we are getting the substring of a line by using regexp group.
        var projectRegExp = /project:[\s*]?(.+)?[\s*]?/i;
        var isProjectName = projectRegExp.exec(str);
        if (isProjectName) {
            func(isProjectName[1]);
            return true;
        }
    }

    /**
     * This function is invoked when a custom action is triggered
     * in the menu or via button
     * 
     * @param identifier string the identifier defined in registerCustomAction
     */
    function customActionInvoked(identifier) {

        var pathToTaskwarrior = "/usr/bin/task";

        switch (identifier) {
            // export selected lines to Taskwarriors as tasks.
            // The project name will be taken from "Project:" keyword detected in first lines.
            case "exportToTaskwarrior":
                
                // Starting with an empty default project name.
                var projectName = "";
                
                // For each line, we are gathering data to properly create tasks.
                getSelectedTextAndSeparateByNewline().forEach(function (line){
                    if (getProjectNameAndRun(line, function (proName) {
                        projectName = proName;
                        // We expect, that the project name would be the only thing in line, hence `return`.
                        return;
                    })) return;
                    
                    // We are trying to get the task description.
                    // It should be started with either - (minus) or * (asterisk) to indicate list item.
                    var taskRegExp = /[\*\-][\s*]?(.+)[\s*]?/; 
                    var taskDescription;
                    
                    var isTask = taskRegExp.exec(line);
                    if (isTask) {
                        taskDescription = isTask[1];
                        script.startDetachedProcess(pathToTaskwarrior,
                                                    [
                                                        "add",
                                                        "pro:" + projectName,
                                                        taskDescription
                                                    ]);
                        // We expect, that the task description would be the only thing in the line, hence `return`.
                        return;
                    }
                });
                break;
            
            case "importFromTaskwarrior":
                // Get selected text to determine the project we want to import from.

                var projectNames = [];

                getSelectedTextAndSeparateByNewline().forEach(function (line){
                    if (getProjectNameAndRun(line, function (proName) {
                        projectNames.push(proName);
                    })) return;
                });

                // To avoid overwriting what we have selected, we are simply writing it
                script.noteTextEditWrite(script.noteTextEditSelectedText());

                projectNames.forEach( function(projectName) {
                    var result = script.startSynchronousProcess(pathToTaskwarrior, 
                                                                [
                                                                    "pro:" + projectName,
                                                                    "rc.report.next.columns=description",
                                                                    "rc.report.next.labels=Desc"
                                                                ],
                                                                "");
                    if (result) {
                        var tasksSeparated;
                        // The result does not contain any \n, so we are splitting by whitespace.
                        tasksSeparated = result.toString().split('\n');
                        
                        tasksSeparated.splice(0, 1); // removing ""
                        if (tasksSeparated.length === 0) {
                            script.log("No entries");
                            return;
                        }
                        tasksSeparated.splice(0, 1); // removing "Desc"
                        tasksSeparated.splice(0, 1); // removing "----"

                        tasksSeparated.splice(tasksSeparated.length - 1, 1); // removing ""
                        tasksSeparated.splice(tasksSeparated.length - 1, 1); // removing "X tasks"
                        tasksSeparated.splice(tasksSeparated.length - 1, 1); // removing ""

                        script.noteTextEditWrite("\n");

                        script.noteTextEditWrite("Project: " + projectName + "\n\n");
                        tasksSeparated.forEach( function(taskDesc){
                            script.noteTextEditWrite("* " + taskDesc + "\n");
                        });
                        
                    }

                });
                break;

        }
    }
}
