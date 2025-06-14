import QtQml 2.0

/**
 * This script creates a menu item and a button that search in all notes and remove links to note (MD file) no longer existing (aka dead note-link)
 */

QtObject {
    function customActionInvoked(identifier) {
        switch (identifier) {
        case "RemoveDeadNoteLink":
            var dialogText = "";
            var reLink = RegExp("\\[.*\\]\\(.*\\.md\\)", "g"); // RegExp to find links : "[***](***.md)"
            script.fetchNoteIdsByNoteTextPart("").forEach(function (noteId) {
                // Loop for all notes
                var linkText = "";
                var note = script.fetchNoteById(noteId);
                var newNoteText = note.noteText;
                var LinkFound = reLink.exec(note.noteText);
                while (LinkFound != null) {
                    // Loop for all links in the note
                    var LinkNoteName = LinkFound.toString().replace(RegExp(".*\\(", "").exec(LinkFound), ""); // RegExp to find the name of the link : from start of the link to "(", and then removed from the string
                    LinkNoteName = LinkNoteName.toString().replace(RegExp(".*\\/", "").exec(LinkNoteName), ""); // RegExp to find the relative path : from start to the last"/", and then removed from the string
                    LinkNoteName = LinkNoteName.replace(")", ""); // removing last ")" of the link
                    while (LinkNoteName.search("%20") > -1) {
                        LinkNoteName = LinkNoteName.replace("%20", " "); // replacing all the %20 by space in the filename
                    }
                    if (script.fetchNoteByFileName(LinkNoteName).id == 0) {
                        // Does a note exist with that filename
                        newNoteText = newNoteText.replace(LinkFound, ""); // removing the link in the future NoteText
                        linkText += "\n  - " + LinkFound;
                    }
                    LinkFound = reLink.exec(note.noteText);
                }
                if (note.noteText != newNoteText) {
                    script.setCurrentNote(note);
                    script.noteTextEditSelectAll();
                    script.noteTextEditWrite(newNoteText.trim());
                    dialogText += "\n\nNote : " + note.name + "   link(s) removed :" + linkText;
                }
            });

            if (dialogText != "") {
                dialogText = "Here's the result of removing dead note-link(s)" + dialogText;
                script.informationMessageBox(dialogText);
            } else {
                script.informationMessageBox("No dead note-link found");
            }
            break;
        }
    }
    function init() {
        script.registerCustomAction("RemoveDeadNoteLink", "Remove dead links to note", "Remove dead note-link", "bookmark-new", true, false, true);
    }
}
