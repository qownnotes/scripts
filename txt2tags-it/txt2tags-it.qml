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
            "identifier": "useSetextHeadings",
            "name": "Setext headings",
            "text": "Enable markdown setext headings (Title followed by === or ---)",
            "type": "boolean",
            "default": false
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
    property bool useSetextHeadings

    function init() {
        var optionsObj = eval("(" + options + ")");
        // MarkdownIt.markdownit is a top-level var in markdown-it.js — accessible
        // via the module qualifier in both Qt5 and Qt6 QML.
        md = new MarkdownIt.markdownit(optionsObj);

        if (useTxt2tagsPlugin)
            md.use(MarkdownItTxt2tags.markdownitTxt2tags, { useSetextHeadings: useSetextHeadings });

        if (useTxt2tagsPlugin) {
            script.registerCustomAction("txt2tags-italic",        qsTr("Italic (txt2tags)"),        qsTr("Italic"),        "format-text-italic",        true, false, false);
            script.registerCustomAction("txt2tags-strikethrough", qsTr("Strikethrough (txt2tags)"), qsTr("Strike"),        "format-text-strikethrough", true, false, false);
            script.registerCustomAction("txt2tags-underline",     qsTr("Underline (txt2tags)"),     qsTr("Underline"),     "format-text-underline",     true, false, false);
            script.registerCustomAction("txt2tags-h1",            qsTr("Heading 1 (txt2tags)"),     qsTr("H1"),            "format-text-header",        true, false, false);
            script.registerCustomAction("txt2tags-h2",            qsTr("Heading 2 (txt2tags)"),     qsTr("H2"),            "format-text-header",        true, false, false);
            script.registerCustomAction("txt2tags-h3",            qsTr("Heading 3 (txt2tags)"),     qsTr("H3"),            "format-text-header",        true, false, false);
        }

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

    function wrapInline(marker) {
        var selectedText = script.noteTextEditSelectedText();
        if (selectedText.length > 0) {
            script.noteTextEditWrite(marker + selectedText + marker);
        } else {
            script.noteTextEditWrite(marker + marker);
            script.noteTextEditSetCursorPosition(script.noteTextEditCursorPosition() - marker.length);
        }
    }

    function applyHeading(level) {
        var markers = "";
        for (var i = 0; i < level; i++) markers += "=";

        var noteText = script.currentNote().noteText;
        var pos = script.noteTextEditCursorPosition();
        var lineStart = noteText.lastIndexOf('\n', pos - 1) + 1;
        var lineEnd = noteText.indexOf('\n', pos);
        if (lineEnd === -1) lineEnd = noteText.length;

        var line = noteText.substring(lineStart, lineEnd);

        // Extract bare content, stripping any existing txt2tags heading
        var headingMatch = line.match(/^(=+)\s+(.*?)\s+\1\s*$/);
        var content = headingMatch ? headingMatch[2] : line.trim();

        // Toggle off if already this heading level, otherwise apply
        var sameLevelRe = new RegExp("^" + markers + "\\s+.*?\\s+" + markers + "\\s*$");
        var newLine = sameLevelRe.test(line)
            ? content
            : markers + " " + content + " " + markers;

        script.noteTextEditSetSelection(lineStart, lineEnd);
        script.noteTextEditWrite(newLine);
    }

    function customActionInvoked(identifier) {
        switch (identifier) {
            case "txt2tags-italic":        wrapInline("//"); break;
            case "txt2tags-strikethrough": wrapInline("--"); break;
            case "txt2tags-underline":     wrapInline("__"); break;
            case "txt2tags-h1":            applyHeading(1);  break;
            case "txt2tags-h2":            applyHeading(2);  break;
            case "txt2tags-h3":            applyHeading(3);  break;
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
        if (script.platformIsWindows())
            path = "/" + path;

        mdHtml = mdHtml.replace(/(\b(?:src|href|data-[\w-]+)\s*=\s*)(["'])([^"']+)\2/gi, (_, attr, quote, rawPath) => {
            if (isProtocolUrl(rawPath))
                return `${attr}${quote}${rawPath}${quote}`;

            let finalPath;
            if (isUnixAbsolute(rawPath) || isWindowsAbsolute(rawPath))
                finalPath = rawPath.replace(/\\/g, '/');
            else
                finalPath = resolvePath(path, rawPath.replace(/^\.\/+/, ''));
            return `${attr}${quote}file://${finalPath}${quote}`;
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
