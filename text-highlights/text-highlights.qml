import QtQml 2.0
import QOwnNotesTypes 1.0

QtObject {
	property string backgroundColor;
	property string styleInEditor;
	property string styleForEditor;

	property variant settingsVariables: [
		{
			"identifier": "backgroundColor",
			"name": "Highlight Color",
			"description": "Color to highlight text with (name or #hex):",
			"type": "string",
			"default": "#FFFF00",
		},
		{
			"identifier": "styleInEditor",
			"name": "Highlight in editor panel",
			"description": "Do you want to highlight the text also in the editor panel?",
			"text": "Highlight text in the editor",
			"type": "boolean",
			"default": false,
		},
		{
			"identifier": "styleForEditor",
			"name": "Higlight style for the editor",
			"description": "Please select a style for the highlight in the editor (available only if the previous option is checked)",
			"type": "selection",
			"default": "8",
			"items": {
					"-1": "NoState",
					"0": "Link",
					"3": "Image",
					"4": "CodeBlock",
					"5": "CodeBlockComment",
					"7": "Italic",
					"8": "Bold",
					"9": "List",
					"11": "Comment",
					"12": "H1",
					"13": "H2",
					"14": "H3",
					"15": "H4",
					"16": "H5",
					"17": "H6",
					"18": "BlockQuote",
					"21": "HorizontalRuler",
					"22": "Table",
					"23": "InlineCodeBlock",
					"24": "MaskedSyntax",
					"25": "CurrentLineBackgroundColor",
					"26": "BrokenLink",
					"27": "FrontmatterBlock",
					"28": "TrailingSpace",
					"29": "CheckBoxUnChecked",
					"30": "CheckBoxChecked",
					"31": "StUnderline"
			},
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
		if (styleInEditor) {
			script.addHighlightingRule("(==)([^=]*)?==", "", 24, 1, -1);
			script.addHighlightingRule("==([^=]*)?(==)", "", 24, 2, -1);
			script.addHighlightingRule("==([^=]*)?==", "", parseInt(styleForEditor), 1, -1);
		}
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
