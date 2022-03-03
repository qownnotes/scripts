import QtQml 2.0

QtObject {
    /**
     * This function is called when the markdown html of a note is generated
     *
     * It allows you to modify this html
     * This is for example called before by the note preview
     *
     * @param {Note} note - the note object
     * @param {string} html - the html that is about to being rendered
     * @param {string} forExport - true if the html is used for an export, false for the preview
     * @return {string} the modified html or an empty string if nothing should be modified
     */
    function noteToMarkdownHtmlHook(note, html, forExport) {
        if (!forExport) {
            html = html.replace(new RegExp("　", 'g'), "&nbsp;");
        }

        return html;
    }
}
