import QtQml 2.2
import QOwnNotesTypes 1.0

// This script adds toolbar buttons to increase and decrease the depth of all the headlines in selected text

Script {   
    function init() {
        script.registerCustomAction("#+", "Increase headline depth", "#+")
        script.registerCustomAction("#-", "Decrease headline depth", "#-")
    }
    
    function customActionInvoked(action) {        
        if (action == "#+")
            script.noteTextEditWrite(script.noteTextEditSelectedText().replace(/^\#/gm, "##"))
        if (action == "#-")
            script.noteTextEditWrite(script.noteTextEditSelectedText().replace(/^\#\#/gm, "#"))
    }
}
 
 
