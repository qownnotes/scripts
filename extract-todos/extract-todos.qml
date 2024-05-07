import QtQml 2.0
import QOwnNotesTypes 1.0

Script {
    property string subFolder;
    property variant settingsVariables: [
        {
			"identifier": "subFolder",
			"name": "TODO Subfolder",
			"description": "Restrict search for TODOs to this note subfolder.",
			"type": "string",
			"default": "",
		}
    ];
    
    function init() {
        script.registerLabel("extract todos")
        extractTodos()
    }
    
    function extractTodos() {

        const path = script.currentNoteFolderPath() + "/" + subFolder;
        const findResult = script.startSynchronousProcess("find", ["\(", "-name", "*.md", "-or", "-name", "*.txt", "\)", "-printf", "%P\n"], "", path);
        const files = findResult.toString().split("\n");
 
        const todoRegex = /^\s*- \[ \]\s*/;
        var output = "<h1>Open TODOs</h1>\n";

        for (const i in files) {
            const file = files[i];
            const text = script.startSynchronousProcess("cat", [ file ], "", path);
            const todos = text.toString()
                            .split("\n")
                            .filter(s => s.match(todoRegex))
                            .map(s => s.replace(todoRegex, ""));
            if (todos.length > 0) {
                output +=  "<h3>" + file + "</h3><ul>\n";
                for (const j in todos) {
                    output += "<p>" + todos[j] + "</p>\n";
                }
                output += "</ul>\n";
            }
        }

        script.setLabelText("extract todos", output);
    }

    function onNoteStored(note) { extractTodos() }
}

