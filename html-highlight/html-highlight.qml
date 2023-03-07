import QtQml 2.0
import QOwnNotesTypes 1.0

QtObject {
	property string styleForMainColor;
	property string styleForTagName;
	property string styleForAttrName;
	property string styleForAttr;
    property var qownStyles: {
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
			};

	property var settingsVariables: [
		{
			"identifier": "styleForMainColor",
			"name": "Main highlight style for HTML tags",
			"description": "Please select a style for the main highlight of HTML tags",
			"type": "selection",
			"default": "3",
			"items": qownStyles
			},
		{
			"identifier": "styleForTagName",
			"name": "Highlight style for HTML tags names",
			"description": "Please select a style for the highlight for the HTML tags names",
			"type": "selection",
			"default": "11",
			"items": qownStyles
		},
		{
			"identifier": "styleForAttrName",
			"name": "Highlight style for HTML attributes names",
			"description": "Please select a style for the highlight for the HTML attributes names",
			"type": "selection",
			"default": "7",
			"items": qownStyles
		},
		{
			"identifier": "styleForAttr",
			"name": "Highlight style for HTML attributes values",
			"description": "Please select a style for the highlight for the HTML attributes values",
			"type": "selection",
			"default": "11",
			"items": qownStyles
		}
	];
        

    function init() {
        script.addHighlightingRule("<(\\S*?)[^>]>.?<\\1>|<.*?>", "", parseInt(styleForMainColor));
        script.addHighlightingRule("<(\\S*?)[^>]>.?<\\1>|<.*?>", "", parseInt(styleForTagName), 1, -1);
        script.addHighlightingRule("<(\\S*?)[^>]>.?<\\1>|<(.*?)>", "", parseInt(styleForTagName), 2, -1);
        script.addHighlightingRule("(\\w+)=[\"']?((?:.(?![\"']?\\s+(?:\\S+)=|\\s*\/?[>\"']))+.)[\"']?", "", parseInt(styleForAttrName), 1, -1);
        script.addHighlightingRule("(\\w+)=[\"']?((?:.(?![\"']?\\s+(?:\\S+)=|\\s*\/?[>\"']))+.)[\"']?", "", parseInt(styleForAttr), 2, -1);
    }
} 
