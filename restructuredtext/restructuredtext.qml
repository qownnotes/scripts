/*
This script can preview and help format reStructuredText style note.

Dependencies
docutils

Usage
1. Install dependencies.
(1). Install python3.
(2). Install docutils: pip3 install docutils
(3). Install pygments: pip3 install pygments (if you need code highlight)

2. Change default note file extension to rst.(Settings > General)

3. New a rst extension note file, and edit it using custom actions toolbar/menu added by this script.

Note
You can use bold and italic buildin formating buttons directly, because reStructuredText have the same bold/italic format as Markdown .

You'd better use dark theme, because code highlight using darcula theme now.(Enable dark mode in Setting > Interface , and select dark color schema in Setting > Editor > Editor font & colors)

Only tested on windows10. Should works on all platforms.


Todo:
 - Add reStructuredText keyword highlight and autocomplete.
 - Reuse buildin formating buttons?  Maybe need more new QOwnNotes script methods/hooks helping to do it.
 - Add reStructuredText table more other formating actions.
 - And reStructuredText Directive templates.
 - Note head use reStructuredText style Title.
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
        script.registerCustomAction("strikeText", "strike", "strike text", "format-text-strikethrough");
        // create LineBlock.
        script.registerCustomAction("createLineBlock", "LineBlock", "|");
        script.registerCustomAction("insertTable", "insert table", "insert table", "table");
        script.registerCustomAction("alignCol", "align current table column", "|=|");
        script.registerCustomAction("tableNewLine", "newline in table", "\\n");

        script.registerCustomAction("addCol", "add table column", "addCol",
                                    scriptDirPath + "/table-insert-column-after.svg");
        script.registerCustomAction("delCol", "delete table column", "delCol",
                                    scriptDirPath + "/table-delete-column.svg");
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
            let text = note.noteText;
            text = text.replace(/\r/g, "").replace(/\n/g, "\\n")
                       .replace(/'/g, "\\'").replace(/"/g, "\\\"");
            let scriptDir = script.fromNativeDirSeparators(scriptDirPath);
            let python = "python3";
            if (script.platformIsWindows()) {
                python = "python";
            }
            let params = ["-c", "import os;os.chdir('"+scriptDir+"');" +
                                "import rst2html;rst2html.rst2html('"+text+"');"];
            let result = script.startSynchronousProcess(python, params);
            let u8arr = new Uint8Array(result);
            for (let i=0; i<u8arr.length/2; i++) {
                u8arr[i] = parseInt(String.fromCharCode(u8arr[2*i]) +
                                    String.fromCharCode(u8arr[2*i+1]), 16);
            }
            u8arr = null;
            return result.slice(0, result.byteLength/2);
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
        var text;

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
            let start = script.noteTextEditSelectionStart();
            let end = script.noteTextEditSelectionEnd();
            // add LineBlock char to the head of start line.
            script.noteTextEditSetSelection(0, start);
            text = script.noteTextEditSelectedText();
            script.noteTextEditSetSelection(text.lastIndexOf("\n"), end);
            text = script.noteTextEditSelectedText();
            text = text.replace(/\n/g, "\n| ");
            script.noteTextEditWrite(text);
            break;
        case "strikeText":
            text = script.noteTextEditSelectedText();
            if (text === "") {
                script.noteTextEditWrite(":strike:``");
                let pos = script.noteTextEditCursorPosition();
                script.noteTextEditSetCursorPosition(pos - 1);
            } else {
                text = ":strike:`" + text + "`";
                script.noteTextEditWrite(text);
            }
            break;
        case "insertTable":
            let result = script.inputDialogGetText(
                "insert table", "Please enter TitleNum RowNum ColumnNum", "1 4 4");
            let arr = result.split(" ", 3);
            let tn = Number(arr[0]);
            let rn = Number(arr[1]);
            let cn = Number(arr[2]);
            let w = 10;
            let u0 = " ".repeat(w) + "|";
            let u1 = "-".repeat(w) + "+";
            let u2 = "=".repeat(w) + "+";
            let l0 = "   |" + u0.repeat(cn) + "\n";
            let l1 = "   +" + u1.repeat(cn) + "\n";
            let l2 = "   +" + u2.repeat(cn) + "\n";
            let t = l1 + l0;
            let r = l0 + l1;
            text = ".. table:: table\n   :widths: auto\n\n" + t.repeat(tn) + l2 + r.repeat(rn);
            script.noteTextEditWrite(text);
            break;
        case "alignCol":
            rebuildTable(function(fontLines, backLines) {
                let curLineFont = fontLines[fontLines.length - 1];
                let colStart = curLineFont.lastIndexOf("|");
                let curLine = curLineFont + backLines[0];
                let diffn = curLine.trim().length - fontLines[1].trim().length;
                let cArr = curLine.match(/[^\x00-\xff]/ig);
                if (cArr !== null) diffn += cArr.length;

                function rebuildLine(line) {
                    let splitChar = line.charAt(colStart);
                    let i = line.indexOf(splitChar, colStart + 1);
                    if (diffn > 0) {
                        let fillChar = line.charAt(i - 1);
                        return line.slice(0, i) + fillChar.repeat(diffn) + line.slice(i);
                    }
                    else return line.slice(0, i + diffn) + line.slice(i);
                }

                let i;
                for (i=1; i<fontLines.length-1; i++) {
                    fontLines[i] = rebuildLine(fontLines[i]);
                }
                for (i=1; i<backLines.length-1; i++) {
                    backLines[i] = rebuildLine(backLines[i]);
                }
                return (fontLines.length - 2) * diffn;
            });
            break;
        case "tableNewLine":
            rebuildTable(function(fontLines, backLines) {
                let curLineFont = fontLines[fontLines.length - 1];
                let curLine = curLineFont + backLines[0];
                fontLines[fontLines.length - 1] = curLine;
                backLines[0] = fontLines[1].replace(/-/g, " ").replace(/\+/g, "|");
                return curLine.length;
            });
            break;
        case "addCol":
            rebuildTable(function(fontLines, backLines) {
                let curLineFont = fontLines[fontLines.length - 1];
                let curLine = curLineFont + backLines[0];
                let y = fontLines[fontLines.length - 1].length;

                function rebuildLine(line) {
                    return line.slice(0, y) +
                        line.slice(y).replace(/(.+?)([-= ])([\+|])(.+)/,
                                              '$1$2$3'+'$2'.repeat(10)+'$3$4');
                }

                let i;
                for (i=1; i<fontLines.length-1; i++) {
                    fontLines[i] = rebuildLine(fontLines[i]);
                }
                for (i=1; i<backLines.length-1; i++) {
                    backLines[i] = rebuildLine(backLines[i]);
                }
                backLines[0] = rebuildLine(curLine);
                fontLines.pop();
                return (fontLines.length - 1) * 11;
            });
            break;
        case "delCol":
            rebuildTable(function(fontLines, backLines) {

            });
            break;
        }
    }

    function createTitle(titleChar) {
        let text = script.noteTextEditSelectedText();
        if (text === "") {
            text = "Section title.";
        }
        let underline = "";
        for (let i = 0; i < text.length; i++) {
            underline += titleChar;
        }
        script.noteTextEditWrite(text + "\n" + underline + "\n\n");
    }

    // refactor(fontLines, backLines) -> n chars add(+)/del(-) before cursor.
    function rebuildTable(refactor){
        let pos = script.noteTextEditCursorPosition();
        script.noteTextEditSelectAll();
        let text = script.noteTextEditSelectedText();
        let fontLines = [];
        let line;
        let i0 = pos;
        let i;
        do {
            i = text.lastIndexOf("\n", i0 - 1);
            line = text.slice(i, i0);
            fontLines.unshift(line);
            i0 = i;
        } while (line.trim() !== "");

        let start = i;
        let backLines = [];
        i0 = pos;
        do {
            i = text.indexOf("\n", i0 + 1);
            line = text.slice(i0, i);
            backLines.push(line);
            i0 = i;
        } while (line.trim() !== "");
        let end = i;

        pos += refactor(fontLines, backLines);

        script.noteTextEditSetSelection(start, end);
        script.noteTextEditWrite(fontLines.join("") + backLines.join(""));
        script.noteTextEditSetSelection(pos, pos);
    }
}
