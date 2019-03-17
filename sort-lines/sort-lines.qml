import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * This script sort selected lines in note text edit. It creates an array from selected lines,
 * sorts array and joins it again to output string.
 */

Script {
  /**
   * Initializes the custom actions
   */
  function init() {
    script.registerCustomAction("sortLinesAsc", "Sort lines ascending", "SortAsc", "view-sort-ascending", true, true);
    script.registerCustomAction("sortLinesDesc", "Sort lines descending", "SortDesc", "view-sort-descending", true, true);
  }

  function customActionInvoked(identifier) {
    if (identifier != "sortLinesAsc" && identifier != "sortLinesDesc") {
      return;
    }

    // getting selected text from the note text edit
    var text = script.noteTextEditSelectedText();

    switch (identifier) {
      // sort lines ascending
      case "sortLinesAsc":
        text = text.split("\n").sort(function(a, b) {
          return a.localeCompare(b, {
            'sensitivity': 'base'
          });
        }).join("\n");
        break;

        // sort lines descending
      case "sortLinesDesc":
        text = text.split("\n").sort(function(a, b) {
          return a.localeCompare(b, {
            'sensitivity': 'base'
          });
        }).reverse().join("\n");
        break;
    }

    // put the result to the current cursor position in the note text edit
    script.noteTextEditWrite(text);
  }
}
