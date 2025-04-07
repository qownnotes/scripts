import QtQml 2.0
import QOwnNotesTypes 1.0

QtObject {
    property string charactersList
    property var qownStyles: {
        "-1": "NoState",
        "0": "Link",
        "3": "Image",
        "4": "CodeBlock",
        "5": "CodeBlockComment",
        "7": "Italic",
        "8": "Bold",
        "9": "List",
        "11": "Comment",
        "12": "H1",
        "13": "H2",
        "14": "H3",
        "15": "H4",
        "16": "H5",
        "17": "H6",
        "18": "BlockQuote",
        "21": "HorizontalRuler",
        "22": "Table",
        "23": "InlineCodeBlock",
        "24": "MaskedSyntax",
        "25": "CurrentLineBackgroundColor",
        "26": "BrokenLink",
        "27": "FrontmatterBlock",
        "28": "TrailingSpace",
        "29": "CheckBoxUnChecked",
        "30": "CheckBoxChecked",
        "31": "StUnderline"
    }
    property var settingsVariables: [
        {
            "identifier": "charactersList",
            "name": "List of charachters to highlight",
            "description": "Please list all the characters you want to highlight (without ANY separation, such as coma or spaces). Warning, by default the sting is NOT EMPTY but contains two different bearking spaces to highlight (U+00A0 and U+202F).",
            "type": "string",
            "default": "  "
        },
        {
            "identifier": "styleForEditor",
            "name": "Highlight style for the choosen charchacters",
            "description": "Please select a style for the characters highlight",
            "type": "selection",
            "default": "28",
            "items": qownStyles
        }
    ]
    property string styleForEditor

    function init() {
        script.addHighlightingRule("[" + charactersList + "]", "", parseInt(styleForEditor));
    }
}
