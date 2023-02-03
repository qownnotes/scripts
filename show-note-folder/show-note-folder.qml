import QtQml 2.0
import QOwnNotesTypes 1.0

QtObject {
    function init() {
        script.registerLabel("loc-label", "N/A");
    }

    function noteOpenedHook(note) {
        var noteSubFolderQmlObj = Qt.createQmlObject("import QOwnNotesTypes 1.0; NoteSubFolder{}", mainWindow, "noteSubFolder");
        var subFolder = noteSubFolderQmlObj.fetchNoteSubFolderById(note.noteSubFolderId);
        script.setLabelText("loc-label", "<B>" + subFolder.relativePath()+"</B>");
    }
}
