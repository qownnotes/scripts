import QtQml 2.2
import QOwnNotesTypes 1.0

/// Simple script, that creates a button and a context menu item that insert text, defined in the script settings.

Script {
    property string buttonIcon
    property string buttonName
    property string menuName
    property variant settingsVariables: [
        {
            "identifier": "text",
            "name": "Text to insert",
            "description": "A text that would be inserted to note text when the button is pressed.",
            "type": "string",
            "default": "[comment]: # ()"
        },
        {
            "identifier": "menuName",
            "name": "Name of the menu item",
            "description": "",
            "type": "string",
            "default": "Insert comment"
        },
        {
            "identifier": "buttonName",
            "name": "Name of the button",
            "description": "",
            "type": "string",
            "default": "Insert comment"
        },
        {
            "identifier": "buttonIcon",
            "name": "Icon of the button",
            "description": "Name or full path to button icon. If empty, button name will be shown.",
            "type": "string",
            "default": "insert-text.svg"
        },
    ]
    property string text

    function customActionInvoked(action) {
        if (action == "insertText") {
            script.noteTextEditWrite(text);
        }
    }
    function init() {
        script.registerCustomAction("insertText", menuName, buttonName, buttonIcon, true);
    }
}
