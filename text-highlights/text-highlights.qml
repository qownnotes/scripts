import QtQml 2.0
import QOwnNotesTypes 1.0

QtObject {
	property string highlightColor;
	
	property variant settingsVariables: [
		{
			"identifier": "highlightColor",
			"name": "Highlight Color",
			"description": "Color to highlight text as",
			"type": "string",
			"default": "FFFF00",
		}
	];

	function noteToMarkdownHtmlHook(note, html) {
		var stylesheet = ".highlighted {background-color: #" + highlightColor + ";}";
		html = html.replace(/==(.+?)==/g, "<span class='highlighted'>$1</span>");
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
