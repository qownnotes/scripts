import QtQml 2.2
import QOwnNotesTypes 1.0

/* This script adds toolbar buttons and context menu items to change selected text formatting:
 * - make it an ordered list with numbers or letters;
 * - make it an unordered list with markers of your choice;
 * - clear any list formatting.
 */

Script {
    property string setLetters
    property string setMarkers
    property bool useNestingLetters
    
    property variant settingsVariables: [
        {
            "identifier": "setLetters",
            "name": "Letters to use for ordered lists",
            "description": "Letters/symbol and their order to use for ordered list",
            "type": "string",
            "default": "abcdefghijklmnopqrstuvwxyz",
        },
        {
            "identifier": "setMarkers",
            "name": "Unordered list item markers",
            "description": "Put the symbols you want to use as marked list item markers. Spaces and commas are ignored",
            "type": "string",
            "default": "- • ‣",
        },
        {
            "identifier": "useNestingLetters",
            "name": "Use letters instead of numbers for second level of nested numbered list instead",
            "description": "Enable for letters, disable for numbers",
            "type": "boolean",
            "default": "false",
        },
    ]
    
    property string letters
    property string markers
    
    function init() {
        script.registerCustomAction("list 123", "1. 2. 3. list", "1.", "", true)
        
        if (setLetters) {
            letters = setLetters.replace(/[\s,;]/g, "")
            var orderedLettersListIcon = letters[0] + "."
            var orderedLettersListName = "%1. %2. %3. list".arg(letters[0]).arg(letters[1]).arg(letters[2])
            
            script.registerCustomAction("list abc", orderedLettersListName, orderedLettersListIcon, "", true)
        }
        
        if (setMarkers) {
            markers = setMarkers.replace(/[\s,;]/g, "")
            for (var n = 0; n < markers.length; n++)
                script.registerCustomAction("list " + markers[n], markers[n] + " list", markers[n])
        }
        script.registerCustomAction("list " + markers[0], "%1 list".arg(markers[0]), "", "", true, true)
        script.registerCustomAction("list clear", "Clear list formatting", "X", "", true)
    }
    
    // This will return the type of a list of the first line of text
    function getListType(text) {
        text = text.replace(/^ */, "")
        if (text.search(/\d[\.\d]*\. /) != -1)
            var type = "number"
        else if (letters.indexOf(text.substring(0, 1)) != -1 && text.substring(1, 3) == ". ")
            var type = "letter"
        else if (markers.indexOf(text.substring(0, 1)) != -1 && text.substring(1, 2) == " ")
            var type = "mark"
        else 
            var type = "none"
            
        return type
    }
    
    // This will clear the text of all list formatting the script uses
    function clearLine(text) {
        var line = text
        var lineType = getListType(line)
        
        while (lineType != "none") {
            if (lineType == "number")
                line = line.replace(/\d[\.\d]*\. /, "")
            else if (lineType == "letter")
                line = line.replace(/[^ ]\. /, "")
            else if (lineType == "mark")
                line = line.replace(/[^ ] /, "")
            
            lineType = getListType(line)
        }
        return line
    }
    
    function customActionInvoked(action) {        
        if (action.substring(0, 5) == "list ") {
            
            var type = getListType(script.noteTextEditSelectedText())
            var lines = script.noteTextEditSelectedText().split("\n")
            var newText = []
            lines[0] = lines[0].replace(/^ */, "")
            
            if (action == "list 123" && type == "number") {
                
                // Continue the list for nested and flat numbered list
                if (lines[0].search(/\d+\.\d+\. /) != -1) {
                    var number = lines[0].match(/^\d*/) 
                    lines[0] = lines[0].replace(number + ".", "")
                    var subnumber = lines[0].match(/^\d*/) - 1
                    lines[0] = " " + lines[0]
                }
                else { 
                    var number = lines[0].match(/\d*/) - 1
                    var subnumber = 0
                }
            }
            else if (action == "list abc" && type == "letter") {
                var number = letters.indexOf(lines[0].substring(0, 1))
                var subnumber = 0
            }
            else {
                var number = 0
                var subnumber = 0
            }
            
            for (var n = 0; n < lines.length; n++) {
                
                if (lines[n] == "" || lines[n].substring(0, 1) == "\t") {
                    newText.push(lines[n])
                    continue
                }
                
                var line = (clearLine(lines[n]))
                
                if (action == "list clear") {
                    newText.push(line.replace(/^ */, ""))
                    continue
                }
                else if (action == "list 123") {
                    
                    if (line.substring(0, 1) == " ") {
                        subnumber++
                        var mark = " " + number + "." + subnumber + ". "                       
                    }
                    else {
                        subnumber = 0
                        number++
                        var mark = number + ". "
                    }
                }
                else if (action == "list abc") {
                    var mark = letters[number++] + ". "
                }
                else { 
                    var mark = action.substring(5, 6) + " "
                }
                    
                newText.push(mark + line.replace(/^ */, ""))
            }
            
            script.noteTextEditWrite(newText.join("\n"))
        }
    }
}
 
