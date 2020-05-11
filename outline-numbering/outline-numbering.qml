import QtQml 2.0
import QOwnNotesTypes 1.0


/**
* This script inserts and updates the decimal outline numbering in a document
**/

Script {

  /**
  * Initializes the custom action
  **/
  function init() {
    script.registerCustomAction("outlineNumbering", "Refresh Outline Numbers in Headings", "Outline Numbers", "", true, true);
  }

  /**
  * this function finds all the headings and overwrites them with decimal outline numbering
  *
  * @param lines an array of strings containing the lines of the document
  * @return lines an array of strings with the heading lines updated
  **/
  function addOlNumbers(lines) {
    // set the current nums to their start
    var curNums = [0,0,0,0,0,0];
    var depth = 0;
    var last_depth=0;

    // go through all the lines
    for (var n = 0; n < lines.length; n++) {
      // if we found a heading
      var match = lines[n].match(/^(#+)\s*([0-9\.]*)\s+(.*)$/);
      if (match) {
        
        // get the depth - the heading number
        depth=match[1].length-1;

        // if the current depth is at a higher level than the last, reset all the lower level vals
        if (depth < last_depth) {
          for (var n=depth; n< curNums.length ; n++) {
            curNums[n] == 0;
          }
        }
        
        // up the val for the current depth and save this depth as the last one
        curNums[depth] += 1;
        last_depth = depth;

        // rewrite the currentt line with the number
        lines[n] = match[1] + " " + getOlNumber(curNums, depth) + " " + match[3];

      };
    }
    return lines;
  }
 
  /**
  * based on the current depth and the current digits, return the outline number string
  * which is the first depth number of elements in the nums array joined by a "."
  * 
  * @param nums a 6 element array containing the current oultline numbering values
  * @param depth the current depth that we want a number for
  **/
  function getOlNumber(nums, depth) {

    var num = "";
    for (var n=0; n<depth+1; n++) {
      num += nums[n];

      // only add the delim if there are more numbers to get
      if (n < depth) { num += ".";};
    }
    return num;
  }

  /**
  * this function is invoked when a custom action is triggered
  *
  * @param action string identifier defined in registerCumstomAction
  **/
  function customActionInvoked(action) {
    if (action == "outlineNumbering")
      // get the document and update the lines
      var lines = script.currentNote().noteText.split("\n");
      var updated_lines = addOlNumbers(lines);
      
      // save the current cursor position
      var cursorPositionStart = script.noteTextEditSelectionStart();
      var cursorPositionEnd = script.noteTextEditSelectionEnd();

      script.log("presave selection: " + cursorPositionStart + "," + cursorPositionEnd);

      // select all and overwrite with the new text
      script.noteTextEditSelectAll();
      script.noteTextEditWrite(updated_lines.join("\n"));

      // restore the cursor position
      script.noteTextEditSetSelection(cursorPositionStart, cursorPositionEnd);
    }
  }
}
