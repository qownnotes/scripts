import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * This script unwraps a paragraph into a single line. Useful for text pasted from PDFs to enable dynamic word wrapping.
 */

Script {
  /**
   * Initializes the custom actions
   */
  function init() {
    script.registerCustomAction("unWrap", "Unwrap Text", "unWrap", "text-field", false, true);
  }

  function customActionInvoked(identifier) {
    if (identifier != "unWrap") {
      return;
    }

    // getting selected text from the note text edit
    var text = script.noteTextEditSelectedText();
    var newText = ("");
    
    // turn text into an array of lines
    text = text.split("\n");
    var numLines = text.length;
    
    // build unwrapped text by adding each line, adjusting white space
    // and removing dashes on split words
    for (var i = 0; i < numLines; i++){
        newText = newText + text[i];
        newText.trim();
        if (newText.substr(-1) != "-"){
        newText = newText + " ";
        } else {
        newText = newText.slice(0, -1);
        }
    }
    // put the unwrapped text to the current cursor position in the note text edit
    script.noteTextEditWrite(newText);
  }
}
