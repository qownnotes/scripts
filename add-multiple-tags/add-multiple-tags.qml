import QtQml 2.0

/**
 * This script creates a menu item and a button with which you can add space separated tags to the current note
 */
QtObject {
    /**
     * Initializes the custom action
     */
    function init() {
        // create the menu entry
         script.registerCustomAction("multipleTags", "Add Multiple tags", "fav", "bookmark-new");
    }

    /**
     * This function is invoked when a custom action is triggered
     * in the menu or via button
     * 
     * @param identifier string the identifier defined in registerCustomAction
     */
    function customActionInvoked(identifier) {
        switch (identifier) {
            // add tags to the current note
            case "multipleTags":
                var tags = script.inputDialogGetText("Add tags", "Enter tags separated by space", "");
                script.log(tags);
                var tagsList = tags.split(' ');
                var i;
                for (i = 0; i  < tagsList.length; i++) {
                    script.tagCurrentNote(tagsList[i]);
                }
                break;
        }
    }
}
