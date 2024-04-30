import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * This script replaces a selected CSV block in your note with corresponding Markdown.
 * Selected CSV text block can have any delimiter char or string."
 * Selected CSV text block can start with a header row or not." 
*/
QtObject {
    /**
     * Initializes the custom action
     */
    function init() {
        // create a menu entry to replace csv text with an MD table
        script.registerCustomAction("csv-2-md", "Replace CSV with MD Table", "Markdown");
    }

    function customActionInvoked(identifier) {
        switch (identifier) {
            case "csv-2-md":
				// Present a dialog asking the delimiter char of the CSV file
				var delimiter = script.inputDialogGetItem("CSV Delimiter", "Please select the CSV delimiter char(s)", [",", ";","TAB","Other"]);
		        switch (delimiter) {
					case "TAB":
						delimiter = String.fromCharCode(0x0009); //that is the unicode hex code of TAB character
						break;
						//In case "Other" delimiter was selected another dialog is presented asking to provide the custom char or string
					case "Other":
						delimiter = script.inputDialogGetText("CSV delimiter", "Please enter custom delimiter char(s)", "");
						break;			
				}
				// Present a dialog asking the behavior with the first row and stores it in headerRow variable
				var headerRow = script.inputDialogGetItem("CSV Headers", "Please select the option that applies", ["1: First row is header", "2: First row is data"]).split(":")[0];
				// Initialize the text variable containing the current text selection
                var text = script.noteTextEditSelectedText().split("\n");
				// Initialize markdown variable
				var markdown = "| ";
				// Split the flow for CSV with/without header
				if (headerRow == "1"){				
			    	if (text.length >= 1){
			    		var headings = text[0].split(delimiter);
			    		for (var h = 0; h < headings.length; h++){
			    			markdown += headings[h] + " |";
			    		}
			    		markdown += "\r\n| ";
			    		for (var k = 0; k < headings.length; k++){
			    			markdown += "--- |";
			    		}
			    		markdown += "\r\n";
			    	}
			    	for (var i = 1; i < text.length; i++){
			    		var row = text[i].split(delimiter);
			    		var rowmd = "| ";
			    		for (var j = 0; j < row.length; j++){
			    			rowmd += row[j] + " |";
			    		}
			    		markdown += rowmd + "\r\n";
					}
				} else {
					for (var i = 1; i < text.length; i++){
						var row = text[i].split(delimiter);
						var rowmd = "| ";
						for (var j = 0; j < row.length; j++){
							rowmd += row[j] + " |";
						}
						markdown += rowmd + "\r\n";
					}	
				}
                script.noteTextEditWrite(markdown);
                break;
        }
    }
}