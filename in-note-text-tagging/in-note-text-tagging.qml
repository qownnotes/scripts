import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * This script handles tagging in a note for tags in the note text like:
 * @tag1 @tag2 @tag3
 * @tag_one would tag the note with "tag one" tag.
 */
Script {
    property string tagMarker

    property variant settingsVariables: [
        {
            "identifier": "tagMarker",
            "name": "Tag word marker",
            "description": "A word that starts with this characters is recognized as tag",
            "type": "string",
            "default": "@",
        }
    ]
    
    /**
     * Handles note tagging for a note
     *
     * This function is called when tags are added to, removed from or renamed in
     * a note or the tags of a note should be listed
     *
     * @param note
     * @param action can be "add", "remove", "rename" or "list"
     * @param tagName tag name to be added, removed or renamed
     * @param newTagName tag name to be renamed to if action = "rename"
     * @return string or string-list (if action = "list")
     */
    function noteTaggingHook(note, action, tagName, newTagName) {
        var noteText = note.noteText;
        var tagRegExp = RegExp("\\B%1($|\\s|\\b)".arg(escapeRegExp(tagMarker + tagName).replace(" ", "_")));

        switch (action) {
            // adds the tag "tagName" to the note
            // the new note text has to be returned so that the note can be updated
            // returning an empty string indicates that nothing has to be changed
            case "add":
                // check if tag already exists
                if (noteText.search(tagRegExp) > 0) {
                    return "";
                }

                // add the tag at the end of the note
                noteText += "\n" + tagMarker + tagName.replace(" ", "_");
                return noteText;
                break;

            // removes the tag "tagName" from the note
            // the new note text has to be returned so that the note can be updated
            // returning an empty string indicates that nothing has to be changed
            case "remove":
                noteText = noteText.replace(tagRegExp, "");
                return noteText;
                break;

            // renames the tag "tagName" in the note to "newTagName"
            // the new note text has to be returned so that the note can be updated
            // returning an empty string indicates that nothing has to be changed
            case "rename":
                noteText.replace(tagRegExp, tagMarker + newTagName.replace(" ", "_"));
                return noteText;
                break;

            // returns a list of all tag names of the note
            case "list":
                var re = new RegExp("\\B%1([^\\s,;]+)".arg(escapeRegExp(tagMarker)), "gi"),
                    result, tagNameList = [];

                while ((result = re.exec(noteText)) !== null) {
                    var tagName = result[1].replace("_", " ");
                    
                    // add the tag if it wasn't in the list
                    if (tagNameList.indexOf(tagName) ==  -1) {
                        tagNameList.push(tagName);
                    }
                }
                return tagNameList;
                break;
        }
    
        return "";
    }
    
    /**
     * Escapes a string for regular expressions
     */
    function escapeRegExp(str) {
        return str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");
    }
}
