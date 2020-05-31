import QtQml 2.0
import QOwnNotesTypes 1.0

import "markdown-it.js" as MarkdownIt
import "markdown-it-deflist.js" as MarkdownItDeflist

QtObject {
    property variant md;

    property string options;
    property string customStylesheet;
    property bool useDeflistPlugin;

    property variant settingsVariables: [
        {
            "identifier": "options",
            "name": "Markdown-it options",
            "description": "For available options and default values see <a href='https://github.com/markdown-it/markdown-it/blob/master/lib/presets'>markdown-it presets</a>.",
            "type": "text",
            "default":
"{"+"\n"+
"    //html:         false,        // Enable HTML tags in source"+"\n"+
"    //xhtmlOut:     false,        // Use '/' to close single tags (<br />)"+"\n"+
"    //breaks:       false,        // Convert '\\n' in paragraphs into <br>"+"\n"+
"    //langPrefix:   'language-',  // CSS language prefix for fenced blocks"+"\n"+
"    //linkify:      false,        // autoconvert URL-like texts to links"+"\n"+
""+"\n"+
"    // Enable some language-neutral replacements + quotes beautification"+"\n"+
"    //typographer:  false,"+"\n"+
""+"\n"+
"    // Double + single quotes replacement pairs, when typographer enabled,"+"\n"+
"    // and smartquotes on. Could be either a String or an Array."+"\n"+
"    //"+"\n"+
"    // For example, you can use '«»„“' for Russian, '„“‚‘' for German,"+"\n"+
"    // and ['«\\xA0', '\\xA0»', '‹\\xA0', '\\xA0›'] for French (including nbsp)."+"\n"+
"    //quotes: '\\u201c\\u201d\\u2018\\u2019', /* “”‘’ */"+"\n"+
""+"\n"+
"    // Highlighter function. Should return escaped HTML,"+"\n"+
"    // or '' if the source string is not changed and should be escaped externaly."+"\n"+
"    // If result starts with <pre... internal wrapper is skipped."+"\n"+
"    //"+"\n"+
"    // function (/*str, lang*/) { return ''; }"+"\n"+
"    //"+"\n"+
"    //highlight: null,"+"\n"+
""+"\n"+
"    //maxNesting:   100            // Internal protection, recursion limit"+"\n"+
"}"
        },
        {
            "identifier": "useDeflistPlugin",
            "name": "Definition lists",
            "text": "Enable the Mardown-it definition list (<dl>) plugin",
            "type": "boolean",
            "default": false,
        },
        {
            "identifier": "customStylesheet",
            "name": "Custom stylesheet",
            "description": "Please enter your custom stylesheet:",
            "type": "text",
            "default": null,
        },
    ];

    function init() {

        var optionsObj = eval("("+options+")");
        // md = new MarkdownIt.markdownit(optionsObj);
        md = new this.markdownit(optionsObj); // workaround because its a node module and qml-browserify didn't work

        if (useDeflistPlugin) {
            // md.use(MarkdownItDeflist.markdownitDeflist);
            md.use(this.markdownitDeflist); // workaround because its a node module and qml-browserify didn't work
        }

        //Allow file:// url scheme
        var validateLinkOrig = md.validateLink;
        var GOOD_PROTO_RE = /^(file):/;
        md.validateLink = function(url)
        {
            var str = url.trim().toLowerCase();
            return GOOD_PROTO_RE.test(str) ? true : validateLinkOrig(url);
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
        
        var mdHtml = md.render(note.noteText);

        //Insert root folder in attachments and media relative urls
        var path = script.currentNoteFolderPath();
        if (script.platformIsWindows()) {
            path = "/" + path;
        }
        mdHtml = mdHtml.replace(new RegExp("href=\"file://attachments/", "gi"), "href=\"file://" + path + "/attachments/");
        mdHtml = mdHtml.replace(new RegExp("src=\"file://media/", "gi"), "src=\"file://" + path + "/media/");

        //Get original styles
        var head = html.match(new RegExp("<head>(?:.|\n)*?</head>"))[0];
        //Add custom styles
        head = head.replace("</style>", "table {border-spacing: 0; border-style: solid; border-width: 1px; border-collapse: collapse; margin-top: 0.5em;} th, td {padding: 0 5px;}" + customStylesheet + "</style>");

        mdHtml = "<html>"+head+"<body>"+mdHtml+"</body></html>";

        return mdHtml;
    }
}
