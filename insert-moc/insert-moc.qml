import QtQml 2.2
import QOwnNotesTypes 1.0

Script {
    function init() {
        // Register custom action for MOC index generation
        script.registerCustomAction("indexpage", "Generate MOC", "indexpage");
    }

    function customActionInvoked(action) {
        if (action !== "indexpage") {
            return;
        }

        var currentNote = script.currentNote;
        var noteIds = script.fetchNoteIdsByNoteTextPart(""); // get all note IDs

        // Build each link line and collect into array
        var listedLinks = [];
        for (var i = 0; i < noteIds.length; i++) {
            var noteId = noteIds[i];
            var noteObj = script.fetchNoteById(noteId);
            var name = noteObj.name;
            var fullPath = noteObj.fullNoteFilePath;
            var parts = fullPath.split('.');
            var ext = parts[parts.length - 1];
            var relDir = noteObj.relativeNoteFileDirPath;

            // Construct filePath and encoded path
            var filePath = relDir && relDir.length > 0
                ? relDir + "/" + name + "." + ext         
                : name + "." + ext;
            var rawLink = (relDir && relDir.length > 0
                ? relDir + "/" + name
                : name);
            var encoded = encodeURIComponent(rawLink)
                .replace(/%2F/g, "/")
                .replace(/%2E/g, ".") + "." + ext;

            // Format line
            var line = "|" + filePath + "  | --->  [" + name + "." + ext + "](" + encoded + ")|   ";
            listedLinks.push(line);
        }

        // Sort lines alphabetically
        listedLinks.sort();

        // Assemble new note text
        var noteTextstring = "# Map of Content   \n\n|path |filelink  | \n|---|---| \n" + listedLinks.join("\n") + "\n";

        // Replace entire note content
        script.noteTextEditSelectAll();
        script.noteTextEditWrite(noteTextstring);
        script.log("MOC index generated and sorted successfully.");
    }
}
