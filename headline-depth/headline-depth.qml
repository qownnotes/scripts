import QtQml 2.2
import QOwnNotesTypes 1.0

// This script adds toolbar buttons to increase and decrease the depth of all the headlines in selected text

Script {   
    function init() {
        script.registerCustomAction("#+", "Increase headline depth", "#+")
        script.registerCustomAction("#-", "Decrease headline depth", "#-")
    }
    
    function customActionInvoked(action) {
	var currentSelectedText = script.noteTextEditSelectedText();
    	if (script.noteTextEditSelectedText() == "") {
	    script.noteTextEditSelectCurrentLine();
	    currentSelectedText = script.noteTextEditSelectedText();
    	}
    	
    	if (action == "#+")
            script.noteTextEditWrite(currentSelectedText.replace(/^\#/gm, "##"))
	    
        if (action == "#-")
            script.noteTextEditWrite(currentSelectedText.replace(/^\#\#/gm, "#"))
    }
}
 
 
