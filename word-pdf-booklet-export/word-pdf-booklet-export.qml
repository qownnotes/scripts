import QtQml 2.0
import QOwnNotesTypes 1.0

Script {

    // the path to the script's directory will be set here
    property string scriptDirPath;
    // the path to the pandoc executable will be set here
    property string pandocPath;
    property string libreOfficePath;
    property string pdfbook2Path;

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

        var outFile = script.getSaveFileName("Going to create files. Specify a base name and a location to save to…", noteFileDir + "/" + noteName, "(*.odt)");

        if (outFile === "") {
            script.log(identifier + ": cancelled note export");
            return;
        }

        var odtFile = outFile + ".odt";

        //variables for pandoc
        var defaultsFile = noteFileDir + "/defaults.yaml";
        if ( !script.fileExists(defaultsFile) ) {
            defaultsFile = scriptDirPath + "/defaults.yaml";
        }
        var pandocArgs = [fullFileName, "-d", defaultsFile, "-o", odtFile];

        // Uncomment for enabling Pandoc logging
        // var log = "--log=" + noteFileDir + "/" + noteName + "_log.json";
        // pandocArgs.push(log);

        // TODO make of all of the following a detached process

        // Create ODT file
        script.log(pandocArgs);
        script.log(scriptDirPath);
        var resultPandoc = script.startSynchronousProcess(pandocPath, pandocArgs, "", noteFileDir);
        script.log(identifier + ": exported note file - " + odtFile + ", result: " + resultPandoc);

        // Convert ODT to DOCX
        var libreOfficeArgs = ["--convert-to", "docx", odtFile];
        var resultLibreOffice = script.startSynchronousProcess(libreOfficePath, libreOfficeArgs);
        script.log(identifier + ": converted odt file to Word file - " + odtFile + ", result: " + resultLibreOffice);

        // Convert ODT to PDF
        var libreOfficeArgsPdf = ["--convert-to", "pdf", odtFile];
        var resultLibreOfficePdf = script.startSynchronousProcess(libreOfficePath, libreOfficeArgsPdf);
        script.log(identifier + ": converted odt file to PDF file - " + odtFile + ", result: " + resultLibreOfficePdf);

        // Remove ODT file
        // script.removeFile(outFile); // This is missing ;-)
        var resultRm = script.startSynchronousProcess("rm", [odtFile]);
        script.log(identifier + ": removed file " + odtFile + ", result: " + resultRm);

        // Create booklet using pdfbook2   input.pdf
        var pdfbook2Args = ["--paper=a4paper", "--short-edge", outFile + ".pdf"];
        var resultPdfbook2 = script.startSynchronousProcess(pdfbook2Path, pdfbook2Args);
        script.log(identifier + ": created bookled from PDF file - " + outFile + ".pdf" + ", result: " + resultPdfbook2);

        script.informationMessageBox("Exported note file to Word and PDF files.");
    }
}

