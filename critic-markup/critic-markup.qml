import QtQml 2.0
import QOwnNotesTypes 1.0

QtObject {
	property string commentsBackgroundColor;
	property string commentsHightlightsColor;
	property string commentsDeletionColor;
	property string commentsAdditionColor;

	property variant settingsVariables: [
		{
			"identifier": "commentsBackgroundColor",
			"name": "Comments Background Color",
			"description": "Color for the backgroud of the Critc Markup comments (name or #hex):",
			"type": "string",
			"default": "#FFFF00",
		},
		{
			"identifier": "commentsHightlightsColor",
			"name": "Hightlights Border Color",
			"description": "Color for the hightlights in Critc Markup (name or #hex):",
			"type": "string",
			"default": "#ff832b",
		},
		{
			"identifier": "commentsDeletionColor",
			"name": "Deletions Text Color",
			"description": "Color for the deleted text in Critc Markup (name or #hex):",
			"type": "string",
			"default": "#FF0000",
		},
		{
			"identifier": "commentsAdditionColor",
			"name": "Addition Text Color",
			"description": "Color for the added text in Critc Markup (name or #hex):",
			"type": "string",
			"default": "#008000",
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
		var stylesheet = "span.critic.comment {background-color:" + commentsBackgroundColor + "; padding-left: 4px; border-left: 4px solid "+ commentsHightlightsColor +"; } del {color: "+ commentsDeletionColor +" ; text-decoration: line-through;} ins {color: "+ commentsAdditionColor +" ; text-decoration: underline;} mark {background-color:" + commentsHightlightsColor + ";}";
		html = html.replace(/\{\+\+(.*?)\+\+\}/gm, "<ins>$1</ins>");
		html = html.replace(/\{\-\-(.*?)\-\-\}/gm, "<del>$1</del>");
		html = html.replace(/\{(?:<s>|~~)(.*?)\~&gt;(.*?)(?:<\/s>|~~)\}/gm, "<del>$1</del><ins>$2</ins>");
		html = html.replace(/\{(?:<mark>|==)(.*?)(?:<\/mark>|==)\}\{&gt;&gt;(.*?)&lt;&lt;\}/gm, "<mark>$1</mark><span class='critic comment'>$2</span>");
		html = html.replace(/\{&gt;&gt;(.*?)&lt;&lt;\}/gm, "<span class='critic comment'>$1</span>");
		html = html.replace("</style>", stylesheet + "</style>");
		return html;
	}

	function init() {
		script.registerCustomAction("tranformToCMComments", "Transform the text to comment with Critic Markup", "Transform the text to comment with Critic Markup", "edit-comment");
		script.registerCustomAction("tranformToCMAdded", "Mark the text as added with Critic Markup", "Mark the text as added with Critic Markup", "list-add");
		script.registerCustomAction("tranformToCMDeleted", "Mark the text as deleted with Critic Markup", "Mark the text as deleted with Critic Markup", "list-remove");
		script.registerCustomAction("tranformToCMSubstitute", "Substitute the text with Critic Markup", "Substitute the text with Critic Markup", "entry-edit");
		script.registerCustomAction("tranformToCMHighlighted", "Hightlight the text with Critic Markup", "Hightlight the text with Critic Markup", "edit-comment");
	}

	function customActionInvoked(identifier) {
		switch (identifier) {
			case "tranformToCMComments":
				// getting selected text from the note text edit
				var text = "{>>" + script.noteTextEditSelectedText() + "<<}";
				// put the result to the current cursor position in the note text edit
				script.noteTextEditWrite(text);
			break;
			case "tranformToCMAdded":
				// getting selected text from the note text edit
				var text = "{++" + script.noteTextEditSelectedText() + "++}";
				// put the result to the current cursor position in the note text edit
				script.noteTextEditWrite(text);
			break;
			case "tranformToCMDeleted":
				// getting selected text from the note text edit
				var text = "{--" + script.noteTextEditSelectedText() + "--}";
				// put the result to the current cursor position in the note text edit
				script.noteTextEditWrite(text);
			break;
			case "tranformToCMSubstitute":
				// getting selected text from the note text edit
				var text = "{~~" + script.noteTextEditSelectedText() + "~> NEWTEXT ~~}";
				// put the result to the current cursor position in the note text edit
				script.noteTextEditWrite(text);
			break;
			case "tranformToCMHighlighted":
				// getting selected text from the note text edit
				var text = "{==" + script.noteTextEditSelectedText() + "==}{>> COMMENTS <<}";
				// put the result to the current cursor position in the note text edit
				script.noteTextEditWrite(text);
			break;
		}
	}
}
