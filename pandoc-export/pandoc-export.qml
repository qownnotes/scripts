import QtQml 2.0
import QOwnNotesTypes 1.0

Script {

    // the path to the script's directory will be set here
    property string scriptDirPath;
    // the path to the pandoc executable will be set here
    property string pandocPath;

    // register your settings variables so the user can set them in the script settings
    property variant settingsVariables: [
        {
            "identifier": "pandocPath",
            "name": "Pandoc path",
            "description": "Please select the path to your Pandoc executable:",
            "type": "file",
            "default": "pandoc",
        },
    ];

    /**
     * Initializes the custom action
     */
    function init() {
		script.registerCustomAction("pandocExport", "Export note using pandoc", "Pandoc Export" );
    }

    /**
     * This function is invoked when a custom action is triggered
     * in the menu or via button
     * 
     * @param identifier string the identifier defined in registerCustomAction
     */
    function customActionInvoked(identifier) {

        if (identifier != "pandocExport") {
            return;
        }

        var note = script.currentNote();

        var noteName = note.name;

        //various path variables
        var fullFileName = note.fullNoteFilePath;
        var noteFileDir = note.fullNoteFileDirPath;
        var noteFolderDir = script.currentNoteFolderPath();

        var outFile = script.getSaveFileName("Export note as...", noteFileDir + "/" + noteName, "(*.*)");

        if (outFile === "") {
            script.log(identifier + ": cancelled note export");
            return;
        }


        //variables for pandoc
        var defaultsFile = noteFileDir + "/defaults.yaml";
        if ( !script.fileExists(defaultsFile) ) {
            defaultsFile = scriptDirPath + "/defaults.yaml";
        }
        var pandocArgs = [fullFileName, "-d", defaultsFile, "-o", outFile];

        // Uncomment for enabling Pandoc logging
        // var log = "--log=" + noteFileDir + "/" + noteName + "_log.json";
        // pandocArgs.push(log);

        script.log(pandocArgs);
        script.log(scriptDirPath);
        script.startSynchronousProcess(pandocPath, pandocArgs, "", noteFileDir);
        script.log(identifier + ": exported note file - " + outFile);
        script.informationMessageBox("exported note file - " + outFile);
    }
}

