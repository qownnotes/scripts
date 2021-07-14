import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * This script handles tagging in a note for tags in the note text like:
 * @tag1 @tag2 @tag3
 * @tag_one would tag the note with "tag one" tag.
 */

Script {
    property string tagMarker
    property bool putToBeginning
    property string tagHighlightColor

    property variant settingsVariables: [
        {
            "identifier": "tagMarker",
            "name": "Tag word marker",
            "description": "A word that starts with this characters is recognized as tag",
            "type": "string",
            "default": "@",
        },
        {
            "identifier": "putToBeginning",
            "name": "Put tags to beginning of note rather than to end",
            "description": "If enabled tags, added by UI, will be put to the first line of note or right after top headline",
            "type": "boolean",
            "default": "false",
        },
        {
            "identifier": "tagHighlightColor",
            "name": "The color for tag highlighting in note preview",
            "description": "Put a <a href=\"https://www.w3.org/TR/SVG/types.html#ColorKeywords\">color name</a> or a <a href=\"http://doc.qt.io/qt-5/qcolor.html#setNamedColor\">supported</a> color code here. Leave empty to disable tag highlighting in preview.",
            "type": "string",
            "default": "purple",
        },
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
        var tagRegExp = RegExp("\\B%1(?=($|\\s|\\b)) ?".arg(escapeRegExp(tagMarker + tagName).replace(/ /g, "_")));

        switch (action) {
            // adds the tag "tagName" to the note
            // the new note text has to be returned so that the note can be updated
            // returning an empty string indicates that nothing has to be changed
            case "add":
                // check if tag already exists
                if (noteText.search(tagRegExp) > 0) {
                    return "";
                }

                const tag = tagMarker + tagName.replace(/ /g, "_");

                // add the tag to the beginning or to the end of the note
                if (putToBeginning) {

                    // make an array of up to 3 first lines and other text as last item
                    var textLines = [];
                    for (var lineCount = 0, lineStart = 0, lineEnd = 0; lineCount != 3; lineCount++) {
                        lineEnd = noteText.indexOf("\n", lineStart + 1);

                        if (lineEnd == -1)
                            continue;

                        textLines.push(noteText.substring(lineStart, lineEnd));
                        lineStart = lineEnd;
                    }

                    textLines.push(noteText.substring(lineStart));

                    // if line after headline is a line for tags add tag there,
                    // or make a new line for tags after headline
                    function appendTag(text, tag, prepend) {
                        if (text.substring(0, tagMarker.length) == tagMarker ||
                            text.substring(1, tagMarker.length + 1) == tagMarker)
                            return text + " " + tag;
                        else
                            return prepend + tag + "\n" + text;
                    }

                    // use different tag line number depending on a headline type
                    if (textLines[0].substring(0, 1) == "#")
                        textLines[1] = appendTag(textLines[1], tag, "\n");
                    else if (textLines[1].search(/=+/) != -1)
                        textLines[2] = appendTag(textLines[2], tag, "\n");
                    else
                        textLines[0] = appendTag(textLines[0], tag, "");

                    noteText = textLines.join("");
                }

                else
                    noteText += "\n" + tag;

                return noteText;

            // removes the tag "tagName" from the note
            // the new note text has to be returned so that the note can be updated
            // returning an empty string indicates that nothing has to be changed
            case "remove":
                return noteText.replace(tagRegExp, "");

            // renames the tag "tagName" in the note to "newTagName"
            // the new note text has to be returned so that the note can be updated
            // returning an empty string indicates that nothing has to be changed
            case "rename":
                return noteText.replace(tagRegExp, tagMarker + newTagName.replace(/ /g, "_"));

            // returns a list of all tag names of the note
            case "list":
                var re = new RegExp("\\B%1([^\\s,;%1]+)".arg(escapeRegExp(tagMarker)), "gi"),
                    result, tagNameList = [];

                while ((result = re.exec(noteText)) !== null) {
                    tagName = result[1].replace(/_/g, " ");

                    // add the tag if it wasn't in the list
                    if (tagNameList.indexOf(tagName) ==  -1) {
                        tagNameList.push(tagName);
                    }
                }
                return tagNameList;
        }

        return "";
    }

    // Removes tag marker in note preview and highlights tag name with set color
   function preNoteToMarkdownHtmlHook(note, text, forExport) {
        if (tagHighlightColor == "")
            return;

        var re = new RegExp("\\B%1([^\\s,;%1]+)".arg(escapeRegExp(tagMarker)), "gi"), result;

        while ((result = re.exec(text)) !== null && result !== '')
            text = text.replace(result[0], '<b><font color="%1">%2</font></b>'.arg(tagHighlightColor).arg(result[1]));

        return text;
    }

    // Escapes a string for regular expressions
    function escapeRegExp(str) {
        return str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");
    }

    /**
     * Hook to feed the autocompletion with tags if the current word starts with the tag marker
     */
    function autocompletionHook() {
        // get the current word plus non-word-characters before the word to also get the tag marker
        var word = script.noteTextEditCurrentWord(true);

        if (!word.startsWith(tagMarker)) {
            return [];
        }

        // cut the tag marker off of the string and do a substring search for tags
        var tags = script.searchTagsByName(word.substr(tagMarker.length));

        // convert tag names with spaces to in-text tags with "_", "tag one" to @tag_one
        for (var i = 0; i < tags.length; i++) {
            tags[i] = tags[i].replace(/ /g, "_");
        }

        return tags;
    }
}
