import QtQml 2.0
import QOwnNotesTypes 1.0

Script {
    /**
     * Writes the selected text on the webpage that was sent to QOwnNotes from
     * the browser extension into the current note
     */
    function websocketRawDataHook(requestType, pageUrl, pageTitle, rawData,
                                  screenshotDataUrl) {
        // we only want to handle selection requests, page requests are ignored
        if (requestType != "selection") {
            return false;
        };

        
        let uid = Date.now();
        let selected =`\n- ${rawData} : [(link)][${uid}]`;
        let url = `\n[${uid}]: ${pageUrl}`;
        let posBefore = script.noteTextEditCursorPosition();

        // Insert Selected text after current line
        script.noteTextEditSelectCurrentLine();
        script.noteTextEditSetSelection(
            script.noteTextEditSelectionEnd() ,
            script.noteTextEditSelectionEnd() )
        script.noteTextEditWrite(selected);

        // Go to end of file and append web URL

        script.noteTextEditSetCursorPosition(-1);   
        script.noteTextEditWrite(url);

        // Go back to current editing position
        script.noteTextEditSetCursorPosition(posBefore);





        return true;
    }
}