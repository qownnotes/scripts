import QtQml 2.2
import QOwnNotesTypes 1.0

// This script adds a toolbar button and a context menu item to copy the link of selected note to clipboard

Script {   
    function init() {
        script.registerCustomAction("noteLinkToClipboard", "Copy link to the note to clipboard", 
                                    "Note link to cb", "link" , false, false, true)
    }
    
    function customActionInvoked(action) {        
        if (action == "noteLinkToClipboard") {
            var note = script.currentNote()
            script.setClipboardText("[%1](note://%2)".arg(note.name).arg(note.name.replace(/[^\d\w]/g, "_")))
        }
    }
}
 
 
 
