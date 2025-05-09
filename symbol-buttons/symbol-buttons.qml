import QtQml 2.2
import QOwnNotesTypes 1.0

/// This script adds toolbar buttons to insert characters set in script options

Script {
    property variant settingsVariables: [
        {
            "identifier": "symbolString",
            "name": "Symbols to insert with buttons",
            "description": "Put any unicode characters separated by spaces. You can group multiple symbols together.",
            "type": "string",
            "default": "∑ ∫ ∮"
        }
    ]
    property var symbolList
    property string symbolString

    function customActionInvoked(symbol) {
        if (symbolList.indexOf(symbol) != -1) {
            script.noteTextEditWrite(symbol);
        }
    }
    function init() {
        if (symbolString) {
            symbolList = symbolString.split(' ');
            for (var n = 0; n < symbolList.length; n++)
                script.registerCustomAction(symbolList[n], symbolList[n], symbolList[n]);
        }
    }
}
