import QtQml 2.0
import QOwnNotesTypes 1.0


// todo:
// add reStructuredText keyword highlight, hint and autocomplete.
// add more reStructuredText edit tool buttons and Directive templates.
// note head use reStructuredText style Title.


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
