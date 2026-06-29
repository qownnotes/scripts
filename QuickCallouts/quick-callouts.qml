import QtQml 2.0
import QOwnNotesTypes 1.0

Script {
    /**
     * Initializes the custom buttons and menu items in QOwnNotes
     */
    function init() {
        script.registerCustomAction("insertInfoCallout", "Insert Info Callout", "Info Callout", "dialog-information");
        script.registerCustomAction("insertWarningCallout", "Insert Warning Callout", "Warning Callout", "dialog-warning");
        script.registerCustomAction("insertNoteCallout", "Insert Note Callout", "Note Callout", "dialog-warning");
    }

    /**
     * Triggers when you click the menu action or custom toolbar button
     */
    function customActionInvoked(identifier) {
        var selectedText = script.noteTextEditSelectedText();
        if (!selectedText) {
            selectedText = "Type your note content here...";
        }

        var resultHtml = "";

        switch (identifier) {
            case "insertNoteCallout":
                resultHtml = '<div style="background-color: #0C0640; padding: 15px; border-left: 5px solid #1300D6; border-radius: 4px;">' +
                    '<h2>📝 Note</h2>' +
                    '<strong>Items of Interest</strong>' +
                    '<p>' + selectedText + '</p>' +
                    '</div>';
                break;

            case "insertInfoCallout":
                resultHtml = '<div style="background-color: #579644; padding: 15px; border-left: 5px solid #1E6907; border-radius: 4px;">' +
                    '<h2>💡 Tip</h2>' +
                    '<p>' + selectedText + '</p>' +
                    '</div>';
                break;

            case "insertWarningCallout":
                resultHtml = '<div style="background-color: #A30741; padding: 15px; border-left: 5px solid #700327; border-radius: 4px;">' +
                    '<h2>⚠️ Caution</h2>' +
                    '<strong>Potential Pitfalls</strong>' +
                    '<p>' + selectedText + '</p>' +
                    '</div>';
                break;
        }

        if (resultHtml !== "") {
            script.noteTextEditWrite(resultHtml);
        }
    }
}
