import QtQml 2.0
import QOwnNotesTypes 1.0

QtObject {
    /**
     * Moves the cursor to the end after opening a note, overriding its restored position.
     */
    function noteOpenedHook(note) {
        script.noteTextEditSetCursorPosition(-1);
    }
}
