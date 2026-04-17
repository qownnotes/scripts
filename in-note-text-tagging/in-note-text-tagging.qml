import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * This script handles tagging in a note for tags in the note text like:
 * #tag1 #tag2 #tag3 #tag4
 * @tag_one would tag the note with "tag one" tag.
 * One or both markers can be enabled independently via the settings.
 *  - The two checkboxes are independent — you can enable # alone, @ alone, both, or freely change the characters       
 * - If both are disabled, no tags are detected (clean empty return)
 * - maxTagLength = 0 disables the limit → * quantifier in the regex                                                   
 * - maxTagLength = 32 → {0,31} quantifier (1 mandatory letter + 31 more = 32 total)                                   
 * - The tagBodyQuantifier() function computes the correct quantifier on each call

 */

Script {
    property bool putToBeginning
    property variant settingsVariables: [
        {
            "identifier": "useMarker1",
            "name": "Enable primary tag marker",
            "description": "Recognize words starting with the primary marker as tags",
            "type": "boolean",
            "default": "true"
        },
        {
            "identifier": "tagMarker",
            "name": "Primary tag marker character",
            "description": "Character used as primary tag prefix (default: #)",
            "type": "string",
            "default": "#"
        },
        {
            "identifier": "useMarker2",
            "name": "Enable secondary tag marker",
            "description": "Recognize words starting with the secondary marker as tags",
            "type": "boolean",
            "default": "false"
        },
        {
            "identifier": "tagMarker2",
            "name": "Secondary tag marker character",
            "description": "Character used as secondary tag prefix (default: @)",
            "type": "string",
            "default": "@"
        },
        {
            "identifier": "maxTagLength",
            "name": "Maximum tag length",
            "description": "Maximum number of characters allowed in a tag (0 = no limit, default: 32)",
            "type": "integer",
            "default": "32"
        },
        {
            "identifier": "putToBeginning",
            "name": "Put tags to beginning of note rather than to end",
            "description": "If enabled, tags added via UI will be put to the first line of note or right after top headline",
            "type": "boolean",
            "default": "false"
        },
    ]
    property bool useMarker1
    property string tagMarker
    property bool useMarker2
    property string tagMarker2
    property int maxTagLength

    // Returns the preferred marker for writing new tags: primary if enabled, otherwise secondary
    function writeMarker() {
        return (useMarker1 && tagMarker) ? tagMarker : tagMarker2;
    }

    // Returns an array of currently active tag markers
    function allMarkers() {
        var markers = [];
        if (useMarker1 && tagMarker) markers.push(tagMarker);
        if (useMarker2 && tagMarker2) markers.push(tagMarker2);
        return markers;
    }

    // Returns a regex alternation string matching any active marker, or null if none active
    function markerPattern() {
        var markers = allMarkers();
        if (markers.length === 0) return null;
        return "(?:" + markers.map(escapeRegExp).join("|") + ")";
    }

    // Returns the quantifier for tag body chars based on maxTagLength setting.
    // First letter is always required; this governs the *remaining* characters.
    function tagBodyQuantifier() {
        if (maxTagLength > 0) return "{0," + (maxTagLength - 1) + "}";
        return "*";
    }

    /**
     * Hook to feed the autocompletion with tags if the current word starts with any active marker
     */
    function autocompletionHook() {
        var pattern = markerPattern();
        if (!pattern) return [];

        // get the current word plus non-word-characters before the word to also get the tag marker
        var word = script.noteTextEditCurrentWord(true);

        var matchedMarker = "";
        var markers = allMarkers();
        for (var i = 0; i < markers.length; i++) {
            if (word.startsWith(markers[i])) {
                matchedMarker = markers[i];
                break;
            }
        }

        if (!matchedMarker) {
            return [];
        }

        // cut the tag marker off of the string and do a substring search for tags
        var tags = script.searchTagsByName(word.substr(matchedMarker.length));

        // convert tag names with spaces to in-text tags with "_", "tag one" to @tag_one
        for (var j = 0; j < tags.length; j++) {
            tags[j] = tags[j].replace(/ /g, "_");
        }

        return tags;
    }

    // Escapes a string for regular expressions
    function escapeRegExp(str) {
        return str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");
    }

    // If the line already starts with a tag marker, appends the tag to it.
    // Otherwise inserts a new tag line before it, prefixed by prepend.
    function appendTag(text, tag, prepend) {
        var markers = allMarkers();
        for (var mi = 0; mi < markers.length; mi++) {
            var m = markers[mi];
            if (text.substring(0, m.length) == m || text.substring(1, m.length + 1) == m)
                return text + " " + tag;
        }
        return prepend + tag + "\n" + text;
    }

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
        var pattern = markerPattern();
        if (!pattern) return action === "list" ? [] : "";

        var noteText = note.noteText;
        // Match a specific known tag with any active marker.
        // Group 1: leading space/newline, preserved on replace. Group 2: the matched marker.
        var tagRegExp = RegExp("(^|\\s)(%1)%2(?=($|\\s)) ?".arg(pattern).arg(escapeRegExp(tagName).replace(/ /g, "_")), "m");

        switch (action) {
        // adds the tag "tagName" to the note
        // the new note text has to be returned so that the note can be updated
        // returning an empty string indicates that nothing has to be changed
        case "add":
            // check if tag already exists
            if (noteText.search(tagRegExp) !== -1) {
                return "";
            }

            var tag = writeMarker() + tagName.replace(/ /g, "_");

            // add the tag to the beginning or to the end of the note
            if (putToBeginning) {

                // make an array of up to 3 first lines and other text as last item
                var textLines = [];
                var lineCount = 0;
                var lineStart = 0;
                var lineEnd = 0;

                for (; lineCount != 3; lineCount++) {
                    lineEnd = noteText.indexOf("\n", lineStart + 1);

                    if (lineEnd == -1)
                        continue;

                    textLines.push(noteText.substring(lineStart, lineEnd));
                    lineStart = lineEnd;
                }

                textLines.push(noteText.substring(lineStart));

                // use different tag line number depending on a headline type
                if (textLines[0].substring(0, 1) == "#")
                    textLines[1] = appendTag(textLines[1], tag, "\n");
                else if (textLines[1].search(/=+/) != -1)
                    textLines[2] = appendTag(textLines[2], tag, "\n");
                else
                    textLines[0] = appendTag(textLines[0], tag, "");

                noteText = textLines.join("");
            } else
                noteText += "\n" + tag;

            return noteText;

        // removes the tag "tagName" from the note
        // the new note text has to be returned so that the note can be updated
        // returning an empty string indicates that nothing has to be changed
        case "remove":
            return noteText.replace(tagRegExp, "$1");

        // renames the tag "tagName" in the note to "newTagName"
        // the new note text has to be returned so that the note can be updated
        // returning an empty string indicates that nothing has to be changed
        case "rename":
            return noteText.replace(tagRegExp, "$1$2" + newTagName.replace(/ /g, "_"));

        // returns a list of all tag names of the note
        case "list":
            // Exclude all marker characters from tag content.
            // Requires a space/newline (or start of line) before the marker,
            // a letter (including accented/Unicode) as first char.
            // Max length is controlled by tagBodyQuantifier().
            var excludedChars = allMarkers().map(escapeRegExp).join("");
            var re = new RegExp(
                "(?:^|\\s)" + pattern +
                "([a-zA-Z" +
                "\\u00C0-\\u024F" +   // Latin Extended A+B
                "\\u0250-\\u02AF" +   // IPA Extensions
                "\\u0370-\\u03FF" +   // Greek and Coptic
                "\\u0400-\\u052F" +   // Cyrillic + Supplement
                "\\u0530-\\u058F" +   // Armenian
                "\\u05D0-\\u05FF" +   // Hebrew
                "\\u0600-\\u06FF" +   // Arabic
                "\\u0900-\\u0D7F" +   // Indic (Devanagari, Bengali, Gurmukhi, Gujarati, Oriya, Tamil, Telugu, Kannada, Malayalam)
                "\\u0E00-\\u0EFF" +   // Thai and Lao
                "\\u10A0-\\u10FF" +   // Georgian
                "\\u1200-\\u137F" +   // Ethiopic
                "\\u1E00-\\u1FFF" +   // Latin Extended Additional + Greek Extended
                "\\u3040-\\u30FF" +   // Hiragana + Katakana
                "\\u3400-\\u4DBF" +   // CJK Extension A
                "\\u4E00-\\u9FFF" +   // CJK Unified Ideographs
                "\\uAC00-\\uD7AF" +   // Hangul Syllables
                "]" +
                "[^\\s,;" + excludedChars + "]" + tagBodyQuantifier() + ")",
                "gim"
            ), result, tagNameList = [];

            while ((result = re.exec(noteText)) !== null) {
                tagName = result[1].replace(/_/g, " ");

                // add the tag if it wasn't in the list
                if (tagNameList.indexOf(tagName) == -1) {
                    tagNameList.push(tagName);
                }
            }
            return tagNameList;
        }

        return "";
    }
}
