import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * This script allow to insert citations with Zotero
 */

Script {
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
    // the path to the script's directory will be set here
    property string scriptDirPath
    property var settingsVariables: [
        {
            "identifier": "styleForCitationText",
            "name": "Highlight style for the Zotero Citation",
            "description": "Please select a style for the Citation text",
            "type": "selection",
            "default": "0",
            "items": qownStyles
        }//,
        // {
        // 	"identifier": "styleForCitationBrackets",
        // 	"name": "Highlight style for the Zotero Citation Brackets",
        // 	"description": "Please select a style for the Citation Brackets",
        // 	"type": "selection",
        // 	"default": "24",
        // 	"items": qownStyles
        // 	}
    ]
    property string styleForCitationBrackets
    property string styleForCitationText

    // Setting the actions
    function customActionInvoked(identifier) {
        if (identifier != "insertZoteroCitation")
            return;
        var testZotero = script.startSynchronousProcess("curl", ["-s", "http://localhost:23119/better-bibtex/cayw?probe=probe"]);
        if (testZotero == "") {
            script.informationMessageBox("Zotero with the plugin Better Bibtex need to be launched in order to insert a citation. Please launch Zotero with the Better BibTeX plugin and try again. If they are running, check 'Enable export by HTTP' in Better Bibtex and restart Zotero.", "Better Bibtex plugin of Zotero not detected");
            return;
        }
        if (testZotero == "No endpoint found") {
            script.informationMessageBox("Better BibTeX cannot find your library. Ensure only one Zotero instance is open. If so, reinstall Better BibTeX.", "Zotero Better Bibtex plugin error");
            return;
        }
        if (testZotero != "ready") {
            script.informationMessageBox("Unknown error in Better BibTex. Please restart Zotero and try again.", "Zotero Better Bibtex plugin error");
            return;
        }
        var result = script.startSynchronousProcess("curl", ["-s", "http://127.0.0.1:23119/better-bibtex/cayw?format=pandoc&brackets=true"]);

        if (result != '') {
            script.noteTextEditWrite(result);
        }
        return;
    }
    // creating icons and menu entries
    function init() {
        //script.addHighlightingRule("(\\[@).*?\\]", "", parseInt(styleForCitationBrackets),1,-1);
        //script.addHighlightingRule("\\[@.*?(\\])", "", parseInt(styleForCitationBrackets),1,-1);
        //script.addHighlightingRule("\\[@\\S+([\\; @]+)\\S+\\]", "", parseInt(styleForCitationBrackets),1,-1);
        //script.addHighlightingRule("\\[@(.*?)\\]", "", parseInt(styleForCitationText),1,-1);
        script.addHighlightingRule("\\[@(.*?)\\]", "", parseInt(styleForCitationText));
        script.registerCustomAction("insertZoteroCitation", "Zotero: Insert Citation", "Zotero: Insert Citation", script.toNativeDirSeparators(scriptDirPath + "/Logo_Zotero.svg"), true);
    }
}
