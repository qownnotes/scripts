import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * This script is used for manual interaction with Taskwarrior by either
 * importing tasks from a certain project, or exporting them from a note.
 */
QtObject {
    property string taskPath;
    property bool verbose;
    property bool deleteOnImport;

    property variant settingsVariables: [
        {
            "identifier": "taskPath",
            "name": "Taskwarrior path",
            "description": "A path to your Taskwarrior instance",
            "type": "string",
            "default": "/usr/bin/task",
        },
        {
            "identifier": "verbose",
            "name": "Verbose logging",
            "description": "Should the script log every action?",
            "type": "boolean",
            "default": false
        },
        {
            "identifier": "deleteOnImport",
            "name": "Delete on import",
            "description": "Delete tasks on import?",
            "type": "boolean",
            "default": false
        }
    ];

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
        var projectRegExp = /^(#+)[\s*]?(.+)?[\s*]?$/i;
        var isProjectName = projectRegExp.exec(str);
        if (isProjectName) {
            var projectName = isProjectName[2];
            var headerLevel = isProjectName[1].length;
            func(projectName, headerLevel);
            return true;
        }
    }

    function logIfVerbose(str) {
        if (verbose) {
            script.log(str);
        }
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
                
                logIfVerbose("Exporting tasks from a note.");

                // Starting with an empty default project name.
                // We are keeping the project name as a array of strings. We will concatenate them to
                // get the final projectName with nesting.
                var projectName = [];
                var referenceHeaderLevel = 0;

                // For each line, we are gathering data to properly create tasks.
                getSelectedTextAndSeparateByNewline().forEach(function (line){
                    if (getProjectNameAndRun(line, function (proName, headerLevel) {
                        logIfVerbose("Detected project name: " + proName);
                        logIfVerbose("Detected header level: " + headerLevel);

                        if (projectName.length === 0) {
                            referenceHeaderLevel = headerLevel - 1;
                        }

                        if (projectName.length + referenceHeaderLevel >= headerLevel) {
                            var i;
                            for (i = projectName.length + referenceHeaderLevel - headerLevel + 1; i > 0; i--) {
                                projectName.pop();
                                if (projectName.length === 0) {
                                    referenceHeaderLevel = headerLevel - 1;
                                    break;
                                }
                            }
                        }
                        projectName.push(proName);

                        // We expect, that the project name would be the only thing in line, hence `return`.
                        return;
                    })) return;
                    
                    // We are trying to get the task description.
                    // It should be started with either - (minus) or * (asterisk) to indicate list item.
                    var taskRegExp = /^[\*\-][\s*]?(.+)[\s*]?$/; 
                    var taskDescription;
                    
                    var isTask = taskRegExp.exec(line);
                    if (isTask) {
                        
                        taskDescription = isTask[1];
                        logIfVerbose("Detected task: " + taskDescription);
                        var concatenatedProjectName = projectName.join('.');
                        logIfVerbose("Executing \"" + taskPath + " add pro:" + concatenatedProjectName + " " + taskDescription + "\"");
                        script.startDetachedProcess(taskPath,
                                                    [
                                                        "add",
                                                        "pro:" + concatenatedProjectName,
                                                        taskDescription
                                                    ]);
                        // We expect, that the task description would be the only thing in the line, hence `return`.
                        return;
                    }
                });
                break;
            
            case "importFromTaskwarrior":
                // Get selected text to determine the project we want to import from.

                var plainText = getSelectedTextAndSeparateByNewline();

                var projectNames = [];
                var projectNameLines = [];
                var currentLineNo = 0;
                var referenceHeaderLevel = 0;

                plainText.forEach(function (line){
                    currentLineNo++;
                    if (!getProjectNameAndRun(line, function (proName, headerLevel) {
                        if (projectNames.length === 0) {
                            logIfVerbose("No project detected yet. Inserting " + proName)
                            projectNames.push([proName]);
                            logIfVerbose("Reference header level set to " + headerLevel)
                            referenceHeaderLevel = headerLevel - 1;
                            return;
                        }

                        var newProjectName = projectNames[projectNames.length - 1].slice();
                        logIfVerbose("Last project name inserted was " + newProjectName.join('.'));
                        if (newProjectName.length + referenceHeaderLevel >= headerLevel) {
                            logIfVerbose("Same header level detected.");
                            var i;
                            for (i = newProjectName.length + referenceHeaderLevel - headerLevel + 1; i > 0; i--) {
                                newProjectName.pop();
                                if (newProjectName.length === 0) {
                                    referenceHeaderLevel = headerLevel - 1;
                                    break;
                                }
                            }
                        }
                        newProjectName.push(proName);
                        projectNames.push(newProjectName);
                        logIfVerbose("Project name detected. Inserted value is " + newProjectName.join('.'))
                        
                    })) return;
                    projectNameLines.push(currentLineNo);
                });

                var currentProjectNumber = 0;

                projectNames.forEach( function(projectName) {
                    currentProjectNumber++;
                    var concatenatedProjectName = projectName.join('.');
                    var result = script.startSynchronousProcess(taskPath, 
                                                                [
                                                                    "pro.is:" + concatenatedProjectName,
                                                                    "rc.report.next.columns=id,description.desc",
                                                                    "rc.report.next.labels=ID,Desc"
                                                                ],
                                                                "");
                    if (result) {
                        // via https://stackoverflow.com/a/35635260
                        var repeat = function(str, count) {
                            var array = [];
                            for(var i = 0; i < count;)
                                array[i++] = str;
                            return array.join('');
                        }
                        
                        var tasksSeparated;
                        // The result does not contain any \n, so we are splitting by whitespace.
                        tasksSeparated = result.toString().split('\n');
                        
                        tasksSeparated.splice(0, 1); // removing ""
                        if (tasksSeparated.length === 0) {
                            logIfVerbose("No entries");
                            return;
                        }
                        tasksSeparated.splice(0, 1); // removing "Desc"
                        tasksSeparated.splice(0, 1); // removing "----"

                        tasksSeparated.splice(tasksSeparated.length - 1, 1); // removing ""
                        tasksSeparated.splice(tasksSeparated.length - 1, 1); // removing "X tasks"
                        tasksSeparated.splice(tasksSeparated.length - 1, 1); // removing ""

                        var taskIds = [];
                        tasksSeparated.forEach( function(task){
                            var taskParamsRegexp = /(\d+)[\s*]?(.+)?[\s*]?/i;
                            var fetchTaskParams = taskParamsRegexp.exec(task);
                            logIfVerbose("Extracted data from task: ID " + fetchTaskParams[1] + " Desc: " + fetchTaskParams[2]);
                            var taskEntry = "* " + fetchTaskParams[2];
                            plainText.splice(projectNameLines[currentProjectNumber - 1], 0, taskEntry);
                            var i;
                            for (i = currentProjectNumber; i < projectNameLines.length; i++) {
                                projectNameLines[i] += 1;
                            }
                            taskIds.push(fetchTaskParams[1]);
                        });

                        if (deleteOnImport) {
                            script.startDetachedProcess(taskPath,
                            [
                                taskIds.join(' '),
                                "delete"
                            ]);
                        }
                        
                    }

                });

                script.noteTextEditWrite(plainText.join('\n'));

                break;

        }
    }
}
