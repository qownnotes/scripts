import QtQml 2.0

/**
 * This script creates a menu item and a button that adds a tag with the selected text to the current note
 */
QtObject {
    function customActionInvoked(identifier) {
        switch (identifier) {
        case "Text2tag":
            var tag = script.getTagByNameBreadcrumbList(script.noteTextEditSelectedText());
            var AlreadyTagged = false;
            for (var idx in tag.notes) {
                if (tag.notes[idx].id == script.currentNote().id) {
                    AlreadyTagged = true;
                }
            }
            if (!AlreadyTagged) {
                script.tagCurrentNote(script.noteTextEditSelectedText());
            }
            break;
        }
    }
    function init() {
        // create the menu entry
        script.registerCustomAction("Text2tag", "Create tag with selected text", "Text 2 tag", "bookmark-new", true, false, true);
    }
}
