import QtQml 2.0
import QOwnNotesTypes 1.0

/**
 * With this script you can right click in the note edit and paste previously copied HTML
 * from a website as GitHub Markdown with the help of Pandoc.
 */
Script {
    property string pandocPath

    // register your settings variables so the user can set them in the script settings
    property variant settingsVariables: [
        {
            "identifier": "pandocPath",
            "name": "Pandoc path",
            "description": "Please select the path to your Pandoc executable:",
            "type": "file",
            "default": "pandoc"
        },
    ]

    /**
     * This function is invoked when a custom action is triggered
     * in the menu or via button
     *
     * @param identifier string the identifier defined in registerCustomAction
     */
    function customActionInvoked(identifier) {
        if (identifier != "html2Markdown") {
            return;
        }

        var html = script.clipboard(true);

        // you need pandoc to convert HTML to Markdown
        /**
         * UPDATE 2021-12-01:
         *  replacing "markdown_github" with "gfm" as markdown_github is now deprecated and does not have all of the features as gfm
         *  Original call: var params = ["-f", "html", "-t", "markdown_github"];
        */
        var params = ["-f", "html", "-t", "gfm"];
        var markdown = script.startSynchronousProcess(pandocPath, params, html);

        script.noteTextEditWrite(markdown);
    }

    /**
     * Initializes the custom action
     */
    function init() {
        script.registerCustomAction("html2Markdown", "Paste HTML as GitHub Markdown", "GitHub Markdown", "edit-paste", true, true);
    }
}
