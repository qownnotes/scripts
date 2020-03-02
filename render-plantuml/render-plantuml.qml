import QtQml 2.0

/**
 * This script renders any plantuml text embedded in a note with the language hint, into a uml diagram.
 * 
    * Dependencies:
    * Node.js: https://nodejs.org/en/download/
    * java: https://java.com/en/download/
    * plantuml: http://plantuml.com/download
    * 
    * Install node and java. download the plantuml jar and provide the full path to the script.
    *
 */
QtObject {
    property string javaExePath;
    property string plantumlJarPath;
    property string workDir;
    property string hideMarkup;
    property string noStartUml;
    property string additionalParams;

    // register your settings variables so the user can set them in the script settings
    property variant settingsVariables: [
        {
            "identifier": "javaExePath",
            "name": "Path to Java executable",
            "description": "Please enter path to your java executable, or just mention the 'java' if it is already on path:",
            "type": "file",
            "default": "java"
        },
        {
            "identifier": "plantumlJarPath",
            "name": "Path to plantuml jar",
            "description": "Please enter absolute path to plantuml jar file:",
            "type": "file",
            "default": "/opt/softs/plantuml/plantuml.jar"
        },
        {
            "identifier": "workDir",
            "name": "Working directory",
            "description": "Please enter a path to be used as working directory i.e. temporary directory for file creation:",
            "type": "file",
            "default": "/tmp"
        },
        {
            "identifier": "hideMarkup",
            "name": "Hide plantuml markup",
            "description": "Enable if you wish to hide plantuml markup in preview.",
            "type": "boolean",
            "default": false
        },
        {
            "identifier": "noStartUml",
            "name": "No need for @startuml/@enduml",
            "description": "Enable if you don't want to add @startuml/@enduml to your plantUml code (compat with tagging in note text)",
            "type": "boolean",
            "default": true
        },
        {
            "identifier": "additionalParams",
            "name": "Additional Params (Advanced)",
            "description": "Enter any additional parameters you wish to pass to plantuml. This can potentially cause unexpected behaviour:",
            "type": "string",
            "default": ""
        }
    ];

    function extractPlantUmlText(html, plantumlSectionRegex, note) {
        var plantumlFiles = [];
        var index = 0;

        var match = plantumlSectionRegex.exec(html);
        while (match != null) {
			//escape the \n into \|n
            var matchedUml = match[1].replace(/\\n/gm, "\\|n");
            var filePath = workDir + "/" + note.id + "_" + (++index);
			// Tranform the real line breaks into \n
			matchedUml = matchedUml.replace(/\n/gm, "\\n");
			//Unescape HTML entities because some special char are used by PlantUML
			matchedUml = unescape(matchedUml);
			// unescape \|n to a real escaped line break \n (cf. https://stackoverflow.com/questions/27363399/how-to-escape-line-break-already-present-in-a-string/27363443#27363443)
			matchedUml = matchedUml.replace(/(\\)\|n/gm, "\\$1n");


            if (noStartUml == "true") {
				// Transforms back tagged start/end keywords to @startkeyword/@endkeyword
                matchedUml = matchedUml.replace(/^<b><font color=\"\w+\">(start\w+)<\/font><\/b>\\n/gi, "@$1\\n").replace(/<b><font color=\"\w+\">(end\w+)<\/font><\/b>\\n$/gi, "@$1\\n");

                //If needed adds @startuml/@enduml
                if (!(matchedUml.match(/^\n?@start\w+\n/gi)))
					matchedUml = "@startuml\\n" + matchedUml;
                if (!(matchedUml.match(/\n@end\w+\n?$/gi)))
					matchedUml = matchedUml + "\\n@enduml\\n";
            }

            matchedUml = matchedUml.replace(/&gt;/g, ">").replace(/&lt;/g, "<").replace(/"/g, "\\\"").replace(/&quot;/g, "\\\"").replace(/&amp;/g, "&").replace(/&#39;/g,"'").replace(/&#47;/g,"\/");

            var params = ["-e", "require('fs').writeFileSync('" + filePath + "', \"" + matchedUml + "\", 'utf8');"];
            var result = script.startSynchronousProcess("node", params, html);

            plantumlFiles.push(filePath);

            match = plantumlSectionRegex.exec(html);
        }

        return plantumlFiles;
    }

    function generateUmlDiagrams(html, plantumlFiles) {
        var params = ["-jar", plantumlJarPath, "-o", workDir, additionalParams].concat(plantumlFiles);
        var result = script.startSynchronousProcess(javaExePath, params, html);
    }

    function injectDiagrams(html, plantumlSectionRegex, plantumlFiles) {
        var index = 0;
        var updatedHtml = html.replace(plantumlSectionRegex, function(matchedStr, g1) {
            var imgElement = "<div><img src=\"file://" + plantumlFiles[index++] + ".png?t=" + +(new Date()) + "\" alt=\"Wait for it..\"/></div>";

            if (hideMarkup == "true") {
                return imgElement;
            } else {
                return imgElement + matchedStr;
            }
        });
        
        return updatedHtml;
    }

    /**
     * This function is called when the markdown html of a note is generated
     * 
     * It allows you to modify this html
     * This is for example called before by the note preview
     * 
     * @param {Note} note - the note object
     * @param {string} html - the html that is about to being rendered
     * @return {string} the modfied html or an empty string if nothing should be modified
     */
    function noteToMarkdownHtmlHook(note, html) {
        var plantumlSectionRegex = /<pre><code class=\"language-plantuml\"\>([\s\S]*?)(<\/code>)?<\/pre>/gmi;
        
        var plantumlFiles = extractPlantUmlText(html, plantumlSectionRegex, note);

        if (plantumlFiles.length) {
            generateUmlDiagrams(html, plantumlFiles);
            return injectDiagrams(html, plantumlSectionRegex, plantumlFiles);
        }

        return html;
    }
}
