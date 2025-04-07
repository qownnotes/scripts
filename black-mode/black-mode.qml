import QtQml 2.0

/**
 * This script makes the dark mode even darker
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
            "default": ""
        },
    ]

    /**
     * Adds custom styles
     */
    function init() {
        script.addStyleSheet("
            QWidget {
                background-color: black;
                color: white;
            }

            QPlainTextEdit
            {
                background-color: #000000;;
                color: #0A65CF;
                border-radius: 2px;
                border: 1px solid #000000;
            }

            QTabBar::tab:top {
                color: #b1b1b1;
                border: 1px solid #4A4949;
                border-bottom: 1px transparent black;
                background-color: #000000;
                padding: 5px;
                border-top-left-radius: 2px;
                border-top-right-radius: 2px;
            }

            QTabBar::tab:top:!selected
            {
                color: #b1b1b1;
                background-color: #000000;
                border: 1px transparent #4A4949;
                border-bottom: 1px transparent #4A4949;
                border-top-left-radius: 0px;
                border-top-right-radius: 0px;
            }

            QMenu
            {
                border: 1px solid #000000;
                color: silver;
                margin: 2px;
            }
        ");

        script.addStyleSheet(customStylesheet);
    }
}
