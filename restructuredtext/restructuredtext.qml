/*
This script can preview and help format reStructuredText style note.

Dependencies
docutils

Usage
1. Install dependencies.
(1). Install python3.
(2). Install docutils: pip3 install docutils docutils
(3). Install pygments: pip3 install docutils pygments (if you need code highlight)

2. Change default note file extension to rst.(Settings > General)

3. New a rst extension note file, and edit it using custom actions toolbar/menu added by this script.

Note
You can use bold and italic buildin formating buttons directly, because reStructuredText have the same bold/italic format as Markdown .

You'd better use dark theme, because code highlight using darcula theme now.(Enable dark mode in Setting > Interface , and select dark color schema in Setting > Editor > Editor font & colors)


todo:
 - add reStructuredText keyword highlight and autocomplete.
 - reuse buildin formating buttons?
 - add reStructuredText table more other formating actions.
 - and reStructuredText Directive templates.
 - note head use reStructuredText style Title.
*/

import QtQml 2.0
import QOwnNotesTypes 1.0


QtObject {
    property string scriptDirPath;

    /**
     * Will be run when the scripting engine initializes
     */
    function init() {
        // create section title.
        script.registerCustomAction("createTitle0", "-title", "-");
        script.registerCustomAction("createTitle1", "~title", "~");
        script.registerCustomAction("createTitle2", "`title", "`");
        // create LineBlock.
        script.registerCustomAction("createLineBlock", "LineBlock", "|");
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
     * @param {string} forExport - true if the html is used for an export, false for the preview
     * @return {string} the modified html or an empty string if nothing should be modified
     */
    function noteToMarkdownHtmlHook(note, html, forExport) {
        if (note.fileName.endsWith(".rst")) {
            var text = note.noteText;
            text = text.replace(/\n/g, "\\n").replace(/'/g, "\\'").replace(/"/g, "\\\"");
            var scriptDir = script.fromNativeDirSeparators(scriptDirPath);
            return script.startSynchronousProcess(
                "python", ["-c", "import docutils.core;\
print(docutils.core.publish_string('"+text+"',writer_name='html',settings_overrides={\
'no_generator':True,'no_source_link':True,'tab_width':4,'file_insertion_enabled':False,\
'raw_enabled':False,'stylesheet_path':None,'traceback':True,'halt_level':5,\
'syntax_highlight':'short','template':'"+scriptDir+"/template.txt',\
'stylesheet':'"+scriptDir+"/basic.css,"+scriptDir+"/darcula.css,"+scriptDir+"/misc.css'}).decode())"]);
        }
    }

    /**
     * Registers a custom action
     *
     * @param identifier the identifier of the action
     * @param menuText the text shown in the menu
     * @param buttonText the text shown in the button
     *                   (no button will be viewed if empty)
     * @param icon the icon file path or the name of a freedesktop theme icon
     *             you will find a list of icons here:
     *             https://specifications.freedesktop.org/icon-naming-spec/icon-naming-spec-latest.html
     * @param useInNoteEditContextMenu if true use the action in the note edit
     *                                 context menu (default: false)
     * @param hideButtonInToolbar if true the button will not be shown in the
     *                            custom action toolbar (default: false)
     * @param useInNoteListContextMenu if true use the action in the note list
     *                                 context menu (default: false)
     */
    function customActionInvoked(identifier) {
        function createTitle(titleChar) {
            var text = script.noteTextEditSelectedText();
            if (text === "") {
                text = "Section title.";
            }
            var underline = "";
            for (var i = 0; i < text.length; i++) {
                underline += titleChar;
            }
            script.noteTextEditWrite(text + "\n" + underline + "\n\n");
        }

        switch (identifier) {
        case "createTitle0":
            createTitle("-");
            break;
        case "createTitle1":
            createTitle("~");
            break;
        case "createTitle2":
            createTitle("`");
            break;
        case "createLineBlock":
            var start = script.noteTextEditSelectionStart();
            var end = script.noteTextEditSelectionEnd();
            // add LineBlock char to the head of start line.
            script.noteTextEditSetSelection(0, start);
            var text = script.noteTextEditSelectedText();
            script.noteTextEditSetSelection(text.lastIndexOf("\n"), end);
            text = script.noteTextEditSelectedText();
            text = text.replace(/\n/g, "\n| ");
            script.noteTextEditWrite(text);
            break;
        }
    }
}
