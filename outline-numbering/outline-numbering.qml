import QtQml 2.0
import QOwnNotesTypes 1.0

/**
* This script inserts and updates the decimal outline numbering in a document
**/

Script {

    /**
  * This function finds all the headings and overwrites them with decimal outline numbering
  *
  * @param lines an array of strings containing the lines of the document
  * @return lines an array of strings with the heading lines updated
  **/
    function addOlNumbers(lines) {
        // Set the current numbers to their start
        var curNums = [0, 0, 0, 0, 0, 0];
        var depth = 0;
        var last_depth = 0;

        // Go through all the lines
        for (var n = 0; n < lines.length; n++) {
            // If we found a heading
            var match = lines[n].match(/^(#+)\s*([0-9\.]*)\s+(.*)$/);
            if (match) {
                // Get the depth - the heading number
                depth = match[1].length - 1;

                // If the current depth is at a higher level than the last, reset all the lower level values
                if (depth < last_depth) {
                    for (var j = depth + 1; j < curNums.length; j++) {
                        curNums[j] = 0; // Reset lower-level numbering
                    }
                }

                // Increment the value for the current depth and save this depth as the last one
                curNums[depth] += 1;
                last_depth = depth;

                // Rewrite the current line with the number
                lines[n] = match[1] + " " + getOlNumber(curNums, depth) + " " + match[3];
            }
        }
        return lines;
    }

    /**
  * This function is invoked when a custom action is triggered
  *
  * @param action string identifier defined in registerCustomAction
  **/
    function customActionInvoked(action) {
        if (action == "outlineNumbering") {
            // Get the document and update the lines
            var lines = script.currentNote().noteText.split("\n");
            var updated_lines = addOlNumbers(lines);

            // Save the current cursor position
            var cursorPositionStart = script.noteTextEditSelectionStart();
            var cursorPositionEnd = script.noteTextEditSelectionEnd();

            // Select all and overwrite with the new text
            script.noteTextEditSelectAll();
            script.noteTextEditWrite(updated_lines.join("\n"));

            // Restore the cursor position
            script.noteTextEditSetSelection(cursorPositionStart, cursorPositionEnd);
        }
    }

    /**
  * Based on the current depth and the current digits, return the outline number string
  * which is the first depth number of elements in the nums array joined by "."
  *
  * @param nums a 6-element array containing the current outline numbering values
  * @param depth the current depth that we want a number for
  * @return string containing #depth numbers separated by "."s
  *
  * Example: getOlNumber([1,2,3,4,5,6], 4) returns "1.2.3.4"
  **/
    function getOlNumber(nums, depth) {
        var num = "";
        for (var n = 0; n < depth + 1; n++) {
            num += nums[n];

            // Only add the delimiter if there are more numbers to get
            if (n < depth) {
                num += ".";
            }
        }

        // Ensure that the number always ends with a full stop
        num += ".";

        return num;
    }

    /**
  * Initializes the custom action
  **/
    function init() {
        script.registerCustomAction("outlineNumbering", "Update Outline Numbers", "Outline Numbers", "", true, true);
    }
}
