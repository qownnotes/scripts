import QtQml 2.0
import QOwnNotesTypes 1.0

QtObject {
    /**
    * This function is called before the markdown html of a note is generated
    *
    * It allows you to modify what is passed to the markdown to html converter
    *
    * The method can for example be used in multiple scripts to render code (like LaTeX math or mermaid)
    * to its graphical representation for the preview
    *
    * The note will not be changed in this process
    *
    * @param {NoteApi} note - the note object
    * @param {string} markdown - the markdown that is about to being converted to html
    * @param {string} forExport - true if the html is used for an export, false for the preview
    * @return {string} the modified markdown or an empty string if nothing should be modified
    */
    function preNoteToMarkdownHtmlHook(note, markdown, forExport) {
        var re = /```mermaid\n([\s\S]*?)\n```/gim;
        markdown = markdown.replace(re, function (_, diag) {
            var encodedData = Qt.btoa(diag);
            var ink = '![](https://mermaid.ink/img/' + encodedData + ')';
            return ink;
        });
        return markdown;
    }
}
