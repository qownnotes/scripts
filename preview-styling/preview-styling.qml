import QtQml 2.0

/**
 * This is an example for custom styling of html in the note preview
 */
QtObject {
    property string customStylesheet

    // register your settings variables so the user can set them in the script settings
    property variant settingsVariables: [
        {
            "identifier": "customStylesheet",
            "name": "Custom stylesheet",
            "description": "Please enter your custom stylesheet:",
            "type": "text",
            "default": "h2 {margin-left: 20px;}\nh3 {margin-left: 40px;}\nh4 {margin-left: 60px;}"
        },
    ]

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
        // see http://doc.qt.io/qt-5/richtext-html-subset.html for a list of
        // supported css styles
        html = html.replace("</style>", customStylesheet + "</style>");
        return html;
    }
}
