import QtQml 2.0
import QOwnNotesTypes 1.0

QtObject {
    property string scriptDirPath
    property string backlinksHtml
    property bool triggerOnPreview
    property string dirSep

    property variant settingsVariables: [
        {
            "identifier": "triggerOnPreview",
            "name": "Trigger backlink generation on preview",
            "description": "Generates backlinks everytime the preview is updated (affects performance; recommended only in conjunction with Export Notes to Website script)",
            "type": "boolean",
            "default": false,
        },
    ];

    function getSubFolder(note, path) {
        var fileName = note.fullNoteFilePath;
        var pathRe = new RegExp(path + dirSep + "((.*)" + dirSep + ")*.*");
        var subfolderName = fileName.replace(pathRe, "$2");
        return subfolderName;
    }

    function normalizeText(text) {
        return text.toLowerCase().replace(/[\-\s_]/g, "").replace(/\[\[([^\]]+)\|[^\]]+\]\]/g, "[[$1]]");
    }

    function normalizeLink(group, link) {
        groupPrefix = "";
        if (!link.match(dirSep)) {
            groupPrefix = group + dirSep;
        }
        normalize = normalizeText(link);
        return groupPrefix + normalize;
    }

    function printBacklinks(backlinks) {
        dirSep = script.dirSeparator();
        var out = "";
        if (backlinks.length != 0) {
            out += "<h2>Backlinks</h2>\n\n<ul>\n";
            for (var i = 0; i < backlinks.length; i++) {
                var backlinkPath = backlinks[i]["p"];
                var backlinkTitle = backlinks[i]["t"];
                out += "    <li><a href=\"file://" + backlinkPath + "\">" + backlinkTitle + "</a></li>\n";
            }
            out += "</ul>\n";
        }
        return out;
    }

    function getBacklinks(note) {
        var noteName = note.name;
        var path = script.currentNoteFolderPath();
        var subfolderName = getSubFolder(note, path);
        var nameNormalized = normalizeText(noteName);

        var noteIds = script.fetchNoteIdsByNoteTextPart("");
        var backlinks = [];

        noteIds.forEach(function (pageId){
            var pageObj = script.fetchNoteById(pageId);
            var basename = pageObj.name;
            var pageGroup = getSubFolder(pageObj, path);
            var text = pageObj.noteText;
            if (/\[\[.*\]\]/.test(text)) {
                var normalizedText = normalizeText(text);
                var isBacklink = false;
                if (subfolderName == pageGroup) {
                    var re = new RegExp("\\[\\[" + nameNormalized + "\\]\\]");
                    if (re.test(normalizedText)) {
                        isBacklink = true;
                    }
                } else {
                    var subfolderNormalized = normalizeText(subfolderName);
                    var re = new RegExp("\\[\\[" + subfolderNormalized + dirSep + nameNormalized + "\\]\\]");
                    if (re.test(normalizedText)) {
                        isBacklink = true;
                    }
                }
                if (isBacklink == true) {
                    var fullPath = pageObj.fullNoteFilePath;
                    var title = "";
                    var titleMatch = text.match(/^# (.*)/);
                    if (titleMatch) {
                        title = titleMatch[1];
                    }
                    var backlinkObj = {"p":fullPath, "t":title};
                    backlinks.push(backlinkObj);
                }
            }
        });
        var sortedBacklinks = backlinks.sort((a,b) => (a.p > b.p) ? 1 : ((b.p > a.p) ? -1 : 0));
        return printBacklinks(sortedBacklinks);
    }

    function getGroup(backlinkPath) {
        backlink_dir = File.dirname(backlinkPath)
        File.basename(backlink_dir)
    }

    function getLink(backlinkPath) {
        backlink_ext = File.extname(backlinkPath)
        backlinkLink = File.basename(backlinkPath, backlink_ext)
    }

    /**
    * This function is called after a note was opened
    *
    * @param {NoteApi} note - the note object that was opened
    */
    function noteOpenedHook(note) {
        backlinksHtml = getBacklinks(note);
    }

    function noteToMarkdownHtmlHook(note, html, forExport) {
        if (triggerOnPreview) {
            backlinksHtml = getBacklinks(note);
        }

        html = html.replace("</body>", "\n" + backlinksHtml + "\n</body>");
        return html;
    }
}
