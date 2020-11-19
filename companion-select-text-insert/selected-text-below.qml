import QtQml 2.0
import QOwnNotesTypes 1.0

Script {
    /**
     * Writes the selected text on the webpage that was sent to QOwnNotes from
     * the browser extension into the current note
     */
 
    property string linkStyle;
    property variant settingsVariables: [
        {
            "identifier": "linkStyle",
            "name": "Insert Link as Ref Style",
            "description": "Insert link As Reference , Below or NoLink ?",
            "type": "selection",
            "default": "option1",
            "items": {"option1": "Below", "option2": "Ref", "option3": "NoLink"},
        }
    ]
    function websocketRawDataHook(requestType, pageUrl, pageTitle, rawData,
                                  screenshotDataUrl) {
        // we only want to handle selection requests, page requests are ignored
        if (requestType != "selection") {
            return false;
        };

        if ( linkStyle == "Below") {
            insertTextUnder(requestType, pageUrl, pageTitle, rawData,screenshotDataUrl)
        } else if ( linkStyle == "Ref") {
            sertTextRefBottom (requestType, pageUrl, pageTitle, rawData,screenshotDataUrl)
        } else {
            insertTextOnly (requestType, pageUrl, pageTitle, rawData,screenshotDataUrl)
        }
        return true;
    }
    function insertTextUnder(requestType, pageUrl, pageTitle, rawData,
                                  screenshotDataUrl) {
        // we only want to handle selection requests, page requests are ignored
        if (requestType != "selection") {
            return false;
        };

        
        let selected =`\n- ${rawData}: <${pageUrl}>`;
        let posBefore = script.noteTextEditCursorPosition();

        // Insert Selected text below current line
        writeSelected(selected)
        script.noteTextEditSetCursorPosition(posBefore);

        return true;
    }
    function insertTextRefBottom(requestType, pageUrl, pageTitle, rawData,
                                  screenshotDataUrl) {
        // we only want to handle selection requests, page requests are ignored

        
        let uid = Date.now();
        let selected =`\n- ${rawData} : [(link)][${uid}]`;
        let url = `\n[${uid}]: ${pageUrl}`;
        let posBefore = script.noteTextEditCursorPosition();

        // Insert Selected text after current line
        writeSelected(selected)
        // Go to end of file and append web URL
        script.noteTextEditSetCursorPosition(-1);   
        script.noteTextEditWrite(url);
        // Go back to current editing position
        script.noteTextEditSetCursorPosition(posBefore);

        return true;
    }
    function insertTextOnly(requestType, pageUrl, pageTitle, rawData,
                                  screenshotDataUrl) {
        // we only want to handle selection requests, page requests are ignored

        
        let uid = Date.now();
        let selected =`\n- ${rawData} : [(link)][${uid}]`;
        let posBefore = script.noteTextEditCursorPosition();

        // Insert Selected text after current line
        writeSelected(selected)
        script.noteTextEditWrite(selected);

        return true;
    }
    function writeSelected(selected){
        script.noteTextEditSelectCurrentLine();
        script.noteTextEditSetSelection(
        script.noteTextEditSelectionEnd() ,
        script.noteTextEditSelectionEnd() )
        script.noteTextEditWrite(selected);
    }
}