import QtQml 2.0

/**
 * This script adds custom styles to the application
 *
 * You can get the object names from the *.ui files, for example
 * https://github.com/pbek/QOwnNotes/blob/develop/src/mainwindow.ui
 *
 * Take a look at http://doc.qt.io/qt-5/stylesheet-reference.html for
 * a reference of what styles are available.
 */
QtObject {
    property string customStylesheet

    // register your settings variables so the user can set them in the script settings
    property variant settingsVariables: [
        {
            "identifier": "customStylesheet",
            "name": "Custom stylesheet",
            "description": "Please enter your custom stylesheet:",
            "type": "text",
            "default": "QTreeWidget#noteTreeWidget {font-family: Pacifico; font-size: 28px;}"
        },
    ]

    /**
     * Adds custom styles
     */
    function init() {
        // add a custom stylesheet to increase font size in the note list and set a font
        script.addStyleSheet(customStylesheet);
    }
}
