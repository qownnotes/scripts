import QtQml 2.0
import QOwnNotesTypes 1.0

Script {
    function autocompletionHook() {
        // get the current word plus non-word-characters before the word to also get the "[<"-character
        var word = script.noteTextEditCurrentWord(true);

        var noteSubFolderQmlObj = Qt.createQmlObject("import QOwnNotesTypes 1.0; NoteSubFolder{}", mainWindow, "noteSubFolder");
        var noteSubFolder = noteSubFolderQmlObj.activeNoteSubFolder();

        if (!word.startsWith("[<") || !noteSubFolder || !noteSubFolder.notes) {
            return [];
        }
        // cut the "[>]" off of the string and do a substring search for notes
        var searchString = word.slice(2, -1).trim();

        // array holds the matching names
        var matchedNotes = [];

        for (var i in noteSubFolder.notes) {
            var note = noteSubFolder.notes[i];
            if (note.name.toLowerCase().startsWith(searchString.toLowerCase())) {
                matchedNotes.push(note.name);
            }
        }
        return matchedNotes;
    }
}
