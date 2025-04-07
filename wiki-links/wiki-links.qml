import QtQml 2.0
import QOwnNotesTypes 1.0

QtObject {
    property variant settingsVariables: [
        {
            "identifier": "wikilinksSanitizeFilename",
            "name": "Wiki Links Sanitize Filename",
            "description": "Remove all symbols from linked filenames.",
            "type": "boolean",
            "default": true
        },
        {
            "identifier": "wikilinksRemoveSpaces",
            "name": "Wiki Links Remove Spaces",
            "description": "Remove or replace spaces from linked filenames.",
            "type": "boolean",
            "default": true
        },
        {
            "identifier": "wikilinksLowerCase",
            "name": "Wiki Links Lower Case",
            "description": "Convert linked filenames to lower case.",
            "type": "boolean",
            "default": true
        },
        {
            "identifier": "wikilinksReplaceSpacesSymbol",
            "name": "Wiki Links Replace Spaces Symbol",
            "description": "If Wiki links Remove Spaces option is selected, the symbol to replace spaces in filenames with (default: dash, replace with blank to remove spaces without replacing)",
            "type": "string",
            "default": "-"
        },
        {
            "identifier": "wikilinksHideSubfolder",
            "name": "Wiki Links Hide Subfolder",
            "description": "Hide the subfolder name in link text",
            "type": "boolean",
            "default": true
        },
        {
            "identifier": "wikilinksBackgroundColor",
            "name": "Wiki Links Background Color",
            "description": "Color for the backgroud of rendered wiki links (name or #hex):",
            "type": "string",
            "default": "#FFFF00"
        },
        {
            "identifier": "wikilinksForegroundColor",
            "name": "Wiki Links Foreground Color",
            "description": "Color for the foreground of rendered wiki links (name or #hex):",
            "type": "string",
            "default": "#ff832b"
        }
    ]
    property string wikilinksBackgroundColor
    property string wikilinksForegroundColor
    property bool wikilinksHideSubfolder
    property bool wikilinksLowerCase
    property bool wikilinksRemoveSpaces
    property string wikilinksReplaceSpacesSymbol
    property bool wikilinksSanitizeFilename

    function formatLink(unescapedTitle, linkTitle, filePath, subfolderName) {
        var escapedTitle = unescapedTitle;
        var prettyTitle = linkTitle;
        if (wikilinksSanitizeFilename) {
            escapedTitle = escapedTitle.replace(/[\!\?\.,\(\)\[\]@\$\^\&\*"';:<>]/g, "");
        }
        if (wikilinksRemoveSpaces) {
            escapedTitle = escapedTitle.replace(/\s+/g, wikilinksReplaceSpacesSymbol);
        }
        if (wikilinksLowerCase) {
            escapedTitle = escapedTitle.toLowerCase();
        }
        if (wikilinksHideSubfolder) {
            prettyTitle = prettyTitle.replace(/.*\//, "");
        }

        if (!/\//.test(escapedTitle)) {
            escapedTitle = subfolderName + escapedTitle.replace(/.*\//, "");
        }

        var formattedLink = "<a href=\"" + filePath + escapedTitle + ".md\">" + prettyTitle + "</a>";
        return formattedLink;
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

    function getFilePath(path) {
        if (script.platformIsWindows()) {
            path = "/" + path;
        }

        var filePath = "file://" + path + "/";
        return filePath;
    }
    function getSubfolder(note, path) {
        var fileName = note.fullNoteFilePath;
        var pathRe = new RegExp(path + "\/(.*\/)*.*");
        var subfolderName = fileName.replace(pathRe, "$1");
        return subfolderName;
    }
    function noteToMarkdownHtmlHook(note, html, forExport) {
        var path = script.currentNoteFolderPath();
        var subfolderName = getSubfolder(note, path);
        var filePath = getFilePath(path);

        html = html.replace(new RegExp("<x-wikilink data-target=\"(.*?)\">(.*?)</x-wikilink>", "gi"), function (_, unescapedTitle, linkTitle) {
            return formatLink(unescapedTitle, linkTitle, filePath, subfolderName);
        });
        return html;
    }
}
