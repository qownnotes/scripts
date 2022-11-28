import QtQml 2.0
import QOwnNotesTypes 1.0
import com.qownnotes.noteapi 1.0

/**
 * This script exports all notes as HTML files
 */
Script {
    property string exportStyleSelection;
    property string defaultExportFolder;
    property string defaultExportPath;
    property bool useAbsolutePaths;

    property variant settingsVariables: [
        {
            "identifier": "exportStyleSelection",
            "name": "File export selection",
            "description": "This determines whether the files are exported into a central folder (in notebook named subfolders) or inside notebook folders. To keep the old default behavior, leave this as 'Save files in each notebook'.",
            "type":"selection",
            "default": "opt1",
            "items": {"opt1": "Save files in each notebook (original behavior).", "opt2": "Save files in central location."}
        },
        {
            "identifier": "defaultExportFolder",
            "name": "Set export folder name",
            "description" : "If the 'Save files in each notebook' is selected, this is the name of the eport folder. Default is export. If 'Save files in central location is selected, this field has no effect.",
            "type": "string",
            "default" : "export"
        },        
        {
            "identifier": "defaultExportPath",
            "name": "Set base folder for website export",
            "description": "If the 'Save files in subfolder in central location' is used, this is the folder path for the save. Each website will be saved in a subfolder named after the notebook name. If 'Save files in each notebook' is selected, this property has no effect.",
            "type":"directory",
            "default": ""
        },
        {
            "identifier": "useAbsolutePaths",
            "name": "Use absolute paths for links",
            "description": "Internal links will only work in the export folder (not recommended)",
            "type": "boolean",
            "default": false,
        }
    ];

    /**
     * Initializes the custom actions
     */
    function init() {
        script.registerCustomAction("exportWebsite", "Export notes as website",
            "", "applications-internet", false, true, true);
    }

    function getSubFolderInLinux(note, path) {
        var fileName = note.fullNoteFilePath;
        var sep = script.dirSeparator();
        var pathRe = new RegExp(path + sep + "((.*)" + sep + ")*.*");
        var subfolderName = fileName.replace(pathRe, "$2");
        return subfolderName;
    }
    
    function getSubFolderInWindows(note, path) {
        var fileName = note.fullNoteFilePath;
        var sep = '\/';
        var pathRe = new RegExp(path + sep + "((.*)" + sep + ")*.*");
        var subfolderName = fileName.replace(pathRe, "$2");
        return subfolderName;        
    }
    
    function mkDirInLinux(path) {
        script.startSynchronousProcess("mkdir", ["-p", exportFolder]);
    }
    
    function mkDirInWindows(path) {
        script.startSynchronousProcess('cmd', ['/c','mkdir',path]);
    }

    /**
     * This function is invoked when a custom action is triggered
     * in the menu or via button
     * 
     * @param identifier string the identifier defined in registerCustomAction
     */
    function customActionInvoked(identifier) {
        if (identifier != "exportWebsite") {
            return;
        }
        
        var isWin = script.platformIsWindows();
        var sep = script.dirSeparator();
        var exportBasePath = "";
        var exportBaseFolder = "";
        
        switch(exportStyleSelection) {
            case "opt1":
                exportBasePath = script.toNativeDirSeparators(script.currentNoteFolderPath());
                exportBaseFolder = defaultExportFolder;
                break;
            case "opt2":
                exportBasePath = script.toNativeDirSeparators(defaultExportPath);
                var p = script.currentNoteFolderPath().split('/')
                exportBaseFolder = p[p.length-1];
                break;
            default:
                return;
		}
        
        isWin ? mkDirInWindows(exportBasePath + sep + exportBaseFolder) : mkDirInLinux(exportBasePath + sep + exportBaseFolder);

        var noteIds = script.fetchNoteIdsByNoteTextPart("");

        noteIds.forEach(function (noteId) {
            var note = script.fetchNoteById(noteId);
            var path = script.currentNoteFolderPath();
            var subFolder = isWin ? getSubFolderInWindows(note, path) : getSubFolderInLinux(note, path);
            var noteName = note.name;
            var sep = script.dirSeparator();
            var exportFolder = script.toNativeDirSeparators(exportBasePath + sep + exportBaseFolder + sep + subFolder);
            isWin ? mkDirInWindows(exportFolder) : mkDirInLinux(exportFolder);
            var exportPath = exportFolder + sep + noteName + ".html";
            
            var noteHtml = note.toMarkdownHtml();
            var titleMatch = noteHtml.match(/<h1>(.*)<\/h1>/);
            var noteTitle = noteName;
            if (titleMatch) {
              noteTitle = titleMatch[1];
            }
            noteHtml = noteHtml.replace(/<head>/, "<head><title>" + noteTitle + "</title>");
            var linkRe = new RegExp("file://" + path + "/([^\"]+?)\.md", "g");
            if (useAbsolutePaths) {
                noteHtml = noteHtml.replace(linkRe, "file://" + path + "/export/$1.html");
            } else {
                noteHtml = noteHtml.replace(linkRe, function(_, linkPath) {
                    var parentDir = "";
                    if (subFolder != "") {
                        var depth = linkPath.split("/").length - 1;
                        if (depth == 0) {
                            depth ++;
                        }
                        for (var i = 0; i < depth; i++) {
                            parentDir += "../";
                        }
                    }
                    return parentDir + linkPath + ".html";
                });
            }
            script.writeToFile(exportPath, noteHtml);
            script.log("Successfully exported note: " + subFolder + sep + note.name);
        });

        script.log("All notes succssfully exported!");
    }
}
