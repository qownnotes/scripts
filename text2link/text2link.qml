import QtQml 2.0

/**
 * This script creates links to all notes containing the selected text at the end of the current note. Caution ! This script doesn't work with note-subfolders.
 */
QtObject {
    function customActionInvoked(identifier) {
        switch (identifier) {
        case "Text2link":
            var text = script.noteTextEditSelectedText().trim();
            if (text == "") {
                break;
            }
            var foundedNotes = -1; // Current note will not be counted
            var addedLinks = 0;
            var oldLinks = 0;
            // loop for all notes containing the raw text
            script.fetchNoteIdsByNoteTextPart(text).forEach(function (noteId) {
                var note = script.fetchNoteById(noteId);
                // first condition : text should be a complete word in the note
                var reTest = RegExp("\\b" + text + "\\b", "gi").exec(note.noteText);
                // second condition : the note should not be already linked in this note
                var link = "(" + note.fileName + ")";
                while (link.search(" ") > -1) {
                    // need to loop for each space because .replace() only works once
                    link = link.replace(" ", "%20");
                }
                var alreadyLinked = script.currentNote().noteText.search(link);
                // third condition : the note should not be self
                if (reTest != null & alreadyLinked == -1 & script.currentNote().id != noteId) {
                    script.noteTextEditSetCursorPosition(-1); // end of the this note
                    script.noteTextEditWrite("\n\n" + "[" + note.name + "]" + link); // add a blank line and the link
                    addedLinks += 1;
                }
                if (reTest != null) {
                    foundedNotes += 1;
                }
                if (alreadyLinked > 0) {
                    oldLinks += 1;
                }
            });
            script.informationMessageBox(foundedNotes + " note(s) containing '" + text + "'\n" + oldLinks + " already linked\n" + addedLinks + " added", "Results");
            break;
        }
    }
    function init() {
        // create the menu entry
        script.registerCustomAction("Text2link", "Create links for all notes containing selected text", "Text 2 link", "bookmark-new", true, false, true);
    }
}
