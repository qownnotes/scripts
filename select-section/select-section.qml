import QtQml 2.0

/**
 * This script allows to select or cut
 * the current section (i.e. at the current cursor position)
 *
 */
QtObject {
    // Setting the actions
    function customActionInvoked(identifier) {
        if (identifier != "selectCurrentSection" && identifier != "cutCurrentSection")
            return;

        // Get positions (cursor and beginning of current line)
        var currentPos = script.noteTextEditCursorPosition();
        var noteText = script.currentNote().noteText;

        var startOfLine = -1;
        var regForHeaders = /\n(#+) ./g;
        var match;
        var currentHeadings;

        // Searching for headers before cursor pos:
        // get all headers
        while (match = regForHeaders.exec(noteText)) {
            // if it is after cursor pos, we leave
            if (match.index >= currentPos)
                break;
            // if it is before, we set our variables
            startOfLine = match.index + 1;
            currentHeadings = match[1];
        }
        // If no match before cursor pos, we leave
        if (startOfLine < 0)
            return;

        // Our header level is
        var currentHeadingsLevel = currentHeadings.length;
        //script.log("level "+currentHeadingsLevel);

        // a regexp to look for the next header
        // of the same level of lower → end of the section
        var regForNextHeader = new RegExp("\n(#{1," + currentHeadingsLevel + "}) .", "g");
        // we seach in the text from the current offset to the end
        match = regForNextHeader.exec(noteText.substr(startOfLine));

        // Set position of the next section
        if (match)
            // we found a match
            // we add the offset to have the proper position
            var nextSectionOffset = match.index + startOfLine;
        else
            // No match means no headings left
            // so get to proper position EOF
            var nextSectionOffset = noteText.length;

        // Select the text of the current section
        script.noteTextEditSetSelection(startOfLine, nextSectionOffset);

        // If a cut was asked
        if (identifier == "cutCurrentSection" && nextSectionOffset > 0) {
            // fill up the clipboard with the current section text
            script.setClipboardText("\n" + script.noteTextEditSelectedText());

            // set the new notetext without the current section
            var modifiedNoteText = noteText.substr(0, startOfLine - 1) + noteText.substr(nextSectionOffset);

            // Put the new text to the editor
            script.noteTextEditSetCursorPosition(0);
            script.noteTextEditWrite(modifiedNoteText);
            script.noteTextEditSetCursorPosition(startOfLine - 1);
        }

        return;
    }
    // creating icons and menu entries
    function init() {
        script.registerCustomAction("selectCurrentSection", "Select current section", "Select current section", "edit-select-all", true);
        script.registerCustomAction("cutCurrentSection", "Cut current section", "cut current section", "edit-cut", true);
    }
}
