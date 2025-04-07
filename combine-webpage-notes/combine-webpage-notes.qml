import QtQml 2.0
import QOwnNotesTypes 1.0
import com.qownnotes.noteapi 1.0

/**
 * This script merges notes in the reverse node Id order and strips the title
 */
Script {

    /**
     * This function is invoked when a custom action is triggered
     * in the menu or via button
     *
     * @param identifier string the identifier defined in registerCustomAction
     */
    function customActionInvoked(identifier) {
        if (identifier != "combine-webpage-notes") {
            return;
        }

        var noteIds = script.selectedNotesIds();

        if (noteIds.length == 0) {
            return;
        }

        var sorted = noteIds.sort((a, b) => b - a) // reorder the notes
        .map(id => script.fetchNoteById(id));
        var mergedLink = sorted[0].noteText.toString().split('\n').filter(x => x.indexOf('html') != -1)[0];
        var mergedTitle = sorted[0].name;
        var titleSeparator = '=====================================';  // markdown

        var newNote = [[mergedTitle, titleSeparator].join('\n'), mergedLink].concat(sorted.map(note => note.noteText.substring(note.name.toString().length).split('\n').filter(x => x != '').filter(x => x.indexOf('====') == -1).filter(x => x.indexOf('html') == -1).join('\n'))).join('\n\n');
        script.createNote(newNote);
    }
    /**
     * Initializes the custom actions
     */
    function init() {
        script.registerCustomAction("combine-webpage-notes", "Combine notes from the same page to a new note", "", "", false, true, true);
    }
}
