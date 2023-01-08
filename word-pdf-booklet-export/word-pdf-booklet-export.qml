import QtQml 2.0
import QOwnNotesTypes 1.0

Script {

    // the path to the script's directory will be set here
    property string scriptDirPath;
    // the path to the pandoc executable will be set here
    property string pandocPath;
    property string libreOfficePath;
    property string pdfbook2Path;
    
    property string outFile;
    property string outDir;
    property string odtFile;

    // register your settings variables so the user can set them in the script settings
    property variant settingsVariables: [
        {
            "identifier": "pandocPath",
            "name": "Pandoc path",
            "description": "Please select the path to your Pandoc executable:",
            "type": "file",
            "default": "pandoc",
        },
        {
            "identifier": "libreOfficePath",
            "name": "LibreOffce (soffice) path",
            "description": "Please select the path to your soffice executable:",
            "type": "file",
            "default": "soffice",
        },
        {
            "identifier": "pdfbook2Path",
            "name": "pdfbook2 path",
            "description": "Please select the path to your pdfbook2 executable (Debian: part of package 'texlive-extra-utils'):",
            "type": "file",
            "default": "pdfbook2",
        }
    ];

    /**
     * Initializes the custom action
     */
    function init() {
		script.registerCustomAction("wordPdfBookletExport", "Export note to Word file and a pdf booklet", "Booklet Export" );
    }

    /**
     * This function is invoked when a custom action is triggered
     * in the menu or via button
     * 
     * @param identifier string the identifier defined in registerCustomAction
     */
    function customActionInvoked(identifier) {

        if (identifier != "wordPdfBookletExport") {
            return;
        }

        var note = script.currentNote();

        var noteName = note.name;

        //various path variables
        var fullFileName = note.fullNoteFilePath;
        var noteFileDir = note.fullNoteFileDirPath;
        var noteFolderDir = script.currentNoteFolderPath();

        outFile = script.getSaveFileName("Going to create files. Specify a base name and a location to save to…", noteFileDir + "/" + noteName, "(*.odt)");

        if (outFile === "") {
            script.log(identifier + ": cancelled note export");
            return;
        }
        
        odtFile = outFile + ".odt";
        outDir =  basePath(outFile);

        //variables for pandoc
        var defaultsFile = noteFileDir + "/defaults.yaml";
        if ( !script.fileExists(defaultsFile) ) {
            defaultsFile = scriptDirPath + "/defaults.yaml";
        }
        var dataDir = noteFileDir;
        if(!script.fileExists(noteFileDir + "/reference.odt")) {
            dataDir = scriptDirPath;
        }
        var pandocArgs = [fullFileName, "-d", defaultsFile, "--data-dir", dataDir, "-o", odtFile];

        // Uncomment for enabling Pandoc logging
        // var log = "--log=" + noteFileDir + "/" + noteName + "_log.json";
        // pandocArgs.push(log);
        // script.log(pandocArgs);
        // script.log(scriptDirPath);

        // Create ODT file
        var resultPandoc = script.startDetachedProcess(pandocPath, pandocArgs, "pandocFinished");
        if(resultPandoc)
            script.informationMessageBox("Started export process. This may take some seconds. You will be notified upon completion.");
        else
            script.informationMessageBox("Export process could not be started. Check protocol for output, please.");
    }
    
    function onDetachedProcessCallback(callbackIdentifier, resultSet, cmd, thread) {
        if(cmd[2] !== 0) {
            script.log(callbackIdentifier + ": failed, result: " + resultSet + ", exit code: " + cmd[2]);
            script.informationMessageBox("A step while exporting the note failed. Are the required binaries installed? See protocol for hints.");
            return;
        }

        if (callbackIdentifier == "pandocFinished") {
            script.log(callbackIdentifier + ": exported note file to odt, " + odtFile + ", result: " + resultSet);
            
            // Convert ODT to DOCX
            var libreOfficeArgs = ["--convert-to", "docx", "--outdir", outDir, odtFile];
            script.startDetachedProcess(libreOfficePath, libreOfficeArgs, "libreOfficeDoxcFinished");
            
        } else if(callbackIdentifier == "libreOfficeDoxcFinished") {
            script.log(callbackIdentifier + ": converted odt file to Word file, " + outFile + ".docx, result: " + resultSet);
            
            // Convert ODT to PDF
            var libreOfficeArgsPdf = ["--convert-to", "pdf", "--outdir", outDir, odtFile];
            script.startDetachedProcess(libreOfficePath, libreOfficeArgsPdf, "libreOfficePdfFinished");
        } else if(callbackIdentifier == "libreOfficePdfFinished") {
            script.log(callbackIdentifier + ": converted odt file to PDF file, " + outFile + ".pdf, result: " + resultSet);
            
            // Remove ODT file
            // script.removeFile(outFile); // This is missing ;-)
            var resultRm = "";
            if(script.platformIsLinux() || script.platformIsOSX()) {
                resultRm = script.startSynchronousProcess("rm", [odtFile]);
            } else if(script.platformIsWindows()) {
                resultRm = script.startSynchronousProcess("del", [odtFile]);
            }
            script.log(callbackIdentifier + ": removed file " + odtFile + ", result: " + resultRm);
            
            // Create booklet using pdfbook2   input.pdf
            var pdfbook2Args = ["--paper=a4paper", "--short-edge", outFile + ".pdf"];
            script.startDetachedProcess(pdfbook2Path, pdfbook2Args, "pdfbook2Finished");

        } else if(callbackIdentifier == "pdfbook2Finished") {
            script.log(callbackIdentifier + ": created bookled from PDF file, result: " + resultSet);
            
            script.informationMessageBox("Exported note file to Word and PDF files.");
        }
    }
    
    function basePath(str) {
        return (str.substring(0, str.lastIndexOf(script.dirSeparator())));
    }
}
