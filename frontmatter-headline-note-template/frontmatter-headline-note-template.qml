import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * This script change the new note behavior:
 * New notes are created with a frontmatter title instead of
 * an h1 title
 */
QtObject {
    property string extraFrontMatterEntries
    property string headlinePreviewCSS
    // register your settings variables so the user can set them in the script settings
    property variant settingsVariables: [
        {
            "identifier": "extraFrontMatterEntries",
            "name": "Extra content for the Frontmatter (optionnal)",
            "description": "Please enter optionnal entries you would like to see in the Frontmatter of EACH AND EVERY NEW notes",
            "type": "text",
            "default": ""
        },
        {
            "identifier": "headlinePreviewCSS",
            "name": "CSS for the preview fo the Frontmatter Headline (optionnal)",
            "description": "Please enter optionnal CSS properties semi-colon seperated (e.g. `font-weight: bold; font-style: italic;`) to specify the preview style of the headline extracted from the Frontmatter of the note.",
            "type": "text",
            "default": ""
        },
        {
            "identifier": "styleInEditor",
            "name": "Highlight Frontmatter Title in Editor",
            "description": "Do you want to highlight the headline of the Frontmatter in the editor? Beware, checking this box may highlight in the editor every paragraph beginning with `title: `.",
            "text": "Highlight the frontmatter headline",
            "type": "boolean",
            "default": false
        },
    ]
    property string styleInEditor

    /**
     * This function is called before a note note is created
     *
     * It allows you to modify the headline of the note before it is created
     * Note that you have to take care about a unique note name, otherwise
     * the new note will not be created, it will just be found in the note list
     *
     * You can use this method for creating note templates
     *
     * @param headline text that would be used to create the headline
     * @return {string} the headline of the note
     */
    function handleNewNoteHeadlineHook(headline) {
        var extraContent = "\n" + extraFrontMatterEntries.trim();
        var text = "---\ntitle: " + headline + extraContent + "\n---\n";
        return text;
    }
    function init() {
        if (styleInEditor) {
            script.addHighlightingRule("^title: (.{1,70})$", "", 12); // Try to avoid false positives with {1,70} and $
        }
    }
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
        var frontmatterTitleReg = /^(?:---)\n*?(?:.*)?\ntitle: (.*)?\n*?(?:(?:.*)?\n)*?(?:---\n)/mi;
        var frontmatterTitleMatch = note.noteText.match(frontmatterTitleReg);
        var frontMatterTitle = frontmatterTitleMatch ? frontmatterTitleMatch[1] : null;
        if (headlinePreviewCSS.length)
            html = html.replace("</style>", " div>h1#noteheadline {" + headlinePreviewCSS + "}</style>");
        return frontMatterTitle ? html.replace("<body class=\"preview\">", "<body class=\"preview\"><div><h1 id='noteheadline'>" + frontMatterTitle + "</h1></div>") : html;
    }
}
