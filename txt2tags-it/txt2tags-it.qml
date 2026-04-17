import QOwnNotesTypes 1.0
import QtQml 2.0
import "markdown-it-txt2tags.js" as MarkdownItTxt2tags
import "markdown-it.js" as MarkdownIt

QtObject {
    property string customStylesheet
    property variant md
    property string options
    property variant settingsVariables: [
        {
            "identifier": "options",
            "name": "Markdown-it options",
            "description": "For available options and default values see <a href='https://github.com/markdown-it/markdown-it/blob/main/lib/presets'>markdown-it presets</a>.",
            "type": "text",
            "default": "{" + "\n" + "    html:          true,         // Enable HTML tags in source" + "\n" + "    //xhtmlOut:     false,        // Use '/' to close single tags (<br />)" + "\n" + "    //breaks:       false,        // Convert '\\n' in paragraphs into <br>" + "\n" + "    //langPrefix:   'language-',  // CSS language prefix for fenced blocks" + "\n" + "    //linkify:      false,        // autoconvert URL-like texts to links" + "\n" + "" + "\n" + "    // Enable some language-neutral replacements + quotes beautification" + "\n" + "    //typographer:  false," + "\n" + "" + "\n" + "    //maxNesting:   100            // Internal protection, recursion limit" + "\n" + "}"
        },
        {
            "identifier": "useTxt2tagsPlugin",
            "name": "txt2tags syntax",
            "text": "Enable txt2tags heading syntax (= H1 =, == H2 ==, …)",
            "type": "boolean",
            "default": true
        },
        {
            "identifier": "useEditorHighlighting",
            "name": "txt2tags editor highlighting",
            "text": "Enable txt2tags heading syntax highlighting in the editor",
            "type": "boolean",
            "default": true
        },
        {
            "identifier": "customStylesheet",
            "name": "Custom stylesheet",
            "description": "Please enter your custom stylesheet:",
            "type": "text",
            "default": null
        }
    ]
    property bool useTxt2tagsPlugin
    property bool useEditorHighlighting

    function init() {
        var optionsObj = eval("(" + options + ")");
        // MarkdownIt.markdownit is a top-level var in markdown-it.js — accessible
        // via the module qualifier in both Qt5 and Qt6 QML.
        md = new MarkdownIt.markdownit(optionsObj);

        if (useTxt2tagsPlugin)
            md.use(MarkdownItTxt2tags.markdownitTxt2tags);

        if (useTxt2tagsPlugin && useEditorHighlighting) {
            // Headings: = H1 =  == H2 ==  …
            script.addHighlightingRule("^= +.+? +=\\s*$",         "=", 12);
            script.addHighlightingRule("^== +.+? +==\\s*$",       "=", 13);
            script.addHighlightingRule("^=== +.+? +===\\s*$",     "=", 14);
            script.addHighlightingRule("^==== +.+? +====\\s*$",   "=", 15);
            script.addHighlightingRule("^===== +.+? +=====\\s*$", "=", 16);
            // Inline: //italic//  __underline__  --strikethrough--
            script.addHighlightingRule("//.+?//",  "//", 7);
            script.addHighlightingRule("__.+?__",  "__", 31);
            script.addHighlightingRule("--.+?--", "--", -1, 0, 0,
                { foregroundColor: "#888888" });
            // Comment: % until end of line
            script.addHighlightingRule("^%.*$", "%", 11);
        }

        //Allow file:// url scheme
        var validateLinkOrig = md.validateLink;
        var GOOD_PROTO_RE = /^(file):/;
        md.validateLink = function (url) {
            var str = url.trim().toLowerCase();
            return GOOD_PROTO_RE.test(str) ? true : validateLinkOrig(url);
        };
    }
    function isProtocolUrl(url) {
        return /^[a-zA-Z][\w+.-]*:\/\//.test(url);
    }
    function isUnixAbsolute(path) {
        return path.startsWith('/');
    }
    function isWindowsAbsolute(path) {
        return /^[a-zA-Z]:[\\/]/.test(path);
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
        if (script.platformIsWindows())
            path = "/" + path;

        mdHtml = mdHtml.replace(/(\b(?:src|href|data-[\w-]+)\s*=\s*["'])([^"']+)["']/gi, (_, prefix, rawPath) => {
            if (isProtocolUrl(rawPath))
                return `${prefix}${rawPath}"`;

            let finalPath;
            if (isUnixAbsolute(rawPath) || isWindowsAbsolute(rawPath))
                finalPath = rawPath.replace(/\\/g, '/');
            else
                finalPath = resolvePath(path, rawPath.replace(/^\.\/+/, ''));
            return `${prefix}file://${finalPath}"`;
        });

        //Get original styles
        var head = html.match(new RegExp("<head>(?:.|\n)*?</head>"))[0];
        //Add custom styles
        head = head.replace("</style>", "table {border-spacing: 0; border-style: solid; border-width: 1px; border-collapse: collapse; margin-top: 0.5em;} th, td {padding: 0 5px;} del {text-decoration: line-through;}" + customStylesheet + "</style>");
        mdHtml = "<html>" + head + "<body>" + mdHtml + "</body></html>";
        return mdHtml;
    }
    function resolvePath(base, relative) {
        const baseParts = base.replace(/\/+$/, '').split('/');
        const relParts = relative.replace(/^\.\/+/, '').split('/');
        for (const part of relParts) {
            if (part === '..')
                baseParts.pop();
            else if (part !== '.' && part !== '')
                baseParts.push(part);
        }
        return baseParts.join('/');
    }
}
