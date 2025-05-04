import QOwnNotesTypes 1.0
import QtQml 2.0
import "markdown-it-deflist.js" as MarkdownItDeflist
import "markdown-it-katex.js" as MarkdownItKatex
import "markdown-it.js" as MarkdownIt

QtObject {
    property string customStylesheet
    property variant md
    property string options
    property variant settingsVariables: [{
        "identifier": "options",
        "name": "Markdown-it options",
        "description": "For available options and default values see <a href='https://github.com/markdown-it/markdown-it/blob/master/lib/presets'>markdown-it presets</a>.",
        "type": "text",
        "default": "{" + "\n" + "    //html:         false,        // Enable HTML tags in source" + "\n" + "    //xhtmlOut:     false,        // Use '/' to close single tags (<br />)" + "\n" + "    //breaks:       false,        // Convert '\\n' in paragraphs into <br>" + "\n" + "    //langPrefix:   'language-',  // CSS language prefix for fenced blocks" + "\n" + "    //linkify:      false,        // autoconvert URL-like texts to links" + "\n" + "" + "\n" + "    // Enable some language-neutral replacements + quotes beautification" + "\n" + "    //typographer:  false," + "\n" + "" + "\n" + "    // Double + single quotes replacement pairs, when typographer enabled," + "\n" + "    // and smartquotes on. Could be either a String or an Array." + "\n" + "    //" + "\n" + "    // For example, you can use '«»„“' for Russian, '„“‚‘' for German," + "\n" + "    // and ['«\\xA0', '\\xA0»', '‹\\xA0', '\\xA0›'] for French (including nbsp)." + "\n" + "    //quotes: '\\u201c\\u201d\\u2018\\u2019', /* “”‘’ */" + "\n" + "" + "\n" + "    // Highlighter function. Should return escaped HTML," + "\n" + "    // or '' if the source string is not changed and should be escaped externaly." + "\n" + "    // If result starts with <pre... internal wrapper is skipped." + "\n" + "    //" + "\n" + "    // function (/*str, lang*/) { return ''; }" + "\n" + "    //" + "\n" + "    //highlight: null," + "\n" + "" + "\n" + "    //maxNesting:   100            // Internal protection, recursion limit" + "\n" + "}"
    }, {
        "identifier": "useDeflistPlugin",
        "name": "Definition lists",
        "text": "Enable the Markdown-it definition list (<dl>) plugin",
        "type": "boolean",
        "default": false
    }, {
        "identifier": "useKatexPlugin",
        "name": "LaTeX Support",
        "text": "Enable the Markdown-it definition list KaTeX plugin",
        "type": "boolean",
        "default": false
    }, {
        "identifier": "customStylesheet",
        "name": "Custom stylesheet",
        "description": "Please enter your custom stylesheet:",
        "type": "text",
        "default": null
    }]
    property bool useDeflistPlugin
    property bool useKatexPlugin

    function init() {
        var optionsObj = eval("(" + options + ")");
        md = new this.markdownit(optionsObj);
        if (useDeflistPlugin)
            md.use(this.markdownitDeflist);

        if (useKatexPlugin)
            this.markdownItKatex(md, {
            "output": "mathml"
        });

        //Allow file:// url scheme
        var validateLinkOrig = md.validateLink;
        var GOOD_PROTO_RE = /^(file):/;
        md.validateLink = function(url) {
            var str = url.trim().toLowerCase();
            return GOOD_PROTO_RE.test(str) ? true : validateLinkOrig(url);
        };
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

    function isProtocolUrl(url) {
        return /^[a-zA-Z][\w+.-]*:\/\//.test(url);
    }

    function isWindowsAbsolute(path) {
        return /^[a-zA-Z]:[\\/]/.test(path);
    }

    function isUnixAbsolute(path) {
        return path.startsWith('/');
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
            // Convert backslashes to forward slashes for URL

            if (isProtocolUrl(rawPath))
                return `${prefix}${rawPath}"`;

            let finalPath;
            if (isUnixAbsolute(rawPath) || isWindowsAbsolute(rawPath))
                // Absolute path (Unix or Windows)
                finalPath = rawPath.replace(/\\/g, '/');
            else
                // Relative path → resolve against base
                finalPath = resolvePath(basePath, rawPath.replace(/^\.\/+/, ''));
            return `${prefix}file://${finalPath}"`;
        });
        // Don't attempt to render in the preview, it doesn't support mathml or complex css
        if (!forExport && useKatexPlugin)
            mdHtml = mdHtml.replace(/(<math\b[^>]*>)([\s\S]*?)(<\/math>)/gi, (fullMatch, openMathTag, mathInner, closeMathTag) => {
                let blockPresent = /\bdisplay="block"/i.test(openMathTag);
                let out = blockPresent ? '<br><i>' + openMathTag : '&nbsp;<i>' + openMathTag;
                out += mathInner.replace(/(<semantics\b[^>]*>)([\s\S]*?)(<\/semantics>)/gi, (semiMatch, openSemi, semiInner, closeSemi) => {
                    const cleaned = semiInner.replace(/<mrow\b[^>]*>[\s\S]*?<\/mrow>/gi, '');
                    return openSemi + cleaned + closeSemi;
                });
                out += blockPresent ? closeMathTag + '</i><br>' : closeMathTag + '</i>&nbsp;';
                return out;
            });

        //Get original styles
        var head = html.match(new RegExp("<head>(?:.|\n)*?</head>"))[0];
        //Add custom styles
        head = head.replace("</style>", "table {border-spacing: 0; border-style: solid; border-width: 1px; border-collapse: collapse; margin-top: 0.5em;} th, td {padding: 0 5px;}" + customStylesheet + "</style>");
        mdHtml = "<html>" + head + "<body>" + mdHtml + "</body></html>";
        return mdHtml;
    }

}
