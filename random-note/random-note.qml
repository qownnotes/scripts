import QtQml 2.0
import com.qownnotes.noteapi 1.0

/**
 * This script creates a menu item and a button to jump to a random note from the collection
 */
QtObject {

    /**
     * This function is invoked when a custom action is triggered
     * in the menu or via button
     *
     * @param identifier string the identifier defined in registerCustomAction
     */
    function customActionInvoked(identifier) {
        if (identifier != "randomNote") {
            return;
        }

        var noteIds = script.fetchNoteIdsByNoteTextPart("");

        var len = noteIds.length;
        var rand = Math.floor(Math.random() * len);
        var noteId = noteIds[rand];
        var note = script.fetchNoteById(noteId);
        script.setCurrentNote(note);
        script.regenerateNotePreview();

        var path = script.currentNoteFolderPath();
        var subfolderName = getSubFolder(note, path);
        script.jumpToNoteSubFolder(subfolderName);
    }
    function getSubFolder(note, path) {
        var fileName = note.fullNoteFilePath;
        var pathRe = new RegExp(path + "\/((.*)\/)*.*");
        var subfolderName = fileName.replace(pathRe, "$2");
        return subfolderName;
    }
    /**
     * Initializes the custom action
     */
    function init() {
        script.registerCustomAction("randomNote", "Jump to a random note", "Random note", "media-playlist-shuffle");
    }
}
