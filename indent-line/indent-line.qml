import QtQml 2.2
import QOwnNotesTypes 1.0

/// Toolbar buttons and context menu items to indent and unindent a text line.

Script {
    property int indent_spaces_number
    property variant settingsVariables: [
        {
            "identifier": "indent_spaces_number",
            "name": "Number of spaces to indent/unindent a text line",
            "type": "integer",
            "default": 4
        },
    ]
    property var unindent_regex: new RegExp("^ {0," + indent_spaces_number + "}")

    function customActionInvoked(action) {
        if (action == "indent" || action == "unindent") {
            const indent_spaces = " ".repeat(indent_spaces_number);

            script.noteTextEditSelectCurrentLine();
            var text_line = script.noteTextEditSelectedText();

            if (action == "indent")
                text_line = indent_spaces.concat(text_line);
            else
                text_line = text_line.replace(unindent_regex, "");

            script.noteTextEditWrite(text_line);
        }
    }
    function init() {
        script.registerCustomAction("indent", "Indent current line", ">");
        script.registerCustomAction("unindent", "Unindent current line", "<");
    }
}
