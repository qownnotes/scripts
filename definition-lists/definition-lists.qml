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

    function noteToMarkdownHtmlHook(note, html, forExport) {
        html = html.replace(/<\/style>/, "dt {font-weight: bold; font-style: italic;}</style>");
        var re = new RegExp("<p>(.*?)\n: (.*?)</p>", "g");
        html = html.replace(re, "<dl>\n  <dt>$1</dt>\n  <dd>$2</dd>\n</dl>");
        return html;
    }
}
