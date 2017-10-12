import QtQml 2.2
import QOwnNotesTypes 1.0

/* This script adds toolbar buttons and context menu items to change selected text formatting:
 * - make it an ordered list with numbers or letters;
 * - make it an unordered list with markers of your choice;
 * - clear any list formatting.
 */

Script {
    property string orderedLetters
    property string unorderedMarkers
    
    property variant settingsVariables: [
        {
            "identifier": "orderedLetters",
            "name": "Letters to use for ordered lists",
            "description": "Letters/symbol and their order to use for ordered list",
            "type": "string",
            "default": "abcdefghijklmnopqrstuvwxyz",
        },
        {
            "identifier": "unorderedMarkers",
            "name": "Unordered list item markers",
            "description": "Put the symbols you want to use as marked list item markers. Spaces and commas are ignored.",
            "type": "string",
            "default": "- • ‣",
        }
    ]
    
    property string letters
    property string markers
    
    function init() {
        script.registerCustomAction("list 123", "1. 2. 3. list", "1.", "", true)
        
        if (orderedLetters) {
            letters = orderedLetters.replace(/[\s,;]/g, "")
            var orderedLettersListIcon = letters[0] + "."
            var orderedLettersListName = "%1. %2. %3. list".arg(letters[0]).arg(letters[1]).arg(letters[2])
            
            script.registerCustomAction("list abc", orderedLettersListName, orderedLettersListIcon, "", true)
        }
        
        if (unorderedMarkers) {
            markers = unorderedMarkers.replace(/[\s,;]/g, "")
            for (var n = 0; n < markers.length; n++) {
                if (markers[n] != " " && markers[n] != ",")
                    script.registerCustomAction("list " + markers[n], markers[n] + " list", markers[n])
            }
        }
        script.registerCustomAction("list " + markers[0], "%1 list".arg(markers[0]), "", "", true, true)
        script.registerCustomAction("list clear", "Clear list formatting", "X", "", true)
    }
    
    function getListType(text) {
        if (text.search(/^\d+\. /) == 0)
            var type = "number"
        else if (letters.indexOf(text.substring(0, 1)) != -1 && text.substring(1, 3) == ". ")
            var type = "letter"
        else if (markers.indexOf(text.substring(0, 1)) != -1 && text.substring(1, 2) == " ")
            var type = "mark"
        else 
            var type = "none"
            
        return type
    }
    
    function clearLine(text) {
        var line = text
        var lineType = getListType(line)
        
        while (lineType != "none") {
            if (lineType == "number")
                line = line.replace(/^\d+\. /, "")
            else if (lineType == "letter")
                line = line.substring(3)
            else if (lineType == "mark")
                line = line.substring(2)
            
            lineType = getListType(line)
        }
        return line
    }
    
    function customActionInvoked(action) {        
        if (action.substring(0, 5) == "list ") {
            
            var type = getListType(script.noteTextEditSelectedText())
            var lines = script.noteTextEditSelectedText().split("\n")
            var newText = []
            
            if (action == "list 123" && type == "number")
                number = lines[0].match(/^\d+/) - 1
            else if (action == "list abc" && type == "letter")
                number = letters.indexOf(lines[0].substring(0, 1))
            else 
                var number = 0

            for (var n = 0; n < lines.length; n++) {
                
                if (lines[n] == "" || lines[n].search(/^\s/) != -1) {
                    newText.push(lines[n])
                    continue
                }
                
                var line = (clearLine(lines[n]))
                
                if (action == "list clear") {
                    newText.push(line)
                    continue
                }
                else if (action == "list 123") {               
                    number++
                    var mark = number + ". "
                }
                else if (action == "list abc")
                    var mark = letters[number++] + ". "
                else 
                    var mark = action.substring(5, 6) + " "
                    
                newText.push(mark + line)
            }
            
            script.noteTextEditWrite(newText.join("\n"))
        }
    }
}
 
