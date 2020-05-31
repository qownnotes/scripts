import QtQml 2.0
import QOwnNotesTypes 1.0

QtObject {
	property string backgroundColor;

	property variant settingsVariables: [
		{
			"identifier": "backgroundColor",
			"name": "Highlight Color",
			"description": "Color to highlight text with (name or #hex):",
			"type": "string",
			"default": "#FFFF00",
		}
	];
    
    /**
     * This function is called when the markdown html of a note is generated
     *
     * It allows you to modify this html
     * This is for example called before by the note preview
     *
     * The method can be used in multiple scripts to modify the html of the preview
     *
     * @param {NoteApi} note - the note object
     * @param {string} html - the html that is about to being rendered
     * @param {string} forExport - the html is used for an export, false for the preview
     * @return {string} the modified html or an empty string if nothing should be modified
     */
    function noteToMarkdownHtmlHook(note, html, forExport) {
		var stylesheet = "mark {background-color:" + backgroundColor + ";}";
		html = html.replace(/==(.+?)==/g, "<mark>$1</mark>");
		html = html.replace("</style>", stylesheet + "</style>");
		return html;
	}

	function init() {
		script.registerCustomAction("addHighlights", "Add Highlight Marks", "Add Highlights", "text-wrap");
	}

	function customActionInvoked(identifier) {
		switch (identifier) {
			case "addHighlights":
				// getting selected text from the note text edit
				var text = "==" + script.noteTextEditSelectedText() + "==";
				// put the result to the current cursor position in the note text edit
				script.noteTextEditWrite(text);
			break;
		}
	}
}
