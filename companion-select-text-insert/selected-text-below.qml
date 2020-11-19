import QtQml 2.0
import QOwnNotesTypes 1.0

Script {
    /**
     * Writes the selected text on the webpage that was sent to QOwnNotes from
     * the browser extension into the current note
     */
 
    property string linkStyle;

    // register your settings variables so the user can set them in the script settings
    //
    // unfortunately there is no QVariantHash in Qt, we only can use
    // QVariantMap (that has no arbitrary ordering) or QVariantList (which at
    // least can be ordered arbitrarily)
    property variant settingsVariables: [
        {
            "identifier": "linkStyle",
            "name": "Insert Link as Ref Style",
            "description": "Insert link As Reference , Below or NoLink ?",
            "type": "selection",
            "default": "Below",
            "items": {"Below": "Below", "Ref": "Ref", "NoLink": "NoLink"},
        }
    ]
    function websocketRawDataHook(requestType, pageUrl, pageTitle, rawData,
                                  screenshotDataUrl) {
        // we only want to handle selection requests, page requests are ignored
        if (requestType != "selection") {
            return false;
        };

        switch (linkStyle) {
            case "Below":
                script.log(linkStyle)
                insertTextBelow(requestType, pageUrl, pageTitle, rawData,screenshotDataUrl)
                script.log("insertTextBelow")
                return true
                break;
            case "Ref":
                script.log(linkStyle)
                script.log("insertTextRefBottom")
                insertTextRefBottom (requestType, pageUrl, pageTitle, rawData,screenshotDataUrl)
                return true
                break;
        
            default:
                script.log(linkStyle)
                script.log("default")
                insertTextOnly (requestType, pageUrl, pageTitle, rawData,screenshotDataUrl)
                return true
                break;
        }

    }
    function insertTextBelow(requestType, pageUrl, pageTitle, rawData,
                                  screenshotDataUrl) {

        let selected =`\n- ${rawData} : <${pageUrl}>`;
        let posBefore = script.noteTextEditCursorPosition();

        // Insert Selected text below current line
        writeSelected(selected)

        script.noteTextEditSetCursorPosition(posBefore);

        return true;
    }
    function insertTextRefBottom(requestType, pageUrl, pageTitle, rawData,
                                  screenshotDataUrl) {
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
        let uid = Date.now();
        let selected =` ${rawData} `;
        // Insert Selected text
        writeSelected(selected)

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