import QtQml 2.0
import QOwnNotesTypes 1.0

QtObject {
	property string highlightColour;

	property variant settingsVariables: [
		{
			"identifier": "highlightColour",
			"name": "Highlight Colour",
			"description": "Colour to highlight text with (name or #hex):",
			"type": "string",
			"default": "#FFFF00",
		}
	];

	function noteToMarkdownHtmlHook(note, html) {
		var stylesheet = "mark {background-color:" + highlightColour + ";}";
		html = html.replace(/==(.+?)==/g, "<mark>$1</mark>");
		html = html.replace("</style>", stylesheet + "</style>");
		return html;
	}
}
