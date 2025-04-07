import QtQml 2.0
import QOwnNotesTypes 1.0

QtObject {
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
        html = html.replace(/<\/style>/, "dt {font-weight: bold; font-style: italic;}</style>");
        var re = new RegExp("<p>(.*?\n: [^]*?)</p>", "g");
        if (re.test(html)) {
            html = html.replace(re, function (_, dl) {
                var output = "<dl>\n";
                var dlArray = dl.split("\n");
                for (var i = 0; i < dlArray.length; i++) {
                    var item = dlArray[i];
                    var entryText = "  <dt>" + item + "</dt>\n";
                    if (item.match(/^: /)) {
                        var defText = item.replace(/^: /g, "");
                        entryText = "  <dd>" + defText + "</dd>\n";
                    }
                    output += entryText;
                }
                output += "</dl>";
                script.log(output);
                return output;
            });
        }
        return html;
    }
}
