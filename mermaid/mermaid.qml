import QtQml 2.0
import QOwnNotesTypes 1.0

QtObject {
    /**
     * This function is called when the markdown html of a note is generated
     *
     * It allows you to modify this html
     * This is for example called before by the note preview
     *
     * The method can be used in multiple scripts to modify the html of the preview
     *
     * @param {NoteApi} note - the note object
     * @param {string} html - the html that is about to being rendered
     * @param {string} forExport - the html is used for an export, false for the preview
     * @return {string} the modified html or an empty string if nothing should be modified
     */

    function preNoteToMarkdownHtmlHook(note, markdown, forExport) {
        var re = /```mermaid\n([\s\S]*?)\n```/gim;
        markdown = note.decryptedNoteText.replace(re, function(_, diag){
            var encodedData = Qt.btoa(diag);
            var ink = '![](https://mermaid.ink/img/' + encodedData + ')';
            return ink;
        });
        return markdown;
    }
}
