import QtQml 2.0

/**
 * This is an example for custom styling of html in the note preview
 */
QtObject {
    /**
     * This function is called when the markdown html of a note is generated
     *
     * It allows you to modify this html
     * This is for example called before by the note preview
     *
     * @param {Note} note - the note object
     * @param {string} html - the html that is about to being rendered
     * @return {string} the modfied html or an empty string if nothing should be modified
     */
    function noteToMarkdownHtmlHook(note, html) {
        // see http://doc.qt.io/qt-5/richtext-html-subset.html for a list of
        // supported css styles
        html = html.replace(/<li>((?:\s|<p>)*)\[[xX]\]/g, "<li style=\"list-style-type: none; margin-left: -16px;\">$1&#x2611;");
        html = html.replace(/<li>((?:\s|<p>)*)\[ \]/g, "<li style=\"list-style-type: none; margin-left: -16px;\">$1&#x2610;");
        return html;
    }
}
